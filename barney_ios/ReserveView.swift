import SwiftUI

struct ReserveView: View {
    @State private var selectedDate = Date()
    @State private var numberOfPeople = 1
    @State private var branches: [Branch] = [] // List of branches available for reservation
    @State private var selectedBranch: Branch? = nil
    @State private var showBranchList = false
    @State private var isLoading = false // No need to show loading animation with fake data

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 2) {
                    // If branch list is not shown, show calendar and number of people
                    if !showBranchList {
                         //Logo Image
                        Image("logo")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()

                        // Select Date
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Choose a Date")
                                .font(.headline)
                            DatePicker("Reservation Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding()
                        }

                        // Select Number of People
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Number of People")
                                .font(.headline)
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
        print("Reservation confirmed for \(branch.name) on \(selectedDate) for \(numberOfPeople) people.")
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
