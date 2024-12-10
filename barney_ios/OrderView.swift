import SwiftUI

struct OrderView: View {
    @State private var drinks: [Drink] = [] // Drinks fetched from the API
    @State private var isLoading: Bool = true // Loading state
    @State private var showCustomizeSheet: Bool = false // Control Customize Sheet visibility
    @State private var showOrderDetailsSheet: Bool = false // Control Order Details Sheet visibility
    @State var order: Order = Order(type: "", items: [])  // Store the submitted order
    
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
                        .padding()

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
                            showCustomizeSheet.toggle()
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .padding()
                                .clipShape(RoundedRectangle(cornerRadius: 50))
                        }
                        .background(Circle().fill(Color.accentColor.opacity(0.8))).shadow(radius: 2)
                        .padding(.trailing, 20)
                        .padding(.bottom, 85) // Positioned above the tab bar
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline) // Inline title style
            .onAppear {
                fetchDrinks()
            }
            .sheet(isPresented: $showCustomizeSheet) {
                CustomizeSheetView(drinks: drinks, order: $order, onNext: { submittedOrder in
                    self.order = submittedOrder
                    showCustomizeSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showOrderDetailsSheet = true
                    }
                })
            }
            .sheet(isPresented: $showOrderDetailsSheet) {
                OrderDetailsSheet(order: $order, onSubmit: {
                    showOrderDetailsSheet = false
                    print("Order confirmed successfully!")
                })
            }
        }
    }

    // Fetch drinks from the API
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

struct CustomizeSheetView: View {
    let drinks: [Drink] // 接收來自 API 的飲品數據
    @State private var selectedOption: String = "Existing Drinks" // Default selection
    @State private var selectedDrink: Drink? = nil
    @State private var types: [String] = [] // Types fetched from API
    @State private var items: [String: [String]] = [:] // Items fetched based on type
    @State private var units: [String: String] = [:] // Units fetched for each type
    @State private var customSelections: [CustomSelection] = [CustomSelection()] // User's custom drink selections
    @Binding var order: Order
    let onNext: (Order) -> Void // Callback to handle next action
    
    

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Order").font(.title3).fontWeight(.bold)
                
                Picker("Choose", selection: $selectedOption) {
                    Text("Existing Drinks").tag("Existing Drinks")
                    Text("Custom Drink").tag("Custom Drink")
                }
                .pickerStyle(SegmentedPickerStyle())

                if selectedOption == "Existing Drinks" {
                    // Existing Drinks List
                    List(drinks) { drink in
                        HStack {
                            Text(drink.drinkName)
                            Spacer()
                            if selectedDrink?.id == drink.id {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .onTapGesture {
                            selectedDrink = drink
                        }
                    }
                } else {
                    // Custom Drink Creation
                    ScrollView {
                        ForEach(customSelections.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 20) {
                                Picker("Type", selection: $customSelections[index].type) {
                                    Text("None").tag("")
                                    ForEach(types, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: customSelections[index].type) { newType in
                                    fetchItems(for: newType) { fetchedItems, fetchedUnit in
                                        items[newType] = fetchedItems
                                        units[newType] = fetchedUnit
                                        customSelections[index].item = ""
                                        customSelections[index].unit = fetchedUnit
                                    }
                                }

                                Picker("Item", selection: $customSelections[index].item) {
                                    Text("None").tag("")
                                    ForEach(items[customSelections[index].type] ?? [], id: \.self) { item in
                                        Text(item).tag(item)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())

                                HStack {
                                    TextField("Amount", value: $customSelections[index].amount, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                    Text(customSelections[index].unit)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }

                        Button(action: {
                            customSelections.append(CustomSelection())
                        }) {
                            Label("Add Item", systemImage: "plus.circle")
                        }
                    }
                }

                Button("Next") {
                    if selectedOption == "Existing Drinks", let drink = selectedDrink {
                        order = Order(type: "Existing", items: [OrderItem(id: drink.id, amount: 1, unit:"")])
                        print(order)
                        onNext(order) // Pass the order back
                    } else {
                        let items = customSelections.map {
                            OrderItem(id: $0.item, amount: $0.amount, unit: $0.unit)
                        }
                        order = Order(type: "Custom", items: items)
                        onNext(order) // Pass the order back
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
            .padding()
        }
        .onAppear {
            fetchTypes() // Fetch types on appear
        }
        .presentationDetents([.fraction(0.7)])
        .padding()
    }

    // Determines if the user can proceed to the next step
    var canSubmit: Bool {
        if selectedOption == "Existing Drinks" {
            return selectedDrink != nil
        } else {
            return !customSelections.contains { $0.type.isEmpty || $0.item.isEmpty || $0.amount <= 0 }
        }
    }

    // Fetches available types from the API
    func fetchTypes() {
        guard let url = URL(string: "http://localhost:\(PORT)/api/getTypes") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching types: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let fetchedTypes = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    types = fetchedTypes
                }
            } catch {
                print("Error decoding types: \(error)")
            }
        }.resume()
    }

    // Fetches items and units for a selected type from the API
    func fetchItems(for type: String, completion: @escaping ([String], String) -> Void) {
        guard let url = URL(string: "http://localhost:\(PORT)/api/getItems?type=\(type)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching items: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(ItemResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.items, response.unit)
                }
            } catch {
                print("Error decoding items: \(error)")
            }
        }.resume()
    }
}

struct OrderDetailsSheet: View {
    @Binding var order: Order // 暫存的訂單資訊
    let onSubmit: () -> Void // 完成提交的回調
    @State private var selectedOption: String = "Dine-In" // 默認選項
    @State private var address: String = "" // 使用者地址
    @State private var selectedBranch: String = "" // 已選擇的分店
    @State private var branches: [Branch] = [] // 從 API 獲取的分店列表
    @State private var pickupTime: Date = Date() // 領取時間
    @State private var showAlert: Bool = false // 顯示成功訊息
    
    let savedData = UserDefaults().array(forKey: "userArray") as? [String]

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Order Detail").font(.title3).fontWeight(.bold)
                
                Picker("Order Type", selection: $selectedOption) {
                    Text("Dine In").tag("Dine-In")
                    Text("Takeaway").tag("Takeaway")
                    Text("Delivery").tag("Delivery")
                }
                .pickerStyle(SegmentedPickerStyle())

                if selectedOption == "Delivery" {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Enter your address:")
                        TextField("Address", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Select a branch:")
                        Menu {
                            ForEach(branches) { branch in
                                Button(action: {
                                    selectedBranch = branch.id
                                }) {
                                    Text(branch.name)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedBranch.isEmpty ? "Choose a branch" : selectedBranch)
                                    .foregroundColor(selectedBranch.isEmpty ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select a branch:")
                        Menu {
                            ForEach(branches) { branch in
                                Button(action: {
                                    selectedBranch = branch.id
                                }) {
                                    Text(branch.name)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedBranch.isEmpty ? "Choose a branch" : selectedBranch)
                                    .foregroundColor(selectedBranch.isEmpty ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }

                // 領取時間選擇
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Pickup Time:")
                    HStack {
                        DatePicker("Pickup Time", selection: $pickupTime, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .frame(maxWidth: .infinity) // 將 DatePicker 寬度設為最大
                    }
                    .padding()
                    .background(Color(.systemGray6)) // 添加背景區域
                    .cornerRadius(8) // 圓角
                }
                .padding()

                Button("Submit") {
                    guard !order.items.isEmpty else { return }

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let formattedTime = dateFormatter.string(from: pickupTime)

                    let finalOrder = FinalOrder(
                        type: order.type,
                        items: order.items,
                        deliveryType: selectedOption,
                        address: (selectedOption == "Delivery") ? address : nil,
                        branchId: selectedBranch,
                        memberId: savedData![5],
                        pickupTime: formattedTime
                    )
                    
                    showAlert = true
                    submitOrder(finalOrder) {
                        showAlert = true // 顯示成功訊息
                    }
                    order = Order(type: "", items: [])
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    (selectedOption == "Delivery" && address.isEmpty) ||
                    (selectedOption != "Delivery" && selectedBranch.isEmpty)
                )
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Success"),
                        message: Text("Your order has been submitted successfully!"),
                        dismissButton: .default(Text("OK"), action: {
                            onSubmit() // 清除暫存的資料並關閉 Sheet
                        })
                    )
                }
            }
            .padding()
        }
        .onAppear {
            fetchBranches()
        }
        .presentationDetents([.fraction(0.8)])
        .padding()
        
    }

    // Fetch branches from the API
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
                }
            } catch {
                print("Error decoding branches: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Submit the final order to the API
    private func submitOrder(_ finalOrder: FinalOrder, completion: @escaping () -> Void) {
        guard let url = URL(string: "http://localhost:\(PORT)/api/postOrder") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let data = try JSONEncoder().encode(finalOrder)
            request.httpBody = data

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error submitting order: \(error)")
                    return
                }
                DispatchQueue.main.async {
                    completion() // 回調通知成功
                }
            }.resume()
        } catch {
            print("Error encoding final order: \(error)")
        }
    }
}

// Final order structure for submission
struct FinalOrder: Codable {
    let type: String
    let items: [OrderItem]
    let deliveryType: String
    let address: String?
    let branchId: String?
    let memberId: String?
    let pickupTime: String // 新增領取時間字段
}

struct CustomSelection {
    var type: String = ""
    var item: String = ""
    var amount: Double = 0.0
    var unit: String = "ml"
}

struct Drink: Identifiable, Codable {
    var id: String
    let drinkName: String
    let flavor: String
    let mood: String
    let intensity: Int
}

struct Order: Codable {
    let type: String
    let items: [OrderItem]
}

struct OrderItem: Codable {
    let id: String
    var amount: Double?
    var unit: String?
}

struct ItemResponse: Codable {
    let items: [String]
    let unit: String
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
    }
}

struct OrderView_Previews: PreviewProvider {
    static var previews: some View {
        OrderView()
    }
}
