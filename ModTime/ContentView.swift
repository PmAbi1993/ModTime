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
}

struct ContentView: View {
    @State private var selectedTab: Tabs = .tasks
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    Home()
                        .navigationTitle("Home")
                }
            }
            Tab("Tasks", systemImage: "plus.square.dashed", value: .tasks) {
                NavigationStack {
                    WaterFillView(startTime: .now, endTime: .now + 15)
                        .navigationTitle("Tasks")
                }
            }
            Tab("Settings", systemImage: "gear", value: .settings) {
                NavigationStack {
                    Settings()
                        .navigationTitle("Settings")
                }
            }
        }
    }
}

struct Home: View {
    var body: some View {
        Text("Hello, World!")
    }
}

struct Settings: View {
    var body: some View {
        Form {
            Section("Profile") {
                Text("Profile")
            }
            Section("Dude") {
                Text("Clear all tasks")
                Text("Logout")
            }
        }
    }
}


struct WaterFillView: View {
    var startTime: Date
    var endTime: Date
    @State private var percentage: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .center) {
                    Text("Task")
                        .font(.largeTitle)
                    Text("SubTitle")
                    
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                ZStack(alignment: .bottom) {
                    // Task info
                    // Glass container
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.blue, lineWidth: 0)
                        .frame(width: geometry.size.width, height: geometry.size.height)

                    // Water fill with top rounded corners
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: geometry.size.width, height: CGFloat(geometry.size.height * (percentage / 100)))
                        .clipShape(CustomTopRoundedShape(cornerRadius: 15)) // Apply custom corner radius
                        .animation(.easeInOut(duration: 1.0))
                }
            }
            .onAppear {
                startFilling()
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startFilling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let totalTime = endTime.timeIntervalSince(startTime)
            let currentTime = Date().timeIntervalSince(startTime)

            if currentTime >= 0 {
                let progress = (currentTime / totalTime) * 100
                self.percentage = min(progress, 100)
            }

            if self.percentage >= 100 {
                timer.invalidate()
            }
        }
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
