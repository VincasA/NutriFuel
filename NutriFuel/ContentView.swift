import SwiftUI

// MARK: - Data Models

enum IngredientType: String, Codable, CaseIterable {
    case solid = "Solid"
    case liquid = "Liquid"
}

enum IngredientCategory: String, Codable, CaseIterable {
    case meat = "Meat"
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case dairy = "Dairy"
    case grains = "Grains"
    case oils = "Oils"
    case others = "Others"
}

struct Ingredient: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var type: IngredientType
    var kcalsPer100: Double
    var proteinPer100: Double
    var carbsPer100: Double
    var fatsPer100: Double
    var sugarsPer100: Double
    var category: IngredientCategory = .others
}

struct FoodIngredient: Identifiable, Codable {
    var id = UUID()
    var ingredient: Ingredient
    var amount: Double // In grams or milliliters
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
}

struct MacroGoals: Codable {
    var kcals: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var sugars: Double
}

/// Food is either built from ingredients or, for a quick add, using manually entered macros.
struct Food: Identifiable, Codable {
    var id = UUID()
    var name: String
    var ingredients: [FoodIngredient]
    var portionName: String
    var portionSize: Double
    var manualMacros: MacroGoals? = nil
    
    var totalKcals: Double {
        if let manual = manualMacros { return manual.kcals }
        let total = ingredients.reduce(0) { $0 + ($1.ingredient.kcalsPer100 * ($1.amount / 100)) }
        return portionSize > 0 ? total / portionSize : total
    }
    var totalProtein: Double {
        if let manual = manualMacros { return manual.protein }
        let total = ingredients.reduce(0) { $0 + ($1.ingredient.proteinPer100 * ($1.amount / 100)) }
        return portionSize > 0 ? total / portionSize : total
    }
    var totalCarbs: Double {
        if let manual = manualMacros { return manual.carbs }
        let total = ingredients.reduce(0) { $0 + ($1.ingredient.carbsPer100 * ($1.amount / 100)) }
        return portionSize > 0 ? total / portionSize : total
    }
    var totalFats: Double {
        if let manual = manualMacros { return manual.fats }
        let total = ingredients.reduce(0) { $0 + ($1.ingredient.fatsPer100 * ($1.amount / 100)) }
        return portionSize > 0 ? total / portionSize : total
    }
    var totalSugars: Double {
        if let manual = manualMacros { return manual.sugars }
        let total = ingredients.reduce(0) { $0 + ($1.ingredient.sugarsPer100 * ($1.amount / 100)) }
        return portionSize > 0 ? total / portionSize : total
    }
}

struct DiaryEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var mealType: MealType
    var food: Food
    var portionSize: Double
}

// MARK: - Global App Data

class AppData: ObservableObject {
    @Published var savedIngredients: [Ingredient] = [
        Ingredient(name: "Chicken Breast", type: .solid, kcalsPer100: 165, proteinPer100: 31, carbsPer100: 0, fatsPer100: 3.6, sugarsPer100: 0, category: .meat),
        Ingredient(name: "Olive Oil", type: .liquid, kcalsPer100: 884, proteinPer100: 0, carbsPer100: 0, fatsPer100: 100, sugarsPer100: 0, category: .oils)
    ]
    
    @Published var savedFoods: [Food] = [
        Food(
            name: "Grilled Chicken Salad",
            ingredients: [
                FoodIngredient(ingredient: Ingredient(name: "Chicken Breast", type: .solid, kcalsPer100: 165, proteinPer100: 31, carbsPer100: 0, fatsPer100: 3.6, sugarsPer100: 0, category: .meat), amount: 200),
                FoodIngredient(ingredient: Ingredient(name: "Olive Oil", type: .liquid, kcalsPer100: 884, proteinPer100: 0, carbsPer100: 0, fatsPer100: 100, sugarsPer100: 0, category: .oils), amount: 10)
            ],
            portionName: "Plate",
            portionSize: 1
        )
    ]
    
    @Published var diaryEntries: [DiaryEntry] = []
    
    @Published var macroGoals: MacroGoals = MacroGoals(kcals: 2000, protein: 75, carbs: 250, fats: 70, sugars: 50)
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            DiaryView()
                .tabItem { Label("Diary", systemImage: "book") }
            FoodsView()
                .tabItem { Label("Foods", systemImage: "list.bullet") }
            IngredientsView()
                .tabItem { Label("Ingredients", systemImage: "leaf") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

// MARK: - Diary View

struct DiaryView: View {
    @EnvironmentObject var appData: AppData
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var showQuickAddFoodEntry: Bool = false
    
    // Format header title based on date.
    func headerTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            if Calendar.current.component(.year, from: date) == Calendar.current.component(.year, from: Date()) {
                formatter.dateFormat = "MMM d"
            } else {
                formatter.dateFormat = "MMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }
    
    func diaryEntries(for meal: MealType, on date: Date) -> [DiaryEntry] {
        appData.diaryEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date) && $0.mealType == meal
        }
    }
    
    var totalMacros: (kcals: Double, protein: Double, carbs: Double, fats: Double, sugars: Double) {
        let entries = appData.diaryEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        let kcals = entries.reduce(0) { $0 + ($1.food.totalKcals * $1.portionSize) }
        let protein = entries.reduce(0) { $0 + ($1.food.totalProtein * $1.portionSize) }
        let carbs = entries.reduce(0) { $0 + ($1.food.totalCarbs * $1.portionSize) }
        let fats = entries.reduce(0) { $0 + ($1.food.totalFats * $1.portionSize) }
        let sugars = entries.reduce(0) { $0 + ($1.food.totalSugars * $1.portionSize) }
        return (kcals, protein, carbs, fats, sugars)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Date header with Change Date button.
                HStack {
                    Text(headerTitle(for: selectedDate))
                        .font(.largeTitle)
                        .padding(.horizontal)
                    Spacer()
                    Button("Change Date") {
                        showDatePicker.toggle()
                    }
                    .padding(.horizontal)
                }
                if showDatePicker {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.horizontal)
                }
                
                // Macro progress bars with percentages.
                VStack(alignment: .leading, spacing: 10) {
                    MacroProgressView(title: "Calories", value: totalMacros.kcals, goal: appData.macroGoals.kcals)
                    MacroProgressView(title: "Protein", value: totalMacros.protein, goal: appData.macroGoals.protein)
                    MacroProgressView(title: "Carbs", value: totalMacros.carbs, goal: appData.macroGoals.carbs)
                    MacroProgressView(title: "Fats", value: totalMacros.fats, goal: appData.macroGoals.fats)
                    MacroProgressView(title: "Sugars", value: totalMacros.sugars, goal: appData.macroGoals.sugars)
                }
                .padding(.horizontal)
                
                // List diary entries grouped by meal type.
                List {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Section(header: Text(meal.rawValue)) {
                            let entries = diaryEntries(for: meal, on: selectedDate)
                            if entries.isEmpty {
                                Text("No entries")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(entries) { entry in
                                    VStack(alignment: .leading) {
                                        Text(entry.food.name)
                                            .font(.headline)
                                        Text("Portion: \(entry.portionSize, specifier: "%.1f") \(entry.food.portionName)")
                                            .font(.subheadline)
                                    }
                                }
                                .onDelete { indexSet in
                                    // Determine which diary entries to remove
                                    let entriesToDelete = indexSet.map { entries[$0] }
                                    // Remove matching entries from the global diaryEntries array.
                                    appData.diaryEntries.removeAll { diaryEntry in
                                        entriesToDelete.contains(where: { $0.id == diaryEntry.id })
                                    }
                                }
                            }
                        }
                    }
                }

            }
            .navigationTitle("Diary")
            .navigationBarItems(trailing: Button(action: {
                showQuickAddFoodEntry = true
            }, label: {
                Image(systemName: "plus")
            }))
            .sheet(isPresented: $showQuickAddFoodEntry) {
                QuickAddFoodEntryView(diaryDate: selectedDate)
                    .environmentObject(appData)
            }
        }
    }
}

struct MacroProgressView: View {
    var title: String
    var value: Double
    var goal: Double
    
    var percentage: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))/\(Int(goal)) (\(Int(percentage * 100))%)")
                    .font(.caption)
            }
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
    }
}

// MARK: - Quick Add Food Entry (Diary)

struct QuickAddFoodEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appData: AppData
    
    let diaryDate: Date
    @State private var foodName: String = ""
    @State private var mealType: MealType = .breakfast
    @State private var servings: String = "1"
    @State private var kcals: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    @State private var sugars: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Details")) {
                    TextField("Food Name", text: $foodName)
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Text(meal.rawValue)
                        }
                    }
                    TextField("Servings", text: $servings)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Macros per Serving")) {
                    TextField("Calories", text: $kcals)
                        .keyboardType(.decimalPad)
                    TextField("Protein", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fats", text: $fats)
                        .keyboardType(.decimalPad)
                    TextField("Sugars", text: $sugars)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Quick Add Food")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addQuickFood() }
                }
            }
        }
    }
    
    func addQuickFood() {
        guard !foodName.isEmpty,
              let servingsVal = Double(servings),
              let kcalsVal = Double(kcals),
              let proteinVal = Double(protein),
              let carbsVal = Double(carbs),
              let fatsVal = Double(fats),
              let sugarsVal = Double(sugars) else { return }
        
        let manualMacros = MacroGoals(kcals: kcalsVal, protein: proteinVal, carbs: carbsVal, fats: fatsVal, sugars: sugarsVal)
        let quickFood = Food(name: foodName, ingredients: [], portionName: "serving", portionSize: 1, manualMacros: manualMacros)
        let entry = DiaryEntry(date: diaryDate, mealType: mealType, food: quickFood, portionSize: servingsVal)
        appData.diaryEntries.append(entry)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Foods View

struct FoodsView: View {
    @EnvironmentObject var appData: AppData
    @State private var editingFoodIndex: Int? = nil
    @State private var foodsSearchText: String = ""
    
    // Compute indices of foods matching the search text.
    var filteredFoodIndices: [Int] {
        appData.savedFoods.enumerated().compactMap { index, food in
            (foodsSearchText.isEmpty || food.name.localizedCaseInsensitiveContains(foodsSearchText)) ? index : nil
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredFoodIndices, id: \.self) { index in
                    let foodBinding = $appData.savedFoods[index]
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Macros per \(foodBinding.wrappedValue.portionSize, specifier: "%.0f") \(foodBinding.wrappedValue.portionName):")
                            Text("Calories: \(Int(foodBinding.wrappedValue.totalKcals)) kcal")
                            Text("Protein: \(foodBinding.wrappedValue.totalProtein, specifier: "%.1f") g")
                            Text("Carbs: \(foodBinding.wrappedValue.totalCarbs, specifier: "%.1f") g")
                            Text("Fats: \(foodBinding.wrappedValue.totalFats, specifier: "%.1f") g")
                            Text("Sugars: \(foodBinding.wrappedValue.totalSugars, specifier: "%.1f") g")
                            
                            Text("")  // Empty line between macros and ingredients.
                            
                            if !foodBinding.wrappedValue.ingredients.isEmpty {
                                Text("Ingredients:")
                                    .fontWeight(.bold)
                                Text("")  // Empty line after "Ingredients:"
                                ForEach(foodBinding.wrappedValue.ingredients) { ingredientEntry in
                                    Text("\(ingredientEntry.ingredient.name): \(ingredientEntry.amount, specifier: "%.1f")")
                                }
                            }
                            
                            Text("")  // Empty line before the Edit button.
                            
                            Button("Edit") {
                                editingFoodIndex = index
                            }
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    } label: {
                        Text(foodBinding.wrappedValue.name)
                    }
                }
                .onDelete(perform: deleteFood)
            }
            .searchable(text: $foodsSearchText, prompt: "Search Foods")
            .navigationTitle("Foods")
            .navigationBarItems(trailing: Button(action: {
                let newFood = Food(name: "New Food", ingredients: [], portionName: "portion", portionSize: 1)
                appData.savedFoods.append(newFood)
                if let newIndex = appData.savedFoods.firstIndex(where: { $0.id == newFood.id }) {
                    editingFoodIndex = newIndex
                }
            }, label: {
                Image(systemName: "plus")
            }))
            .sheet(isPresented: Binding<Bool>(
                get: { editingFoodIndex != nil },
                set: { if !$0 { editingFoodIndex = nil } }
            )) {
                if let index = editingFoodIndex {
                    EditFoodView(food: $appData.savedFoods[index])
                }
            }
        }
    }
    
    func deleteFood(at offsets: IndexSet) {
        let indicesToDelete = offsets.map { filteredFoodIndices[$0] }
        for index in indicesToDelete.sorted(by: >) {
            appData.savedFoods.remove(at: index)
        }
    }
}

// MARK: - Edit Food View

struct EditFoodView: View {
    @Binding var food: Food
    @EnvironmentObject var appData: AppData
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddIngredientSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Name")) {
                    TextField("Name", text: $food.name)
                }
                Section(header: Text("Total Macros per \(food.portionSize, specifier: "%.0f") \(food.portionName)")) {
                    Text("Calories: \(Int(food.totalKcals)) kcal")
                    Text("Protein: \(food.totalProtein, specifier: "%.1f") g")
                    Text("Carbs: \(food.totalCarbs, specifier: "%.1f") g")
                    Text("Fats: \(food.totalFats, specifier: "%.1f") g")
                    Text("Sugars: \(food.totalSugars, specifier: "%.1f") g")
                }
                Section(header: Text("Ingredients")) {
                    ForEach(food.ingredients) { ingredientEntry in
                        Text("\(ingredientEntry.ingredient.name): \(ingredientEntry.amount, specifier: "%.1f")")
                    }
                    .onDelete(perform: deleteIngredient)
                    Button("Add Ingredient") {
                        showAddIngredientSheet = true
                    }
                }
            }
            .navigationTitle("Edit Food")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showAddIngredientSheet) {
                AddIngredientToFoodView(food: $food)
                    .environmentObject(appData)
            }
        }
    }
    
    func deleteIngredient(at offsets: IndexSet) {
        food.ingredients.remove(atOffsets: offsets)
    }
}



struct IngredientsView: View {
    @EnvironmentObject var appData: AppData
    @State private var searchText: String = ""
    @State private var showAddIngredientForm = false
    @State private var editingIngredient: Ingredient?
    
    // Filter ingredients by name using the search text.
    var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return appData.savedIngredients
        } else {
            return appData.savedIngredients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Group ingredients by category.
                ForEach(IngredientCategory.allCases, id: \.self) { category in
                    let ingredientsInCategory = filteredIngredients.filter { $0.category == category }
                    if !ingredientsInCategory.isEmpty {
                        Section(header: Text(category.rawValue)) {
                            ForEach(ingredientsInCategory) { ingredient in
                                DisclosureGroup {
                                    VStack(alignment: .leading) {
                                        Text("Type: \(ingredient.type.rawValue)")
                                        Text("Calories: \(ingredient.kcalsPer100, specifier: "%.1f") kcal")
                                        Text("Protein: \(ingredient.proteinPer100, specifier: "%.1f") g")
                                        Text("Carbs: \(ingredient.carbsPer100, specifier: "%.1f") g")
                                        Text("Fats: \(ingredient.fatsPer100, specifier: "%.1f") g")
                                        Text("Sugars: \(ingredient.sugarsPer100, specifier: "%.1f") g")
                                        
                                        Text("") // Extra spacing
                                        
                                        Button("Edit") {
                                            editingIngredient = ingredient
                                        }
                                        .font(.headline)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                    .padding(.leading)
                                } label: {
                                    Text(ingredient.name)
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ingredients")
            .navigationBarItems(trailing: Button(action: {
                showAddIngredientForm = true
            }) {
                Image(systemName: "plus")
            })
            .searchable(text: $searchText, prompt: "Search Ingredients")
            .sheet(isPresented: $showAddIngredientForm) {
                AddIngredientFormView()
                    .environmentObject(appData)
            }
            .sheet(item: $editingIngredient) { ingredient in
                // Present an edit view for the ingredient.
                // You can adjust this view as needed.
                EditIngredientView(ingredient: Binding(
                    get: {
                        if let index = appData.savedIngredients.firstIndex(of: ingredient) {
                            return appData.savedIngredients[index]
                        }
                        return ingredient
                    },
                    set: { newValue in
                        if let index = appData.savedIngredients.firstIndex(of: ingredient) {
                            appData.savedIngredients[index] = newValue
                        }
                    }
                ))
            }
        }
    }
}

struct AddIngredientFormView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var type: IngredientType = .solid
    @State private var category: IngredientCategory = .others
    @State private var kcals: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    @State private var sugars: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Details")) {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(IngredientType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Picker("Category", selection: $category) {
                        ForEach(IngredientCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                Section(header: Text("Macros per 100g/ml")) {
                    TextField("Calories", text: $kcals)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fats (g)", text: $fats)
                        .keyboardType(.decimalPad)
                    TextField("Sugars (g)", text: $sugars)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveIngredient()
                }
            )
        }
    }
    
    func saveIngredient() {
        guard !name.isEmpty else { return }
        let newIngredient = Ingredient(
            name: name,
            type: type,
            kcalsPer100: Double(kcals) ?? 0,
            proteinPer100: Double(protein) ?? 0,
            carbsPer100: Double(carbs) ?? 0,
            fatsPer100: Double(fats) ?? 0,
            sugarsPer100: Double(sugars) ?? 0,
            category: category
        )
        appData.savedIngredients.append(newIngredient)
        presentationMode.wrappedValue.dismiss()
    }
}


// MARK: - Add Ingredient to Food View
struct AddIngredientToFoodView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.presentationMode) var presentationMode
    @Binding var food: Food
    @State private var selectedIngredient: Ingredient?
    @State private var amount: String = ""
    
    // Extracted picker to simplify type-checking.
    var ingredientPicker: some View {
        Picker("Ingredient", selection: $selectedIngredient) {
            ForEach(appData.savedIngredients, id: \.id) { ingredient in
                Text(ingredient.name)
                    .tag(ingredient as Ingredient?)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Ingredient")) {
                    ingredientPicker
                }
                Section(header: Text("Amount (g or ml)")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add", action: addIngredient)
            )
        }
    }
    
    func addIngredient() {
        guard let ingredient = selectedIngredient, let amt = Double(amount) else { return }
        let foodIngredient = FoodIngredient(ingredient: ingredient, amount: amt)
        food.ingredients.append(foodIngredient)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Ingredient View

struct EditIngredientView: View {
    @Binding var ingredient: Ingredient
    @Environment(\.presentationMode) var presentationMode
    
    // A basic number formatter for decimal values.
    static let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Details")) {
                    TextField("Name", text: $ingredient.name)
                    Picker("Type", selection: $ingredient.type) {
                        ForEach(IngredientType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Picker("Category", selection: $ingredient.category) {
                        ForEach(IngredientCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                Section(header: Text("Macros per 100g/ml")) {
                    TextField("Calories", value: $ingredient.kcalsPer100, formatter: Self.numberFormatter)
                        .keyboardType(.decimalPad)
                    TextField("Protein", value: $ingredient.proteinPer100, formatter: Self.numberFormatter)
                        .keyboardType(.decimalPad)
                    TextField("Carbs", value: $ingredient.carbsPer100, formatter: Self.numberFormatter)
                        .keyboardType(.decimalPad)
                    TextField("Fats", value: $ingredient.fatsPer100, formatter: Self.numberFormatter)
                        .keyboardType(.decimalPad)
                    TextField("Sugars", value: $ingredient.sugarsPer100, formatter: Self.numberFormatter)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var kcalsGoal: String = ""
    @State private var proteinGoal: String = ""
    @State private var carbsGoal: String = ""
    @State private var fatsGoal: String = ""
    @State private var sugarsGoal: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Macro Goals")) {
                    GoalField(title: "Calories", value: $kcalsGoal)
                    GoalField(title: "Protein", value: $proteinGoal)
                    GoalField(title: "Carbs", value: $carbsGoal)
                    GoalField(title: "Fats", value: $fatsGoal)
                    GoalField(title: "Sugars", value: $sugarsGoal)
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: loadSettings)
            .onDisappear(perform: saveSettings)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        saveSettings()
                        dismissKeyboard()
                    }
                }
            }
        }
    }
    
    func loadSettings() {
        kcalsGoal = String(format: "%.0f", appData.macroGoals.kcals)
        proteinGoal = String(format: "%.1f", appData.macroGoals.protein)
        carbsGoal = String(format: "%.1f", appData.macroGoals.carbs)
        fatsGoal = String(format: "%.1f", appData.macroGoals.fats)
        sugarsGoal = String(format: "%.1f", appData.macroGoals.sugars)
    }
    
    func saveSettings() {
        if let kcalsValue = Double(kcalsGoal),
           let proteinValue = Double(proteinGoal),
           let carbsValue = Double(carbsGoal),
           let fatsValue = Double(fatsGoal),
           let sugarsValue = Double(sugarsGoal) {
            appData.macroGoals = MacroGoals(kcals: kcalsValue, protein: proteinValue, carbs: carbsValue, fats: fatsValue, sugars: sugarsValue)
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct GoalField: View {
    var title: String
    @Binding var value: String
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("Goal", text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
