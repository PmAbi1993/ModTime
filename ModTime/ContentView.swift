//
//  ContentView.swift
//  ModTime
//
//  Created by Abhijith Pm on 22/09/24.
//

import SwiftUI

enum Tabs: Hashable {
    case home
    case tasks
    case settings
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .tasks: return "Tasks"
        case .settings: return "Settings"
        }
    }
    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .tasks: "plus.square.dashed"
        case .settings: "gear"
        }
    }
}

struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var selectedTab: Tabs = .home // Default to Home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: Tabs.home.systemImage, value: .home) {
                NavigationStack {
                    Home(selectedTab: $selectedTab)
                        .navigationTitle("Home")
                }
            }
            Tab("Tasks", systemImage: Tabs.tasks.systemImage, value: .tasks) {
                NavigationStack {
                    TasksView()
                        .navigationTitle("Tasks")
                }
            }
            Tab("Settings", systemImage: Tabs.settings.systemImage, value: .settings) {
                NavigationStack {
                    Settings()
                        .navigationTitle("Settings")
                        .environmentObject(taskViewModel) // Provide access if needed
                }
            }
        }
        .environmentObject(taskViewModel) // Inject into environment
    }
}



struct Home: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingAddTask = false
    @Binding var selectedTab: Tabs // Bind to change the selected tab
    
    var body: some View {
        List {
            if taskViewModel.tasks.isEmpty {
                Text("No tasks available. Tap + to add a new task.")
                    .foregroundColor(.gray)
            } else {
                ForEach(taskViewModel.tasks.indices, id: \.self) { index in
                    let task = taskViewModel.tasks[index]
                    VStack(alignment: .leading) {
                        Text(task.title)
                            .font(.headline)
                        Text(task.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Ends at: \(task.endTime, formatter: taskDateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle()) // Make the entire row tappable
                    .onTapGesture {
                        taskViewModel.startTask(at: index)
                        selectedTab = .tasks
                        taskViewModel.initiateCurrentTaskTimer()
                    }
                }
                .onDelete(perform: deleteTasks)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(
            trailing: Button(action: {
                showingAddTask.toggle()
            }) {
                Image(systemName: "plus")
                    .imageScale(.large)
            }
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(isPresented: $showingAddTask)
                .environmentObject(taskViewModel)
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        taskViewModel.tasks.remove(atOffsets: offsets)
        // Adjust currentTaskIndex if necessary
        if let currentIndex = taskViewModel.currentTaskIndex, offsets.contains(currentIndex) {
            taskViewModel.completeCurrentTask()
        } else if let currentIndex = taskViewModel.currentTaskIndex, currentIndex > offsets.first! {
            taskViewModel.currentTaskIndex = currentIndex - offsets.count
        }
    }
    
    private var taskDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}



struct Settings: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                Text("Profile")
            }
            Section(header: Text("Options")) {
                Button("Clear All Tasks") {
                    taskViewModel.clearAllTasks()
                }
                .foregroundColor(.red)
                
                Button("Logout") {
                    // Implement logout functionality
                }
            }
        }
    }
}



struct WaterFillView: View {
    var task: Task
    @State private var percentage: Double = 0.0
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .center) {
                    Text(task.title)
                        .font(.largeTitle)
                        .padding(.bottom, 5)
                    Text(task.subtitle)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Ends at: \(task.endTime, formatter: taskDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                ZStack(alignment: .bottom) {
                    // Glass container
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.blue, lineWidth: 2)
//                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Water fill with top rounded corners
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.blue.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: CGFloat(geometry.size.height * 0.6) * CGFloat(percentage / 100))
                        .clipShape(CustomTopRoundedShape(cornerRadius: 15))
                        .animation(.easeInOut(duration: 1.0), value: percentage)
                }
            }
            .onAppear {
                startFilling()
            }
            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                updatePercentage()
            }
        }
//        .padding()
    }
    
    private func startFilling() {
        updatePercentage()
    }
    
    private func updatePercentage() {
        let totalTime = task.endTime.timeIntervalSince(task.startTime)
        let elapsedTime = Date().timeIntervalSince(task.startTime)
        
        if elapsedTime >= totalTime {
            percentage = 100
            taskViewModel.completeCurrentTask()
        } else if elapsedTime >= 0 {
            let progress = (elapsedTime / totalTime) * 100
            percentage = min(progress, 100)
        } else {
            percentage = 0
        }
    }
    
    private var taskDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}


struct CustomTopRoundedShape: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at the bottom left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // Draw a line to the bottom right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // Draw a line to the top right corner, applying a corner radius
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius))
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: -90),
                    clockwise: true)
        
        // Draw a line to the top left corner, applying a corner radius
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: -90),
                    endAngle: Angle(degrees: -180),
                    clockwise: true)
        
        // Finish the path by drawing a line to the bottom left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        return path
    }
}

#Preview {
    ContentView()
}
