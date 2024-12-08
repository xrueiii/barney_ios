import SwiftUI

struct LogInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true
    @State private var shouldNavigate: Bool = false // 控制跳轉
    @State private var errorMessage: String? = nil // 錯誤提示訊息
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景圖片
                Image("bg") // 確保圖片名稱與您的 Assets 文件一致
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.white.opacity(0.4) // 半透明白色濾鏡
                    .ignoresSafeArea()
                
                VStack {
                    Spacer() // 用於將內容垂直置中
                    
                    // 標題
                    Text("Log In")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    VStack(spacing: 20) {
                        // Email 輸入框
                        TextField("email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                        
                        // 密碼輸入框
                        if isSecure {
                            SecureField("password", text: $password)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                        } else {
                            TextField("password", text: $password)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                        }
                        
                        // 顯示錯誤提示（如果有）
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                        }
                        
                        // "沒有帳戶嗎？" 提示與跳轉
                        HStack {
                            Text("Don't have an account？")
                                .foregroundColor(.black)
                                .font(.system(size: 14, weight: .bold))
                            NavigationLink(destination: SignUpView()) {
                                Text("Sign Up")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        
                        // 登入按鈕
                        Button(action: {
                            handleLogin()
                        }) {
                            Text("Log In")
                                .frame(width: UIScreen.main.bounds.width * 0.4, height: 50)
                                .foregroundColor(.white)
                                .background(isFormValid() ? Color.accentColor.opacity(1.0) : Color.gray) // 根據表單狀態改變按鈕顏色
                                .cornerRadius(10)
                                .font(.system(size: 18, weight: .bold))
                        }
                        .disabled(!isFormValid()) // 表單無效時禁用按鈕
                        
                        // 隱藏的 NavigationLink，用於跳轉到 ContentView
                        NavigationLink(destination: ContentView(), isActive: $shouldNavigate) {
                            EmptyView()
                        }
                    }
                    
                    Spacer() // 用於將內容垂直置中
                }
            }
        }
        .navigationBarBackButtonHidden(true) // 隱藏返回按鈕
    }
    
    // 檢查表單是否有效
    private func isFormValid() -> Bool {
        return !email.isEmpty && !password.isEmpty
    }

    func handleLogin() {
        // 構建 API 請求
        guard let url = URL(string: "https://your-api-endpoint.com/login") else {
            errorMessage = "無效的 API 端點。"
            return
        }
        
        let loginData: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData, options: [])
        } catch {
            errorMessage = "編碼登入資料失敗。"
            return
        }
        
        // 發送請求
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "登入失敗：\(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    errorMessage = "無效的電子郵件或密碼。"
                    return
                }
                
                // 解析返回數據
                if let data = data {
                    do {
                        if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let success = responseJSON["success"] as? Bool, success {
                            // 登入成功
                            shouldNavigate = true
                            errorMessage = nil
                        } else {
                            // 登入失敗
                            errorMessage = "伺服器返回無效數據。"
                        }
                    } catch {
                        errorMessage = "解析伺服器回應失敗。"
                    }
                }
            }
        }.resume()
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}
