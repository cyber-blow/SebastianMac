import Foundation

class AIService {
    static let shared = AIService()
    
    enum AIError: Error, LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case apiError(String)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "APIキーが設定されていません。"
            case .invalidURL: return "無効なURLです。"
            case .networkError(let err): return "通信エラー: \(err.localizedDescription)"
            case .decodingError(let err): return "デコードエラー: \(err.localizedDescription)"
            case .apiError(let msg): return "APIエラー: \(msg)"
            case .unknown: return "不明なエラーが発生しました。"
            }
        }
    }
    
    func generateNippo(from memos: [String], targetDate: Date) async throws -> String {
        let aiProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? "gemini"
        
        if aiProvider == "none" {
            throw AIError.apiError("現在AIが無効に設定されています。設定画面からAIプロバイダーを有効にしてください。")
        }
        
        if aiProvider == "ollama" {
            throw AIError.apiError("Ollamaプロバイダーは準備中です。現在はGeminiをご利用ください。")
        }
        
        let apiKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AIError.noAPIKey
        }
        
        let model = UserDefaults.standard.string(forKey: "geminiModel") ?? "gemini-2.5-flash"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIError.invalidURL
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        let dateString = formatter.string(from: targetDate)
        
        let memoText = memos.joined(separator: "\n- ")
        
        let prompt = """
        あなたは有能で物静かな執事「Sebastian」です。主人の【\(dateString)の業務メモ】から、本日の日報（報告書）を構築してください。
        主人は仕事が忙しく、メモは雑多に書き殴られている可能性があります。それを綺麗なMarkdown形式の日報に清書し、タスクを分類・整理することがあなたのミッションです。
        
        【主人の業務メモ】
        - \(memoText)
        
        【出力ルール】
        1. 丁寧な執事らしい言葉で「本日の業務報告」から始めてください（例：お疲れ様でございます。本日の報告をまとめました。）
        2. 全体をMarkdown形式で出力してください。
        3. メモから読み取れる「明日以降のタスク」があれば、箇条書きで抜き出してください。
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [ ["text": prompt] ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unreadable API Error"
            throw AIError.apiError("Status \(httpResponse.statusCode): \(errorText)")
        }
        
        return try parseGeminiResponse(data: data)
    }
    
    func extractTasks(from text: String) async throws -> [String] {
        let aiProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? "gemini"
        if aiProvider != "gemini" { return [] }
        
        let apiKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        if apiKey.isEmpty { return [] }
        
        let model = UserDefaults.standard.string(forKey: "geminiModel") ?? "gemini-2.5-flash"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return [] }
        
        let prompt = """
        以下のテキストから、実行すべき残りの「具体的なタスク」のリストだけを抽出して箇条書きで抽出してください。
        タスク以外（挨拶や補足）は一切出力しないでください。1行につき1つのタスクにしてください。(-)などを先頭に付けないでください。
        
        【テキスト】
        \(text)
        """
        
        let requestBody: [String: Any] = [
            "contents": [ [ "role": "user", "parts": [ ["text": prompt] ] ] ],
            "generationConfig": [ "temperature": 0.1 ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            return []
        }
        
        let extractedText = try parseGeminiResponse(data: data)
        return extractedText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "-*• ")) }
            .filter { !$0.isEmpty }
    }
    
    private func parseGeminiResponse(data: Data) throws -> String {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                return text
            } else {
                throw AIError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
            }
        } catch {
            throw AIError.decodingError(error)
        }
    }

    
    struct TaskCandidateResponse: Codable {
        let candidates: [TaskCandidateData]
    }
    
    struct TaskCandidateData: Codable {
        var type: String // "new" | "update"
        var title: String
        var description: String?
        var priority: String
        var due_date: String?
        var category: String?
        var target_task_id: String?
        var reason: String
    }
    
    func extractTaskCandidates(memo: String, tasks: [TaskItem], todayDateString: String) async throws -> [TaskCandidateData] {
        let aiProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? "gemini"
        if aiProvider != "gemini" { 
            throw AIError.apiError("現在Gemini以外のプロバイダーはタスク抽出に対応していません。") 
        }
        
        let apiKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        if apiKey.isEmpty { throw AIError.noAPIKey }
        
        let model = UserDefaults.standard.string(forKey: "geminiModel") ?? "gemini-2.5-flash"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw AIError.invalidURL }
        
        var tasksContext = ""
        for (index, task) in tasks.enumerated() {
            let prio = task.priorityValue
            let due = task.dueDate != nil ? "\(task.dueDate!)" : "なし"
            tasksContext += "[ID: \(index)] Title: \(task.title) | Priority: \(prio) | Due: \(due) | Category: \(task.category ?? "なし")\n"
        }
        
        let sysPrompt = """
        あなたは優秀な秘書AIです。本日の日付は「\(todayDateString)」です。
        【ユーザーのメモ】と【現在のタスク一覧】を照らし合わせ、以下の作業を行ってください。
        
        1. メモ内に新しいタスクが含まれていれば、新規タスク(new)として抽出する。
        2. メモ内に既存のタスクの変更（期日が決まった、優先度が上がった等）が含まれていれば、更新(update)として提案する。
        
        返却フォーマットは、必ず以下のJSONスキーマに従うこと。Markdownブロック(```json)等を含めず生のJSONオブジェクトを返すこと。
        {
          "candidates": [
            {
              "type": "new" か "update",
              "title": "タスク名",
              "description": "詳細(任意)",
              "priority": "high", "medium", "low", または "none",
              "due_date": "YYYY-MM-DD"(必須ではない),
              "category": "カテゴリ名(任意)",
              "target_task_id": "updateの場合は既存タスクのID番号を文字列で",
              "reason": "なぜこのタスクを提案したかの簡潔な理由"
            }
          ]
        }
        """
        
        let prompt = """
        【現在のタスク一覧】
        \(tasksContext)
        
        【ユーザーのメモ】
        \(memo)
        """
        
        let requestBody: [String: Any] = [
            "systemInstruction": [
                "role": "user",
                "parts": [ ["text": sysPrompt] ]
            ],
            "contents": [ [ "role": "user", "parts": [ ["text": prompt] ] ] ],
            "generationConfig": [ 
                "temperature": 0.1,
                "responseMimeType": "application/json"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw AIError.apiError("HTTP status: \(httpResponse.statusCode)")
        }
        
        let responseJsonStr = try parseGeminiResponse(data: data)
        guard let jsonData = responseJsonStr.data(using: .utf8) else {
            throw AIError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to read string data"]))
        }
        
        let res = try JSONDecoder().decode(TaskCandidateResponse.self, from: jsonData)
        return res.candidates
    }
}
