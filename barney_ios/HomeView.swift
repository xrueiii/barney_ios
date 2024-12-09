import SwiftUI

struct HomeView: View {
    @State private var branches: [Branch] = [] // Holds the branch data from API
    @State private var isLoading: Bool = true // Loading state for API data
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrollable Content
                if isLoading {
                    ProgressView("Loading branches...")
                        .frame(maxHeight: .infinity)
                } else {
                    // Banner Image
                    Image("logo")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .padding()

                    ScrollView {
                        // Branches List
                        VStack(spacing: 20) {
                            ForEach(branches) { branch in
                                BranchCard(
                                    branchImage: branch.imageName,
                                    branchName: branch.name,
                                    branchPhone: branch.phone,
                                    branchAddress: branch.address,
                                    branchSeats: branch.seats
                                )
                            }
                        }
                        .padding()
                    }
                }

                // Bottom Tab Bar
                HStack {
                    Spacer()
                    Image("logob") // Replace with your custom image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 49, height: 49)
                    Spacer()
                    NavigationLink(destination: ReserveView()) {
                        Image("calender") // Replace with your custom image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 49, height: 49)
                    }
                    Spacer()
                    NavigationLink(destination: OrderView()) {
                        Image("cup") // Replace with your custom image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                    Spacer()
                    NavigationLink(destination: ProfileView()) {
                        Image("member") // Replace with your custom image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 49, height: 49)
                    }
                    Spacer()
                    
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .edgesIgnoringSafeArea(.bottom)
            // .edgesIgnoringSafeArea(.top)
            .navigationBarTitleDisplayMode(.inline) // Inline style for title
            .onAppear {
                fetchBranches()
            }
        }.navigationBarBackButtonHidden(true)
    }
    
    private func fetchBranches() {
        guard let url = URL(string: "http://localhost:\(PORT)/api/getAllBranches") else {
            print("Invalid API endpoint")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching branches: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decodedBranches = try JSONDecoder().decode([Branch].self, from: data)
                DispatchQueue.main.async {
                    self.branches = decodedBranches
                    self.isLoading = false
                }
            } catch {
                print("Error decoding branches: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct BranchCard: View {
    var branchImage: String
    var branchName: String
    var branchPhone: String
    var branchAddress: String
    var branchSeats: Int

    @State private var isFlipped: Bool = false // Controls the flip state

    var body: some View {
        ZStack {
            if isFlipped {
                // Back side with details
                VStack(spacing: 10) {
                    Text(branchName)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Phone: \(branchPhone)")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                    Text("Address: \(branchAddress)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    Text("Seats: \(branchSeats)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(width: 320, height: 200)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .onTapGesture {
                    withAnimation {
                        isFlipped.toggle() // Flip back to front side
                    }
                }
            } else {
                // Front side with image
                Image(branchImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 200)
                    .clipped()
                    .cornerRadius(10)
                    .onTapGesture {
                        withAnimation {
                            isFlipped.toggle() // Flip to back side
                        }
                    }
            }
        }
    }
}

struct Branch: Identifiable, Codable {
    let id: String
    let name: String
    let phone: String
    let address: String
    let seats: Int
    let imageName: String // Image name in the Assets catalog
}

/*struct ReserveView: View {
    var body: some View {
        Text("ReserveView")
    }
}*/

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
