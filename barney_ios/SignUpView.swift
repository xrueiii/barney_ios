import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedGender = ""
    @State private var birthday = Date()
    @State private var isDatePickerPresented = false
    @State private var isSignUpComplete = false // 控制頁面跳轉
    @State private var errorMessage: String? = nil // 錯誤訊息提示
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Image("bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.white.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // 標題
                    Text("Sign Up")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    // 表單
                    VStack(spacing: 20) {
                        Group {
                            TextField("Email", text: $email)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            TextField("Phone Number", text: $phoneNumber)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                                .keyboardType(.phonePad)
                            
                            SecureField("Password", text: $password)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                            
                            TextField("First Name", text: $firstName)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                            
                            TextField("Last Name", text: $lastName)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                        }
                        
                        // 性別選擇
                        VStack(alignment: .leading) {
                            Text("Gender:")
                                .frame(width: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .bold))
                            
                            Picker("Gender", selection: $selectedGender) {
                                Text("Male").tag("Male")
                                Text("Female").tag("Female")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: UIScreen.main.bounds.width * 0.7)
                            .padding(10)
                            .background(
                                Color.white
                                    .opacity(0.9)
                                    .cornerRadius(10)
                            )
                        }
                        
                        // 生日選擇
                        VStack(alignment: .leading) {
                            Text("Birthday:")
                                .frame(width: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .bold))
                            
                            Button(action: {
                                isDatePickerPresented = true
                            }) {
                                Text(birthday, style: .date)
                                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 30)
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                            }
                        }
                        .sheet(isPresented: $isDatePickerPresented) {
                            VStack {
                                DatePicker("---->", selection: $birthday, displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .padding()
                                
                                Button("Done") {
                                    isDatePickerPresented = false
                                }
                                .padding()
                                .font(.system(size: 16, weight: .bold))
                            }
                            .presentationDetents([.fraction(0.5)])
                            .presentationDragIndicator(.visible)
                        }
                    }
                    .padding()
                    
                    // 錯誤提示（如有）
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }
                    
                    // "Already have an account?" 提示與跳轉
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                        NavigationLink(destination: LogInView()) {
                            Text("Log In")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    
                    // 提交按鈕
                    Button(action: handleSignUp) {
                        Text("Sign Up")
                            .frame(width: UIScreen.main.bounds.width * 0.4, height: 50)
                            .foregroundColor(.white)
                            .background(isFormComplete() ? Color.accentColor : Color.gray)
                            .cornerRadius(10)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .padding()
                    .disabled(!isFormComplete())
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $isSignUpComplete) {
                ContentView() // 跳轉到 ContentView
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // 判斷表單是否填寫完整
    private func isFormComplete() -> Bool {
        return !email.isEmpty &&
               !phoneNumber.isEmpty &&
               !password.isEmpty &&
               !firstName.isEmpty &&
               !lastName.isEmpty &&
               !selectedGender.isEmpty
    }
    private func handleSignUp() {
            // 檢查表單是否有效
            guard isFormComplete() else {
                errorMessage = "Please fill in all fields."
                return
            }
            
            // 構建 API 請求
            guard let url = URL(string: "https://your-api-endpoint.com/signup") else {
                errorMessage = "Invalid API endpoint."
                return
            }
            
            let userData: [String: Any] = [
                "email": email,
                "phoneNumber": phoneNumber,
                "password": password,
                "firstName": firstName,
                "lastName": lastName,
                "gender": selectedGender,
                "birthday": birthday.timeIntervalSince1970
            ]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: userData, options: [])
            } catch {
                errorMessage = "Failed to encode user data."
                return
            }
            
            // 發送請求
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        errorMessage = "Failed to sign up: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        errorMessage = "Failed to sign up. Please try again."
                        return
                    }
                    
                    // 成功
                    isSignUpComplete = true
                }
            }.resume()
        }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
