#if canImport(llama)
import Foundation
import llama

/// Interprets a transcript with PrismML's Ternary Bonsai 2 (Q2_0 GGUF), run in-process by llama.cpp on the
/// phone's GPU. Output is constrained to the proposal's JSON shape by a grammar, so there is no free text.
actor BonsaiInterpreter: MoneyInterpreter {
    nonisolated let isMock = false
    nonisolated let modelURL: URL
    nonisolated var name: String { "Bonsai 2 · \(modelURL.deletingPathExtension().lastPathComponent)" }

    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?
    /// For each prompt kind: the fixed start of the prompt (rules and example turns) and the model's memory
    /// right after reading it. Each request restores a snapshot, so it starts clean and never sees an earlier one.
    private var snapshots: [String: (tokens: [llama_token], state: [UInt8])] = [:]
    private var suppressThinking = false

    init(modelURL: URL) {
        self.modelURL = modelURL
    }

    /// A Bonsai model copied onto the phone ahead of time: `Documents/models/*.gguf`.
    /// With several present, `-bonsai 2B` (or `YAP_BONSAI=2B`) picks one; otherwise the largest wins:
    /// on the iPhone 17 Pro the 4B scored 18/20 against the 2B's 12/20 on the built-in eval.
    static func provisionedModel() -> URL? {
        guard let documents = LocalAssets.root else { return nil }
        let folder = documents.appendingPathComponent("models", isDirectory: true)
        let files = ((try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.fileSizeKey])) ?? [])
            .filter { $0.pathExtension == "gguf" && !$0.lastPathComponent.contains("mmproj") }
        if let wanted = ProcessInfo.processInfo.environment["YAP_BONSAI"] ?? UserDefaults.standard.string(forKey: "bonsai"),
           let match = files.first(where: { $0.lastPathComponent.contains(wanted) }) {
            return match
        }
        return files.max { size(of: $0) < size(of: $1) }
    }

    private static func size(of url: URL) -> Int {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }

    /// Loads the model now so the first yap does not wait for it.
    func prewarm() {
        try? ensureLoaded()
    }

    private func ensureLoaded() throws {
        guard context == nil else { return }
        let started = Date()
        llama_backend_init()
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 999 // everything on the GPU
        guard let model = llama_model_load_from_file(modelURL.path, modelParams) else {
            throw InterpreterError.generationFailed("The Bonsai model file could not be loaded.")
        }
        var contextParams = llama_context_default_params()
        contextParams.n_ctx = 2048
        contextParams.n_batch = 2048
        guard let context = llama_init_from_model(model, contextParams) else {
            llama_model_free(model)
            throw InterpreterError.generationFailed("The Bonsai model could not start.")
        }
        self.model = model
        self.context = context
        self.vocab = llama_model_get_vocab(model)
        if let template = llama_model_chat_template(model, nil) {
            suppressThinking = String(cString: template).contains("think")
        }
        print("BONSAI loaded \(modelURL.lastPathComponent) in \(Int(Date().timeIntervalSince(started) * 1000)) ms, thinking switch: \(suppressThinking)")
    }

    func interpret(_ request: InterpretationRequest) async throws -> MoneyProposal {
        try Task.checkCancellation()
        try ensureLoaded()
        let first = try run(key: "money", system: InterpreterPrompt.chatSystem, examples: InterpreterPrompt.chatExamples,
                            sentence: request.transcript, grammar: Self.grammar)
        var proposal: MoneyProposal
        do {
            proposal = try ProposalParser.parse(first)
            if proposal.kind == .reminder {
                // Second step: pull out what to remind about and when.
                let second = try run(key: "reminder", system: InterpreterPrompt.reminderSystem,
                                     examples: InterpreterPrompt.reminderExamples,
                                     sentence: request.transcript, grammar: Self.reminderGrammar)
                proposal = try ProposalParser.parseReminder(second)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw InterpreterError.generationFailed("The model's answer was not readable.")
        }
        // An amount that was never said must not leave the interpreter.
        if let amount = proposal.amount,
           !AmountEvidence.supports(cents: Int((amount * 100).rounded()), in: request.transcript) {
            proposal.amount = nil
        }
        return proposal
    }

    /// One constrained generation: rules + example turns + the sentence in, one JSON object out.
    private func run(key: String, system: String, examples: [(sentence: String, answer: String)],
                     sentence: String, grammar: String) throws -> String {
        guard let context, let vocab else { throw InterpreterError.generationFailed("The Bonsai model is not loaded.") }
        var turns: [(role: String, content: String)] = [("system", system)]
        for example in examples {
            turns.append(("user", InterpreterPrompt.sentenceLine(example.sentence)))
            turns.append(("assistant", example.answer))
        }
        turns.append(("user", InterpreterPrompt.sentenceLine(sentence)))
        var tokens = tokenize(buildPrompt(turns), vocab: vocab)
        guard !tokens.isEmpty, tokens.count < 1900 else {
            throw InterpreterError.generationFailed("That was too long for the model.")
        }

        // Start from a clean memory every time: restore the snapshot taken after the fixed prefix,
        // or read the whole prompt if there is no usable snapshot.
        let memory = llama_get_memory(context)
        llama_memory_clear(memory, true)
        if snapshots[key] == nil {
            snapshotPrefix(key: key, of: turns, context: context, vocab: vocab)
            llama_memory_clear(memory, true)
        }
        var start = 0
        if let snapshot = snapshots[key], tokens.count > snapshot.tokens.count,
           Array(tokens[0..<snapshot.tokens.count]) == snapshot.tokens,
           llama_state_seq_set_data(context, snapshot.state, snapshot.state.count, 0) > 0 {
            start = snapshot.tokens.count
        } else {
            llama_memory_clear(memory, true)
        }
        let status = tokens.withUnsafeMutableBufferPointer { buffer in
            llama_decode(context, llama_batch_get_one(buffer.baseAddress! + start, Int32(buffer.count - start)))
        }
        guard status == 0 else {
            throw InterpreterError.generationFailed("The model could not read the sentence (\(status)).")
        }

        let sampler = llama_sampler_chain_init(llama_sampler_chain_default_params())
        defer { llama_sampler_free(sampler) }
        llama_sampler_chain_add(sampler, llama_sampler_init_grammar(vocab, grammar, "root"))
        llama_sampler_chain_add(sampler, llama_sampler_init_greedy())

        var bytes: [UInt8] = []
        var piece = [CChar](repeating: 0, count: 128)
        for _ in 0..<140 {
            try Task.checkCancellation()
            var token = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocab, token) { break }
            let length = llama_token_to_piece(vocab, token, &piece, Int32(piece.count), 0, false)
            if length > 0 { bytes.append(contentsOf: piece[0..<Int(length)].map { UInt8(bitPattern: $0) }) }
            if bytes.last == UInt8(ascii: "}"),
               ProposalParser.firstJSONObject(in: String(decoding: bytes, as: UTF8.self)) != nil { break }
            guard llama_decode(context, llama_batch_get_one(&token, 1)) == 0 else { break }
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    /// Reads the part of the prompt that never changes and keeps a copy of the model's memory after it.
    private func snapshotPrefix(key: String, of turns: [(role: String, content: String)], context: OpaquePointer, vocab: OpaquePointer) {
        // Two prompts that differ only in the final sentence share exactly the fixed prefix.
        var probe = turns
        probe[probe.count - 1].content = InterpreterPrompt.sentenceLine("Zq")
        var other = turns
        other[other.count - 1].content = InterpreterPrompt.sentenceLine("7 x")
        let first = tokenize(buildPrompt(probe), vocab: vocab), second = tokenize(buildPrompt(other), vocab: vocab)
        let shared = zip(first, second).prefix { $0 == $1 }.count - 2 // stop short of the token that may merge
        guard shared > 16 else { return }
        var prefix = Array(first[0..<shared])
        let status = prefix.withUnsafeMutableBufferPointer { buffer in
            llama_decode(context, llama_batch_get_one(buffer.baseAddress!, Int32(buffer.count)))
        }
        guard status == 0 else { return }
        let size = llama_state_seq_get_size(context, 0)
        guard size > 0 else { return }
        var state = [UInt8](repeating: 0, count: size)
        guard llama_state_seq_get_data(context, &state, size, 0) == size else { return }
        snapshots[key] = (prefix, state)
        print("BONSAI \(key) prefix snapshot: \(prefix.count) tokens, \(size / 1_048_576) MB")
    }

    /// Uses the model's own chat template when llama.cpp recognizes it; otherwise ChatML.
    private func buildPrompt(_ turns: [(role: String, content: String)]) -> String {
        var prompt = templated(turns) ?? turns.map { "<|im_start|>\($0.role)\n\($0.content)<|im_end|>\n" }.joined()
            + "<|im_start|>assistant\n"
        if suppressThinking { prompt += "<think>\n\n</think>\n\n" } // skip the reasoning block; answer directly
        return prompt
    }

    private func templated(_ turns: [(role: String, content: String)]) -> String? {
        guard let model, let template = llama_model_chat_template(model, nil) else { return nil }
        // Keep C strings alive for the duration of the call.
        let roles = turns.map { strdup($0.role) }
        let contents = turns.map { strdup($0.content) }
        defer { (roles + contents).forEach { free($0) } }
        let messages = zip(roles, contents).map { llama_chat_message(role: UnsafePointer($0), content: UnsafePointer($1)) }
        var buffer = [CChar](repeating: 0, count: turns.reduce(2048) { $0 + $1.content.utf8.count * 2 + 64 })
        let written = llama_chat_apply_template(template, messages, messages.count, true, &buffer, Int32(buffer.count))
        guard written > 0, Int(written) < buffer.count else { return nil }
        return String(decoding: buffer[0..<Int(written)].map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    private func tokenize(_ text: String, vocab: OpaquePointer) -> [llama_token] {
        let byteCount = Int32(text.utf8.count)
        var tokens = [llama_token](repeating: 0, count: Int(byteCount) + 16)
        let count = llama_tokenize(vocab, text, byteCount, &tokens, Int32(tokens.count), true, true)
        return count > 0 ? Array(tokens[0..<Int(count)]) : []
    }

    /// The only shape the model may produce: one JSON object matching `MoneyProposal`.
    static let grammar = #"""
    root ::= "{\"kind\":" kind ",\"amount\":" amount ",\"merchant\":" text ",\"category\":" category ",\"date_phrase\":" text ",\"period\":" period "}"
    kind ::= "\"expense\"" | "\"budget_set\"" | "\"reminder\"" | "\"unsupported\""
    amount ::= "null" | [0-9] [0-9]? [0-9]? [0-9]? [0-9]? [0-9]? ("." [0-9] [0-9]?)?
    text ::= "null" | "\"" [^"\\\n] [^"\\\n]* "\""
    category ::= "null" | "\"groceries\"" | "\"dining\"" | "\"coffee\"" | "\"transport\"" | "\"shopping\"" | "\"bills\"" | "\"fun\"" | "\"health\"" | "\"other\""
    period ::= "null" | "\"week\""
    """#

    /// The shape of the second-step reminder answer.
    static let reminderGrammar = #"""
    root ::= "{\"title\":" text ",\"day\":" day ",\"day_of_month\":" num ",\"month\":" num ",\"hour\":" num ",\"minute\":" num ",\"in_minutes\":" num ",\"amount\":" amount "}"
    text ::= "null" | "\"" [^"\\\n] [^"\\\n]* "\""
    day ::= "null" | "\"today\"" | "\"tomorrow\"" | "\"date\"" | "\"monday\"" | "\"tuesday\"" | "\"wednesday\"" | "\"thursday\"" | "\"friday\"" | "\"saturday\"" | "\"sunday\""
    num ::= "null" | [0-9] [0-9]? [0-9]? [0-9]? [0-9]?
    amount ::= "null" | [0-9] [0-9]? [0-9]? [0-9]? [0-9]? [0-9]? ("." [0-9] [0-9]?)?
    """#
}
#endif