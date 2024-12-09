import SwiftUI

struct ReserveView: View {
    @State private var selectedDate = Date()
    @State private var numberOfPeople = 1
    @State private var selectedTime = "12:00 PM" // Default selected time
    @State private var branches: [Branch] = [] // List of branches available for reservation
    @State private var selectedBranch: Branch? = nil
    @State private var showBranchList = false
    @State private var isLoading = false // No need to show loading animation with fake data

    let availableTimes = [
        "12:00 AM", "12:15 AM", "12:30 AM", "12:45 AM", "1:00 AM", "1:15 AM", "1:30 AM", "1:45 AM",
        "2:00 AM", "2:15 AM", "2:30 AM", "2:45 AM", "3:00 AM", "3:15 AM", "3:30 AM", "3:45 AM",
        "4:00 AM", "4:15 AM", "4:30 AM", "4:45 AM", "5:00 AM", "5:15 AM", "5:30 AM", "5:45 AM",
        "6:00 AM", "6:15 AM", "6:30 AM", "6:45 AM", "7:00 AM", "7:15 AM", "7:30 AM", "7:45 AM",
        "8:00 AM", "8:15 AM", "8:30 AM", "8:45 AM", "9:00 AM", "9:15 AM", "9:30 AM", "9:45 AM",
        "10:00 AM", "10:15 AM", "10:30 AM", "10:45 AM", "11:00 AM", "11:15 AM", "11:30 AM", "11:45 AM",
        "12:00 PM", "12:15 PM", "12:30 PM", "12:45 PM", "1:00 PM", "1:15 PM", "1:30 PM", "1:45 PM",
        "2:00 PM", "2:15 PM", "2:30 PM", "2:45 PM", "3:00 PM", "3:15 PM", "3:30 PM", "3:45 PM",
        "4:00 PM", "4:15 PM", "4:30 PM", "4:45 PM", "5:00 PM", "5:15 PM", "5:30 PM", "5:45 PM",
        "6:00 PM", "6:15 PM", "6:30 PM", "6:45 PM", "7:00 PM", "7:15 PM", "7:30 PM", "7:45 PM",
        "8:00 PM", "8:15 PM", "8:30 PM", "8:45 PM", "9:00 PM", "9:15 PM", "9:30 PM", "9:45 PM",
        "10:00 PM", "10:15 PM", "10:30 PM", "10:45 PM", "11:00 PM", "11:15 PM", "11:30 PM", "11:45 PM"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    // If branch list is not shown, show calendar, time picker, and number of people
                    if !showBranchList {
                        // Logo Image
                        Image("logo")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()

                        // Select Date
                        VStack(alignment: .leading, spacing: 10) {
//                            Text("Choose a Date")
//                                .font(.headline)
                            DatePicker("Reservation Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding()
                        }

                        // Select Time
                        VStack(alignment: .leading, spacing: 10) {
//                            Text("Choose a Time")
//                                .font(.headline)
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
//                            Text("Number of People")
//                                .font(.headline)
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
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                    } else {
                        // Display Branches
                        if isLoading {
                            ProgressView("Loading Branches...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
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

                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)

                // Bottom Tab Bar
                VStack {
                    Spacer()
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
                    .frame(height: 50)
                }
            }
        }
    }

    // Use fake branches for testing
    func fetchBranches() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Simulate API delay
            branches = [
                Branch(
                    id: "1",
                    name: "Downtown Branch",
                    phone: "123-456-7890",
                    address: "123 Main St, City",
                    seats: 10,
                    imageName: "branch1"
                ),
                Branch(
                    id: "2",
                    name: "Uptown Branch",
                    phone: "987-654-3210",
                    address: "456 Elm St, City",
                    seats: 15,
                    imageName: "branch2"
                ),
                Branch(
                    id: "3",
                    name: "Suburban Branch",
                    phone: "555-123-4567",
                    address: "789 Pine Rd, Suburb",
                    seats: 8,
                    imageName: "branch3"
                )
            ]
            isLoading = false
        }
    }

    // Make reservation
    func makeReservation() {
        guard let branch = selectedBranch else { return }
        print("Reservation confirmed for \(branch.name) on \(selectedDate) at \(selectedTime) for \(numberOfPeople) people.")
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

                    Spacer()

                    // Reserve Button
                    Button(action: {
                        onReserve() // Call the reserve action
                    }) {
                        Text("Reserve")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
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



struct ReserveView_Previews: PreviewProvider {
    static var previews: some View {
        ReserveView()
    }
}
