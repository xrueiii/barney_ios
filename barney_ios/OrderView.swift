import SwiftUI

struct OrderView: View {
    @State private var drinks: [Drink] = [] // Drinks fetched from the API
    @State private var isLoading: Bool = true // Loading state
    @State private var showCustomizeSheet: Bool = false // Control Customize Sheet visibility

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
                CustomizeSheetView(drinks: drinks, onSubmit: { order in
                    submitOrder(order: order)
                }).padding().padding(.top, 20)
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

    // Submit order to the API
    func submitOrder(order: Order) {
        guard let url = URL(string: "http://localhost:\(PORT)/api/submitOrder") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let data = try JSONEncoder().encode(order)
            request.httpBody = data

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error submitting order: \(error)")
                    return
                }
                print("Order submitted successfully!")
            }.resume()
        } catch {
            print("Error encoding order: \(error)")
        }
    }
}

struct CustomizeSheetView: View {
    let drinks: [Drink] // 接收來自 API 的飲品數據
    @State private var selectedOption: String = "Existing Drinks" // Default selection
    @State private var selectedDrink: Drink? = nil
    @State private var types: [String] = [] // Types fetched from API
    @State private var items: [String: [String]] = [:] // Items fetched based on type
    @State private var units: [String: String] = [:] // Units fetched for each type
    @State private var customSelections: [CustomSelection] = [] // User's custom drink selections
    @State private var showAlert: Bool = false // 控制成功訊息的顯示

    @Environment(\.dismiss) private var dismiss // 用於關閉 sheet

    let onSubmit: (Order) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Picker("Choose", selection: $selectedOption) {
                    Text("Existing Drinks").tag("Existing Drinks")
                    Text("Custom Drink").tag("Custom Drink")
                }
                .pickerStyle(SegmentedPickerStyle())

                if selectedOption == "Existing Drinks" {
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

                Button("Submit") {
                    if selectedOption == "Existing Drinks", let drink = selectedDrink {
                        let order = Order(type: "Existing", items: [OrderItem(name: drink.drinkName)])
                        onSubmit(order)
                        showAlert = true // 顯示成功訊息
                    } else {
                        let items = customSelections.map {
                            OrderItem(name: $0.item, amount: $0.amount, unit: $0.unit)
                        }
                        let order = Order(type: "Custom", items: items)
                        onSubmit(order)
                        showAlert = true // 顯示成功訊息
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Success"),
                            message: Text("Your order has been submitted successfully!"),
                            dismissButton: .default(Text("OK"), action: {
                                dismiss() // 成功訊息後關閉 sheet
                                })
                            )
                    }
            }
            .padding()
        }
        .presentationDetents([.fraction(0.8)])
        .onAppear {
            fetchTypes()
        }
    }

    var canSubmit: Bool {
        if selectedOption == "Existing Drinks" {
            return selectedDrink != nil
        } else {
            return !customSelections.contains { $0.type.isEmpty || $0.item.isEmpty || $0.amount <= 0 }
        }
    }

    func fetchTypes() {
        guard let url = URL(string: "http://localhost:\(PORT)/api/getTypes") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
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

    func fetchItems(for type: String, completion: @escaping ([String], String) -> Void) {
        guard let url = URL(string: "http://localhost:\(PORT)/api/getItems?type=\(type)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
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
    let name: String
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
