# Pitch and video script (2:00 maximum)

The rules cap the video at 2 minutes. The theme is "Recreate": remake an existing AI app fully on-device. Judging: use of Bonsai/Argmax, creativity, wow factor, technical impressiveness. Timings below add up to 2:00; cut Demo 3 to one of its two parts if a take runs long.

**0:00 Recreate (15 s).** "AI budgeting apps like Rocket Money and Cleo want your bank login, and they think in the cloud. We recreated that idea with nothing leaving the device. This is Yap Later. Airplane mode is on." (Show Control Center: airplane on, Wi-Fi off.)

**0:15 Demo 1, expense and nudge (25 s).** Hold the orange button: "Just spent fifty bucks on groceries at Walmart." The card lands in Groceries, the weekly total rolls up, the budget bar fills, and the phone says "Only $… left for Groceries this week."

**0:40 Demo 2, it asks instead of guessing (20 s).** "Grabbed a coffee." It asks "How much was it?" Hold: "Six fifty." It logs $6.50 under Coffee. "It never makes up a number."

**1:00 Demo 3, ramble and reminder (25 s).** "Twelve on lunch, six fifty on coffee and twenty two on an Uber." Three expenses land at once. Then: "Remind me to pay rent tomorrow at six pm." Tap Save; it is in Apple Reminders.

**1:25 Same app on the Mac (10 s).** Show the Mac with Wi-Fi off, Yap Later open, one expense spoken or typed. "Same code, running natively on the Mac."

**1:35 How (20 s).** "Speech is Argmax WhisperKit. Understanding is PrismML's Ternary Bonsai 2, four billion parameters in 1.2 gigabytes, running through llama.cpp on the GPU: about 1.3 seconds a sentence on the phone, half a second on the Mac. We measured the 2B at 12 of 20 and the 4B at 23 of 23, so we ship the smallest one that passes. The model only proposes; Swift code checks every amount and date."

**1:55 Close (5 s).** "No bank login, no server, no signal needed. Yap Later."

For a live finalist demo (12:30), use the same order and skip the Mac segment if switching screens is awkward.

## Demo checklist

- Phone charged, Auto-Lock off, volume up, Do Not Disturb off.
- App opened once after the last install so the speech model is warm (first load after an install can take a minute).
- Budgets set and the week pre-logged through the app so the live grocery yap crosses the "low" line (25% of the limit, or $50 for limits over $200). Example: Groceries budget $200 with $100 already logged; the live $50 leaves exactly $50.
- Airplane mode on, Wi-Fi and Bluetooth off, Mac unplugged.
- Mac: run `scripts/setup_mac.sh` beforehand, open the app once and allow the microphone, then turn Wi-Fi off before recording the Mac segment.
- Video is at most 2:00; submit it with the GitHub link before noon.
- Before recording, check the three things that have not been seen working yet: the Mac microphone (hold the button in the Mac window and allow the prompt), the Argmax voice (listen to one question on the Mac; it is off on the iPhone until checked there), and Sync (tap Sync on the Mac, then on the iPhone, and allow Bluetooth on both). Only show or mention in the video what worked in that check. If Sync works, it fits in the Mac segment: log an expense on the phone, tap Sync on both, and it appears on the Mac.
- Reminders access already granted (save one reminder before the demo so the permission prompt does not appear live).
- Backup: screen recording of the same flow made in airplane mode.
