import SwiftUI

struct ReserveView: View {
    @State private var selectedDate = Date()
    @State private var numberOfPeople = 1
    @State private var selectedTime = "8:00 PM" // Default selected time
    @State private var branches: [Branch] = [] // List of branches available for reservation
    @State private var selectedBranch: Branch? = nil
    @State private var showBranchList = false
    @State private var isLoading = false // To show loading animation

    let availableTimes = [
        "8:00 PM", "8:15 PM", "8:30 PM", "8:45 PM", "9:00 PM", "9:15 PM", "9:30 PM", "9:45 PM","10:00 PM", "10:15 PM", "10:30 PM", "10:45 PM", "11:00 PM", "11:15 PM", "11:30 PM", "11:45 PM","12:00 AM", "12:15 AM", "12:30 AM", "12:45 AM", "1:00 AM", "1:15 AM", "1:30 AM", "1:45 AM","2:00 AM", "2:15 AM", "2:30 AM", "2:45 AM", "3:00 AM", "3:15 AM", "3:30 AM","3:45 AM","4:00 AM"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Logo Image
                    Image("logo")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .padding()

                    ScrollView {
                        VStack(spacing: 0) {
                            if !showBranchList {
                                // Select Date
                                VStack(alignment: .leading, spacing: 10) {
                                    DatePicker("Reservation Date", selection: $selectedDate, displayedComponents: .date)
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                        .padding()
                                }

                                // Select Time
                                VStack(alignment: .leading, spacing: 10) {
                                    Picker("Select Time", selection: $selectedTime) {
                                        ForEach(availableTimes, id: \.self) { time in
                                            Text(time).tag(time)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                }

                                // Select Number of People
                                VStack(alignment: .leading, spacing: 10) {
                                    Stepper(value: $numberOfPeople, in: 1...20) {
                                        Text("\(numberOfPeople) people")
                                            .font(.body)
                                    }
                                    .padding()
                                }

                                // Show Available Branches
                                Button(action: {
                                    showBranchList = true
                                    fetchBranches()
                                }) {
                                    Text("Find Available Branches")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            } else {
                                if isLoading {
                                    ProgressView("Loading Branches...")
                                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                                } else {
                                    LazyVStack(spacing: 15) {
                                        ForEach(branches) { branch in
                                            ReserveBranchCard(
                                                branchImage: branch.imageName,
                                                branchName: branch.name,
                                                branchPhone: branch.phone,
                                                branchAddress: branch.address,
                                                branchSeats: branch.seats,
                                                onReserve: {
                                                    selectedBranch = branch
                                                    makeReservation()
                                                }
                                            )
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                        .padding()
                    }

                    // Bottom Tab Bar
                    VStack {
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
                                Image("cup") // Current active tab
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
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
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarBackButtonHidden(true)
        }
    }

    // Fetch available branches from the API
    func fetchBranches() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let formattedDate = dateFormatter.string(from: selectedDate)
        let parameters: [String: Any] = [
            "date": formattedDate,
            "time": selectedTime,
            "people": numberOfPeople
        ]

        guard let url = URL(string: "http://localhost:\(PORT)/api/getAvailableBranches") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error encoding parameters: \(error)")
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching branches: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            do {
                let decodedBranches = try JSONDecoder().decode([Branch].self, from: data)
                DispatchQueue.main.async {
                    branches = decodedBranches
                    isLoading = false
                }
            } catch {
                print("Error decoding branches: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }.resume()
    }

    // Make reservation
    func makeReservation() {
        guard let branch = selectedBranch else { return }
        
        // API endpoint
        guard let url = URL(string: "http://localhost:\(PORT)/api/makeReservation") else {
            print("Invalid API endpoint")
            return
        }
        
        // Format date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: selectedDate)
        
        // Prepare the reservation data
        let reservation = ReservationRequest(
            branchId: branch.id,
            date: formattedDate,
            time: selectedTime,
            numberOfPeople: numberOfPeople
        )
        
        do {
            let requestData = try JSONEncoder().encode(reservation)
            
            // Configure the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestData
            
            // Make the API call
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making reservation: \(error.localizedDescription)")
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    print("Failed to make reservation. Invalid response from server.")
                    return
                }
                
                // Handle successful reservation
                DispatchQueue.main.async {
                    print("Reservation confirmed for \(branch.name) on \(formattedDate) at \(selectedTime) for \(numberOfPeople) people.")
                }
            }.resume()
            
        } catch {
            print("Error encoding reservation data: \(error.localizedDescription)")
        }
    }
}

struct ReserveBranchCard: View {
    var branchImage: String
    var branchName: String
    var branchPhone: String
    var branchAddress: String
    var branchSeats: Int
    var onReserve: () -> Void

    @State private var isFlipped: Bool = false // Controls the flip state
    @State private var isLoading: Bool = false // Controls the loading state

    var body: some View {
        ZStack {
            if isLoading {
                // Loading animation
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        .scaleEffect(2) // Scale up the loading indicator
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(width: 320, height: 250)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            } else if isFlipped {
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

                    Spacer()

                    // Reserve Button
                    Button(action: {
                        isLoading = true // Set loading state to true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Simulate network delay
                            isLoading = false
                            onReserve() // Call the reserve action
                        }
                    }) {
                        Text("Reserve")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .frame(width: 320, height: 250)
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

struct ReservationRequest: Codable {
    let branchId: String
    let date: String
    let time: String
    let numberOfPeople: Int
}


struct ReserveView_Previews: PreviewProvider {
    static var previews: some View {
        ReserveView()
    }
}
