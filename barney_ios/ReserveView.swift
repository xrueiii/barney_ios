import SwiftUI

struct ReserveView: View {
    @State private var selectedDate = Date()
    @State private var numberOfPeople = 1
    @State private var selectedTime = "20:00" // Default selected time
    @State private var branches: [AvailableBranch] = [] // List of branches available for reservation
    @State private var selectedBranch: AvailableBranch? = nil
    @State private var showBranchSheet = false // 控制 Sheet 彈出
    @State private var isLoading = false // To show loading animation
    @State private var showSuccessAlert = false // 控制成功訊息顯示

    let availableTimes = [
        "20:00", "20:15", "20:30", "20:45", "21:00", "21:15", "21:30", "21:45", "22:00",
        "22:15", "22:30", "22:45", "23:00", "23:15", "23:30", "23:45", "00:00", "00:15",
        "00:30", "00:45", "01:00", "01:15", "01:30", "01:45", "02:00", "02:15", "02:30",
        "02:45", "03:00", "03:15", "03:30", "03:45", "04:00"
    ]

    var body: some View {
        NavigationStack {
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
                        // Select Date
                        DatePicker("Reservation Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()

                        // Select Time
                        Picker("Select Time", selection: $selectedTime) {
                            ForEach(availableTimes, id: \.self) { time in
                                Text(time).tag(time)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)

                        // Select Number of People
                        Stepper(value: $numberOfPeople, in: 1...20) {
                            Text("\(numberOfPeople) people")
                                .font(.body)
                        }
                        .padding()

                        // Show Available Branches
                        Button(action: {
                            fetchBranches()
                            showBranchSheet = true
                        }) {
                            Text("Find Available Branches")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()

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
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showSuccessAlert) { // 顯示成功訊息
                            Alert(
                                title: Text("Success"),
                                message: Text("Your reservation has been submitted successfully!"),
                                dismissButton: .default(Text("OK"))
                            )
                        }
            .sheet(isPresented: $showBranchSheet) {
                AvailableBranchesSheet(
                    branches: $branches,
                    isLoading: $isLoading,
                    onReserve: { branch in
                        selectedBranch = branch
                        makeReservation()
                        showBranchSheet = false
                    }
                )
            }
        }.navigationBarBackButtonHidden(true)
    }
    // Fetch available branches from the API
    func fetchBranches() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let formattedDate = dateFormatter.string(from: selectedDate)
        let parameters: [String: String] = [
            "date": formattedDate,
            "time": selectedTime,
            "people": "\(numberOfPeople)"
        ]

        var urlComponents = URLComponents(string: "http://localhost:\(PORT)/api/getAvailableBranches")
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents?.url else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
                let decodedBranches = try JSONDecoder().decode([AvailableBranch].self, from: data)
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
        guard let url = URL(string: "http://localhost:\(PORT)/api/postReservation") else {
            print("Invalid API endpoint")
            return
        }
        
        // Format date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: selectedDate)
        let savedData = UserDefaults().array(forKey: "userArray") as? [String]
        // Prepare the reservation data
        let reservation = ReservationRequest(
            branchId: branch.id,
            date: formattedDate,
            time: selectedTime,
            memberId: savedData![5],
            people: numberOfPeople
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
                    showSuccessAlert = true // 顯示成功訊息
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
    var availableSeats: Int
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
                    Spacer()
                    
                    Text(branchName)
                        .font(.title3)
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
                    Text("Available Seats: \(availableSeats)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)

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

struct AvailableBranchesSheet: View {
    @Binding var branches: [AvailableBranch]
    @Binding var isLoading: Bool
    @State private var showAlert: Bool = false // 顯示成功訊息
    let onReserve: (AvailableBranch) -> Void

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Branches...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(branches) { branch in
                                ReserveBranchCard(
                                    branchImage: branch.imageName,
                                    branchName: branch.name,
                                    branchPhone: branch.phone,
                                    branchAddress: branch.address,
                                    branchSeats: branch.seats,
                                    availableSeats: branch.availableSeats,
                                    onReserve: {
                                        onReserve(branch)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
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
    let memberId: String
    let people: Int
}


struct ReserveView_Previews: PreviewProvider {
    static var previews: some View {
        ReserveView()
    }
}
