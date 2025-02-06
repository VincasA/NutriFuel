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

/// An entry in the diary (a food eaten on a specific date).
struct DiaryEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var food: Food
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
    @Published var macroGoals: MacroGoals = MacroGoals(kcals: 2000, protein: 100, carbs: 250, fats: 70, sugars: 50)
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
                        MacroProgressView(macroName: "Calories", total: totalKcals, goal: appData.macroGoals.kcals, unit: "kcal")
                        MacroProgressView(macroName: "Protein", total: totalProtein, goal: appData.macroGoals.protein, unit: "g")
                        MacroProgressView(macroName: "Carbs", total: totalCarbs, goal: appData.macroGoals.carbs, unit: "g")
                        MacroProgressView(macroName: "Fats", total: totalFats, goal: appData.macroGoals.fats, unit: "g")
                        MacroProgressView(macroName: "Sugars", total: totalSugars, goal: appData.macroGoals.sugars, unit: "g")
                    }
                    .padding()
                }
                
                // List of diary entries.
                List {
                    Section(header: Text("Diary Entries")) {
                        if diaryForSelectedDay.isEmpty {
                            Text("No entries for this day.")
                        } else {
                            ForEach(diaryForSelectedDay) { entry in
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
                            .onDelete(perform: deleteDiaryEntry)
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
                .sheet(isPresented: $showAddFoodSheet) {
                    AddFoodToDiaryView(selectedDate: selectedDate)
                        .environmentObject(appData)
                }
            }
            .navigationTitle("Diary")
        }
    }
    
    /// Deletes diary entries using the filtered indices.
    func deleteDiaryEntry(at offsets: IndexSet) {
        let diaryForSelectedDay = appData.diaryEntries.enumerated().filter { Calendar.current.isDate($1.date, inSameDayAs: selectedDate) }
        let indicesToDelete = offsets.map { diaryForSelectedDay[$0].offset }
        for index in indicesToDelete.sorted(by: >) {
            appData.diaryEntries.remove(at: index)
        }
    }
}

/// A view that displays a progress bar for one macro.
struct MacroProgressView: View {
    var macroName: String
    var total: Double
    var goal: Double
    var unit: String
    
    /// Returns the fraction (0...1) of the goal reached.
    var progress: Double {
        goal > 0 ? min(total / goal, 1.0) : 0.0
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(macroName): \(total, specifier: "%.1f")/\(goal, specifier: "%.1f") \(unit)")
            ProgressView(value: progress)
                .accentColor(progress >= 1.0 ? .green : .blue)
        }
    }
}

/// A view (presented as a sheet) that lists saved foods so the user can add one to the diary.
struct AddFoodToDiaryView: View {
    @EnvironmentObject var appData: AppData
    var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if appData.savedFoods.isEmpty {
                    Text("No saved foods. Please add foods in the Foods tab.")
                } else {
                    ForEach(appData.savedFoods) { food in
                        Button(action: {
                            // Create a diary entry with the selected food.
                            let newEntry = DiaryEntry(date: selectedDate, food: food)
                            appData.diaryEntries.append(newEntry)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            VStack(alignment: .leading) {
                                Text(food.name)
                                    .font(.headline)
                                HStack {
                                    Text("kcal: \(food.kcals, specifier: "%.0f")")
                                    Text("Protein: \(food.protein, specifier: "%.1f")g")
                                    Text("Carbs: \(food.carbs, specifier: "%.1f")g")
                                }
                                HStack {
                                    Text("Fats: \(food.fats, specifier: "%.1f")g")
                                    Text("Sugars: \(food.sugars, specifier: "%.1f")g")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Food")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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
