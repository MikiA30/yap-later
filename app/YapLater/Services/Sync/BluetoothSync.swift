import CoreBluetooth
import Foundation

/// Copies the ledger between the user's own Mac and iPhone over Bluetooth Low Energy: no internet, no server,
/// no account. It runs only after the user taps Sync. The Mac waits; the iPhone finds it, sends its ledger,
/// and receives the Mac's.
protocol PeerSyncing: AnyObject {
    func start()
    func stop()
}

enum BluetoothSync {
    static let service = CBUUID(string: "7B0E6C52-5A1D-4C0B-9E51-59A1C0DE0001")
    static let channel = CBUUID(string: "7B0E6C52-5A1D-4C0B-9E51-59A1C0DE0002")
    /// Sent after the last piece of a ledger. JSON never contains this byte.
    static let end = Data([0x04])

    /// The Mac hosts; the iPhone connects.
    static func make(snapshot: @escaping () -> Data, receive: @escaping (Data) -> Void,
                     status: @escaping (String, Bool) -> Void) -> any PeerSyncing {
        #if os(macOS)
        SyncHost(snapshot: snapshot, receive: receive, status: status)
        #else
        SyncClient(snapshot: snapshot, receive: receive, status: status)
        #endif
    }

    static func pieces(of data: Data, size: Int) -> [Data] {
        let size = max(size, 20)
        var result: [Data] = []
        var offset = 0
        while offset < data.count {
            let next = min(offset + size, data.count)
            result.append(data.subdata(in: offset..<next))
            offset = next
        }
        return result + [end]
    }
}

/// The waiting side (Mac). All callbacks arrive on the main queue.
final class SyncHost: NSObject, PeerSyncing, CBPeripheralManagerDelegate {
    private let snapshot: () -> Data
    private let receive: (Data) -> Void
    /// (message, finished)
    private let status: (String, Bool) -> Void
    private var manager: CBPeripheralManager?
    private var characteristic: CBMutableCharacteristic?
    private var incoming = Data()
    private var outgoing: [Data] = []

    init(snapshot: @escaping () -> Data, receive: @escaping (Data) -> Void, status: @escaping (String, Bool) -> Void) {
        self.snapshot = snapshot
        self.receive = receive
        self.status = status
    }

    func start() {
        manager = CBPeripheralManager(delegate: self, queue: .main)
    }

    func stop() {
        manager?.stopAdvertising()
        manager?.removeAllServices()
        manager = nil
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else {
            if peripheral.state == .unauthorized || peripheral.state == .poweredOff || peripheral.state == .unsupported {
                status("Bluetooth is off or not allowed for Yap Later.", true)
            }
            return
        }
        let characteristic = CBMutableCharacteristic(type: BluetoothSync.channel, properties: [.write, .notify],
                                                     value: nil, permissions: [.writeable])
        let service = CBMutableService(type: BluetoothSync.service, primary: true)
        service.characteristics = [characteristic]
        self.characteristic = characteristic
        peripheral.removeAllServices()
        peripheral.add(service)
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [BluetoothSync.service],
                                     CBAdvertisementDataLocalNameKey: "Yap Later"])
        status("Waiting for your iPhone. Tap Sync there.", false)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests where request.characteristic.uuid == BluetoothSync.channel {
            guard let value = request.value else { continue }
            if value == BluetoothSync.end {
                receive(incoming)
                incoming = Data()
                // Answer with this Mac's ledger, which now includes what just arrived.
                outgoing = BluetoothSync.pieces(of: snapshot(), size: request.central.maximumUpdateValueLength)
                status("Sending to your iPhone…", false)
            } else {
                incoming.append(value)
            }
        }
        if let first = requests.first { peripheral.respond(to: first, withResult: .success) }
        pump()
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) { pump() }

    private func pump() {
        guard let manager, let characteristic else { return }
        while let piece = outgoing.first {
            guard manager.updateValue(piece, for: characteristic, onSubscribedCentrals: nil) else { return }
            outgoing.removeFirst()
            if outgoing.isEmpty { status("Synced with your iPhone.", true) }
        }
    }
}

/// The connecting side (iPhone). All callbacks arrive on the main queue.
final class SyncClient: NSObject, PeerSyncing, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let snapshot: () -> Data
    private let receive: (Data) -> Void
    private let status: (String, Bool) -> Void
    private var manager: CBCentralManager?
    private var peer: CBPeripheral?
    private var channel: CBCharacteristic?
    private var incoming = Data()
    private var outgoing: [Data] = []
    private var finished = false

    init(snapshot: @escaping () -> Data, receive: @escaping (Data) -> Void, status: @escaping (String, Bool) -> Void) {
        self.snapshot = snapshot
        self.receive = receive
        self.status = status
    }

    func start() {
        finished = false
        manager = CBCentralManager(delegate: self, queue: .main)
    }

    func stop() {
        manager?.stopScan()
        if let peer { manager?.cancelPeripheralConnection(peer) }
        peer = nil
        manager = nil
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            if central.state == .unauthorized || central.state == .poweredOff || central.state == .unsupported {
                status("Bluetooth is off or not allowed for Yap Later.", true)
            }
            return
        }
        central.scanForPeripherals(withServices: [BluetoothSync.service])
        status("Looking for your Mac. Tap Sync there.", false)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard peer == nil else { return }
        peer = peripheral
        central.stopScan()
        central.connect(peripheral)
        status("Found your Mac…", false)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([BluetoothSync.service])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        fail()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if !finished { fail() }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == BluetoothSync.service }) else { return fail() }
        peripheral.discoverCharacteristics([BluetoothSync.channel], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let found = service.characteristics?.first(where: { $0.uuid == BluetoothSync.channel }) else { return fail() }
        channel = found
        peripheral.setNotifyValue(true, for: found)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil, characteristic.isNotifying else { return fail() }
        outgoing = BluetoothSync.pieces(of: snapshot(), size: peripheral.maximumWriteValueLength(for: .withResponse))
        status("Sending to your Mac…", false)
        sendNext()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return fail() }
        if !outgoing.isEmpty { outgoing.removeFirst() }
        sendNext()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else { return }
        if value == BluetoothSync.end {
            finished = true
            receive(incoming)
            incoming = Data()
            status("Synced with your Mac.", true)
            manager?.cancelPeripheralConnection(peripheral)
        } else {
            incoming.append(value)
        }
    }

    private func sendNext() {
        guard let peer, let channel, let piece = outgoing.first else { return }
        peer.writeValue(piece, for: channel, type: .withResponse)
    }

    private func fail() {
        guard !finished else { return }
        finished = true
        status("Sync didn't finish. Keep both devices close and try again.", true)
        stop()
    }
}
