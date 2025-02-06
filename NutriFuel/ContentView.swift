//
//  ContentView.swift
//  NutriFuel
//
//  Created by Vincas Anikevičius on 05/02/2025.
//

import SwiftUI

// MARK: - Data Models

/// A food that the user can save and later add to his diary.
struct Food: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var kcals: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var sugars: Double
}

enum MealCategory: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
    case uncategorized = "Uncategorized"
}

/// An entry in the diary (a food eaten on a specific date).
struct DiaryEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var food: Food
    var category: MealCategory // NEW
}

/// The user’s goals/limits for each macro.
struct MacroGoals: Codable {
    var kcals: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var sugars: Double
}

// MARK: - Global App Data

class AppData: ObservableObject {
    @Published var savedFoods: [Food] = []
    @Published var diaryEntries: [DiaryEntry] = []
    @Published var macroGoals: MacroGoals = MacroGoals(kcals: 0, protein: 0, carbs: 0, fats: 0, sugars: 0)
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            DiaryView()
                .tabItem {
                    Label("Diary", systemImage: "book")
                }
            FoodsView()
                .tabItem {
                    Label("Foods", systemImage: "list.bullet")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Diary Page

struct DiaryView: View {
    @EnvironmentObject var appData: AppData
    @State private var selectedDate: Date = Date()
    @State private var showAddFoodSheet = false
    @State private var selectedMacro: String? = nil
    @State private var macroBreakdown: [(String, Double)] = []
    @State private var showMacroDetails = false
    
    /// Formats the selected date as “Today” (if today) or “MMM d”
    var formattedDate: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with simplified date display and a compact DatePicker.
                HStack {
                    Text(formattedDate)
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                }
                .padding()
                
                // Filter diary entries for the selected day.
                let diaryForSelectedDay = appData.diaryEntries.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
                }
                
                // Calculate total macros consumed that day.
                let totalKcals   = diaryForSelectedDay.reduce(0) { $0 + $1.food.kcals }
                let totalProtein = diaryForSelectedDay.reduce(0) { $0 + $1.food.protein }
                let totalCarbs   = diaryForSelectedDay.reduce(0) { $0 + $1.food.carbs }
                let totalFats    = diaryForSelectedDay.reduce(0) { $0 + $1.food.fats }
                let totalSugars  = diaryForSelectedDay.reduce(0) { $0 + $1.food.sugars }
                
                // Main scroll view for the progress bars.
                ScrollView {
                    VStack(spacing: 20) {
                        MacroProgressView(macroName: "Calories", total: totalKcals, goal: appData.macroGoals.kcals, unit: "kcal") {
                            showMacroDetails(for: "Calories", macroValue: { $0.kcals }, unit: "kcal")
                        }
                        MacroProgressView(macroName: "Protein", total: totalProtein, goal: appData.macroGoals.protein, unit: "g") {
                            showMacroDetails(for: "Protein", macroValue: { $0.protein }, unit: "g")
                        }
                        MacroProgressView(macroName: "Carbs", total: totalCarbs, goal: appData.macroGoals.carbs, unit: "g") {
                            showMacroDetails(for: "Carbs", macroValue: { $0.carbs }, unit: "g")
                        }
                        MacroProgressView(macroName: "Fats", total: totalFats, goal: appData.macroGoals.fats, unit: "g") {
                            showMacroDetails(for: "Fats", macroValue: { $0.fats }, unit: "g")
                        }
                        MacroProgressView(macroName: "Sugars", total: totalSugars, goal: appData.macroGoals.sugars, unit: "g") {
                            showMacroDetails(for: "Sugars", macroValue: { $0.sugars }, unit: "g")
                        }
                    }
                    .padding()
                }
                
                let groupedEntries = Dictionary(grouping: diaryForSelectedDay, by: { $0.category })
                
                // List of diary entries.
                List {
                    ForEach(MealCategory.allCases, id: \.self) { category in
                            if let entries = groupedEntries[category], !entries.isEmpty {
                                Section(header: Text(category.rawValue)) {
                                    ForEach(entries) { entry in
                                        VStack(alignment: .leading) {
                                            Text(entry.food.name)
                                                .font(.headline)
                                            HStack {
                                                Text("kcal: \(entry.food.kcals, specifier: "%.0f")")
                                                Text("Protein: \(entry.food.protein, specifier: "%.1f")g")
                                                Text("Carbs: \(entry.food.carbs, specifier: "%.1f")g")
                                            }
                                            HStack {
                                                Text("Fats: \(entry.food.fats, specifier: "%.1f")g")
                                                Text("Sugars: \(entry.food.sugars, specifier: "%.1f")g")
                                            }
                                        }
                                    }
                                    .onDelete(perform: { indexSet in
                                        deleteDiaryEntry(at: indexSet, from: entries)
                                    })
                                }
                            }
                        }
                }
                
                // Button to add a saved food to the diary.
                Button(action: {
                    showAddFoodSheet = true
                }) {
                    Text("Add Food")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding([.leading, .trailing])
                }
                .padding(.bottom)
                .sheet(isPresented: $showMacroDetails) {
                    NavigationView {
                        List(macroBreakdown, id: \.0) { foodName, value in
                            HStack {
                                Text(foodName)
                                Spacer()
                                Text("\(value, specifier: "%.1f") \(selectedMacro ?? "")")
                            }
                        }
                        .navigationTitle("\(selectedMacro ?? "") Breakdown")
                    }
                }
            }
            .navigationTitle("Diary")
            .sheet(isPresented: $showAddFoodSheet) {
                AddFoodToDiaryView(selectedDate: selectedDate)
                    .environmentObject(appData)
            }
        }
    }
    
    /// Deletes diary entries using the filtered indices.
    func deleteDiaryEntry(at offsets: IndexSet, from categoryEntries: [DiaryEntry]) {
        let indicesToDelete = offsets.map { appData.diaryEntries.firstIndex(of: categoryEntries[$0])! }
        for index in indicesToDelete.sorted(by: >) {
            appData.diaryEntries.remove(at: index)
        }
    }

    
    func showMacroDetails(for macro: String, macroValue: (Food) -> Double, unit: String) {
        let diaryForSelectedDay = appData.diaryEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
        
        let breakdown = diaryForSelectedDay.map { ($0.food.name, macroValue($0.food)) }
        
        self.selectedMacro = macro
        self.macroBreakdown = breakdown
        self.showMacroDetails = true
    }

}

/// A view that displays a progress bar for one macro.
struct MacroProgressView: View {
    var macroName: String
    var total: Double
    var goal: Double
    var unit: String
    var onTap: () -> Void
    
    var percentage: Double {
        goal > 0 ? (total / goal) * 100 : 0
    }
    
    /// Returns the fraction (0...1) of the goal reached.
    var progress: Double {
        goal > 0 ? min(total / goal, 1.0) : 0.0
    }
    
    var progressColor: Color {
        return total > goal ? .red : .blue
    }
    
    var formattedPercentage: String {
        total > goal ? "\(Int(percentage))%" : "\(Int(percentage))%"
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("\(macroName): \(total, specifier: "%.1f")/\(goal, specifier: "%.1f") \(unit)")
                Spacer()
                Text(formattedPercentage) //Show percentage
                    .bold()
                    .foregroundColor(progressColor)
            }
            ProgressView(value: progress)
                .accentColor(progressColor)
                .onTapGesture {
                    onTap()
                }
        }
    }
}

/// A view (presented as a sheet) that lists saved foods so the user can add one to the diary.
struct AddFoodToDiaryView: View {
    @EnvironmentObject var appData: AppData
    var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var kcals: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    @State private var sugars: String = ""
    
    @State private var selectedCategory: MealCategory = .uncategorized
    
    var body: some View {
        NavigationView {
            Form {
                // Section for entering food details
                Section(header: Text("Food Details")) {
                    TextField("Name", text: $name)
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
                
                // Section for selecting meal category
                Section(header: Text("Select Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(MealCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Dropdown-style picker
                }
            }
            .navigationTitle("Add Food")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveFood()
                }
            )
        }
    }
    
    /// Saves the food entry and adds it to the diary
    func saveFood() {
        guard !name.isEmpty,
              let kcalsValue = Double(kcals),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatsValue = Double(fats),
              let sugarsValue = Double(sugars) else {
            // You could add an alert here for invalid input
            return
        }
        
        let newFood = Food(name: name, kcals: kcalsValue, protein: proteinValue, carbs: carbsValue, fats: fatsValue, sugars: sugarsValue)
        let newEntry = DiaryEntry(date: selectedDate, food: newFood, category: selectedCategory)
        
        appData.diaryEntries.append(newEntry)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Foods Page

struct FoodsView: View {
    @EnvironmentObject var appData: AppData
    @State private var showAddFoodForm = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appData.savedFoods) { food in
                    // Use a DisclosureGroup to toggle display of macro details.
                    DisclosureGroup(
                        content: {
                            VStack(alignment: .leading) {
                                Text("Calories: \(food.kcals, specifier: "%.0f")")
                                Text("Protein: \(food.protein, specifier: "%.1f")g")
                                Text("Carbs: \(food.carbs, specifier: "%.1f")g")
                                Text("Fats: \(food.fats, specifier: "%.1f")g")
                                Text("Sugars: \(food.sugars, specifier: "%.1f")g")
                            }
                            .padding(.leading)
                        },
                        label: {
                            Text(food.name)
                                .font(.headline)
                        }
                    )
                }
                .onDelete(perform: deleteFood)
            }
            .navigationTitle("Foods")
            .navigationBarItems(trailing: Button(action: {
                showAddFoodForm = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showAddFoodForm) {
                AddFoodFormView()
                    .environmentObject(appData)
            }
        }
    }
    
    func deleteFood(at offsets: IndexSet) {
        appData.savedFoods.remove(atOffsets: offsets)
    }
}

/// A form view to add a new food to the saved foods list.
struct AddFoodFormView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var kcals: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    @State private var sugars: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Details")) {
                    TextField("Name", text: $name)
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
            .navigationTitle("Add Food")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                saveFood()
            })
        }
    }
    
    func saveFood() {
        guard !name.isEmpty,
              let kcalsValue = Double(kcals),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatsValue = Double(fats),
              let sugarsValue = Double(sugars) else {
            return
        }
        
        let newFood = Food(name: name, kcals: kcalsValue, protein: proteinValue, carbs: carbsValue, fats: fatsValue, sugars: sugarsValue)
        appData.savedFoods.append(newFood)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Settings Page

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
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("Goal", text: $kcalsGoal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("Goal", text: $proteinGoal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("Goal", text: $carbsGoal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Fats")
                        Spacer()
                        TextField("Goal", text: $fatsGoal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Sugars")
                        Spacer()
                        TextField("Goal", text: $sugarsGoal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Save") {
                saveSettings()
            })
            .onAppear(perform: loadSettings)
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
}
