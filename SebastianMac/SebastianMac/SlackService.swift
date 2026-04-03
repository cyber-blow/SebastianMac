import Foundation

class SlackService {
    static let shared = SlackService()
    
    func postNippo(content: String) async throws {
        let isEnabled = UserDefaults.standard.bool(forKey: "isSlackEnabled")
        let webhookURLString = UserDefaults.standard.string(forKey: "slackWebhookURL") ?? ""
        let userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        guard isEnabled, !webhookURLString.isEmpty, let url = URL(string: webhookURLString) else {
            return // 設定が無効なら何もしない
        }
        
        let headerText = userName.isEmpty ? "【本日の日報】" : "【本日の日報: \(userName)】"
        
        // Slack Block Kit Payload
        let payload: [String: Any] = [
            "blocks": [
                [
                    "type": "header",
                    "text": [
                        "type": "plain_text",
                        "text": headerText,
                        "emoji": true
                    ]
                ],
                [
                    "type": "section",
                    "text": [
                        "type": "mrkdwn",
                        "text": content
                    ]
                ],
                [
                    "type": "divider"
                ],
                [
                    "type": "context",
                    "elements": [
                        [
                            "type": "plain_text",
                            "text": "Sent by Sebastian - Mac App",
                            "emoji": true
                        ]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                print("Slack Error! Status code: \(httpResponse.statusCode)")
            }
        }
    }
}
