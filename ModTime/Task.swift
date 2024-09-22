//
//  Task.swift
//  ModTime
//
//  Created by Abhijith Pm on 23/09/24.
//

import SwiftUI
import Foundation

struct Task: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let startTime: Date
    let endTime: Date
    
    init(id: UUID = UUID(), title: String, subtitle: String, startTime: Date = Date(), endTime: Date) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startTime = startTime
        self.endTime = endTime
    }
}


import SwiftUI
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var currentTaskIndex: Int? = nil // Index of the current task
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        loadTasks()
    }
    var currentTask: Task? {
        guard let index = currentTaskIndex, tasks.indices.contains(index) else {
            return nil
        }
        return tasks[index]
    }
    
    func addTask(title: String, subtitle: String, endTime: Date) {
        let newTask = Task(title: title, subtitle: subtitle, startTime: Date(), endTime: endTime)
        tasks.append(newTask)
        
        // If no task is currently active, start this task
        if currentTaskIndex == nil {
            startTask(at: tasks.count - 1)
            initiateCurrentTaskTimer()
        }
        saveTasks()
    }

    
    func startTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        currentTaskIndex = index
    }
    
    func completeCurrentTask() {
        // Move to the next task if available
        if let currentIndex = currentTaskIndex, currentIndex + 1 < tasks.count {
            startTask(at: currentIndex + 1)
        } else {
            // No more tasks
            currentTaskIndex = nil
        }
        saveTasks()
    }
    
    func startTimer(for task: Task, onComplete: @escaping () -> Void) {
        let interval = task.endTime.timeIntervalSince(Date())
        guard interval > 0 else {
            onComplete()
            return
        }
        
        timerCancellable = Just(())
            .delay(for: .seconds(interval), scheduler: RunLoop.main)
            .sink { _ in
                onComplete()
            }
    }
    
    func initiateCurrentTaskTimer() {
        guard let task = currentTask else { return }
        
        startTimer(for: task) { [weak self] in
            self?.completeCurrentTask()
        }
    }
    
    func clearAllTasks() {
        tasks.removeAll()
        currentTaskIndex = nil
        timerCancellable?.cancel()
        saveTasks()
    }
}



struct AddTaskView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var endTime: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    TextField("Subtitle", text: $subtitle)
                    DatePicker("End Time", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Add Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            )
        }
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
        taskViewModel.addTask(title: trimmedTitle, subtitle: trimmedSubtitle, endTime: endTime)
        isPresented = false
    }
}

struct TasksView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        if let currentTask = taskViewModel.currentTask {
            WaterFillView(task: currentTask)
                .onAppear {
                    // Ensure the timer is running
                    taskViewModel.initiateCurrentTaskTimer()
                }
        } else {
            VStack {
                Text("No active task.")
                    .font(.title2)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding()
        }
    }
}


extension TaskViewModel {
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
    func deleteTasks(at offsets: IndexSet) {
        // Existing code...
        saveTasks()
    }
}
