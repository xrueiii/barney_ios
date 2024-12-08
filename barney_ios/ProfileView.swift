//
//  ProfileView.swift
//  barney_ios
//
//  Created by ruei on 2024/12/8.
//

import SwiftUI

struct ProfileView: View {
    @State private var userName: String = "Loading..."
    @State private var userEmail: String = "Loading..."
    @State private var userPhoneNumber: String = "Loading..."
    @State private var userGender: String = "Loading..."
    @State private var errorMessage: String? = nil // 用於處理錯誤訊息

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // Top Bar Image
                    Image("logo")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()

                    // Profile Details
                    VStack(spacing: 20) {
                        if let errorMessage = errorMessage {
                            // 如果出現錯誤，顯示錯誤訊息
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        } else {
                            // 正常顯示用戶資訊
                            HStack {
                                Text("Name:")
                                    .font(.headline)
                                Spacer()
                                Text(userName)
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }

                            HStack {
                                Text("Email:")
                                    .font(.headline)
                                Spacer()
                                Text(userEmail)
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }

                            HStack {
                                Text("Phone Number:")
                                    .font(.headline)
                                Spacer()
                                Text(userPhoneNumber)
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }

                            HStack {
                                Text("Gender:")
                                    .font(.headline)
                                Spacer()
                                Text(userGender)
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .frame(width: UIScreen.main.bounds.width * 0.9)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    .padding(.top, 50) // 設定距離上方的間距

                    Spacer() // 將內容推到上方
                }
                .padding()
                .onAppear {
//                    fetchUserData() // 呼叫 API 獲取用戶資訊
                    let savedData = UserDefaults().array(forKey: "userArray") as? [String]
                    userName = savedData![0] + " " + savedData![1]
                    userGender = savedData![2]
                    userPhoneNumber = savedData![3]
                    userEmail = savedData![4]
                }

                // Bottom Tab Bar
                VStack {
                    Spacer() // 將導航欄固定在最下方
                    HStack {
                        Spacer()
                        NavigationLink(destination: HomeView()) {
                            Image("logob")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 49, height: 49)
                        }
                        Spacer()
                        NavigationLink(destination: ReserveView()) {
                            Image("calender")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 49, height: 49)
                        }
                        Spacer()
                        NavigationLink(destination: OrderView()) {
                            Image("cup")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                        Spacer()
                        Image("member") // 當前選中的頁面
                            .resizable()
                            .scaledToFit()
                            .frame(width: 49, height: 49)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                }
                .edgesIgnoringSafeArea(.bottom) // 忽略底部安全區域
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    // Load user data from API
    private func fetchUserData() {
        guard let url = URL(string: "https://yourapi.com/userProfile") else {
            errorMessage = "Invalid API URL."
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received from server."
                }
                return
            }

            do {
                // 假設 API 返回的資料是 JSON 格式
                let userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self.userName = "\(userProfile.firstName) \(userProfile.lastName)"
                    self.userEmail = userProfile.email
                    self.userPhoneNumber = userProfile.phoneNumber
                    self.userGender = userProfile.gender
                    self.errorMessage = nil // 清除錯誤訊息
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode user data."
                }
            }
        }.resume()
    }
}

// 用於解析 API 返回的用戶資料
struct UserProfile: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let phoneNumber: String
    let gender: String
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
