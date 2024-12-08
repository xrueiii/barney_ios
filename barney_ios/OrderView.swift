import SwiftUI

struct OrderView: View {
    @State private var drinks: [Drink] = [] // Store drinks fetched from the API
    @State private var isLoading: Bool = true // Loading state

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Top Bar Image
                    Image("logo")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()

                    // Content
                    if isLoading {
                        VStack {
                            Spacer()
                            ProgressView("Loading Drinks...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .font(.headline)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                ForEach(drinks) { drink in
                                    DrinkCard(
                                        drinkImage: drink.drinkName.lowercased(),
                                        drinkName: drink.drinkName,
                                        flavor: drink.flavor,
                                        mood: drink.mood,
                                        intensity: drink.intensity
                                    )
                                }
                            }
                            .padding()
                        }
                    }

                    // Bottom Tab Bar
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
                        Image("cup") // Current active tab
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        Spacer()
                        NavigationLink(destination: ProfileView()) {
                            Image("member")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 49, height: 49)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                }

                // Customize Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            print("Customize Button Pressed")
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .padding()
                                .clipShape(RoundedRectangle(cornerRadius: 50))
                        }
                        .background(Circle().fill(Color.orange)).shadow(radius: 2)
                        .padding(.trailing, 20)
                        .padding(.bottom, 85) // Position above the tab bar
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline) // Inline title style
            .onAppear {
                fetchDrinks()
            }
        }
    }

    // Fetch drinks from the real API
    func fetchDrinks() {
        guard let url = URL(string: "http://localhost:\(PORT)/api/getAllRecipes") else { return }

        isLoading = true // Show loading animation
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching drinks: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            do {
                // Decode JSON response into Drink array
                let decodedDrinks = try JSONDecoder().decode([Drink].self, from: data)
                DispatchQueue.main.async {
                    drinks = decodedDrinks
                    isLoading = false // Hide loading animation
                }
            } catch {
                print("Error decoding drinks: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }.resume()
    }
}

struct Drink: Identifiable, Codable {
    var id: String
    let drinkName: String
    let flavor: String
    let mood: String
    let intensity: Int
}

struct DrinkCard: View {
    var drinkImage: String
    var drinkName: String
    var flavor: String
    var mood: String
    var intensity: Int
    @State private var isFlipped: Bool = false // State to track flipping

    var body: some View {
        ZStack {
            // Front Side
            if !isFlipped {
                Image(drinkImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipped()
                    .cornerRadius(10)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isFlipped.toggle()
                        }
                    }
            } else {
                // Back Side
                VStack(spacing: 10) {
                    Text("\(drinkName)")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Flavor: \(flavor)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)

                    Text("Mood: \(mood)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                    Text("Concentration: \(intensity)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                  
                }
                .padding()
                .frame(width: 170, height: 200)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isFlipped.toggle()
                    }
                }
            }
        }
//        .rotation3DEffect(
//            Angle(degrees: isFlipped ? 180 : 0),
//            axis: (x: 0, y: 1, z: 0)
//        )
    }
}

struct OrderView_Previews: PreviewProvider {
    static var previews: some View {
        OrderView()
    }
}
