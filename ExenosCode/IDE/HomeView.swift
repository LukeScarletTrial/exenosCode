import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var showingCreateSheet = false
    @State private var newProjectName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.06)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if appModel.recentProjects.isEmpty {
                            emptyState
                        } else {
                            recentProjectsSection
                        }
                        
                        allProjectsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Exenos Code")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0, green: 0.94, blue: 1))
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                createProjectSheet
            }
            .alert("Alert", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to Exenos")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Create and run LuaZ projects on iPad")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.4))
            
            Text("No projects yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
            
            Text("Create your first project to get started")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
            
            Button(action: { showingCreateSheet = true }) {
                Text("Create Project")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0, green: 0.94, blue: 1))
                    .cornerRadius(8)
            }
        }
        .padding(40)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(16)
    }
    
    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Projects")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(appModel.recentProjects.prefix(4)) { project in
                    ProjectCard(project: project, appModel: appModel)
                }
            }
        }
    }
    
    private var allProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Projects")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(appModel.projects) { project in
                    ProjectCard(project: project, appModel: appModel)
                }
            }
        }
    }
    
    private var createProjectSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Project Name", text: $newProjectName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("New Project")
                } footer: {
                    Text("Enter a name for your new project")
                }
            }
            .navigationTitle("Create Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCreateSheet = false
                        newProjectName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(newProjectName.isEmpty)
                }
            }
        }
    }
    
    private func createProject() {
        guard !newProjectName.isEmpty else { return }
        
        if appModel.createProject(name: newProjectName) != nil {
            showingCreateSheet = false
            newProjectName = ""
        } else {
            alertMessage = "Failed to create project"
            showingAlert = true
        }
    }
}

struct ProjectCard: View {
    let project: Project
    @ObservedObject var appModel: AppModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: { appModel.openProject(project) }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0, green: 0.94, blue: 1))
                    
                    Spacer()
                    
                    Menu {
                        Button("Duplicate") {
                            _ = appModel.duplicateProject(project)
                        }
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                    }
                }
                
                Text(project.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Label("\(project.files.count) files", systemImage: "doc.text")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                    
                    Spacer()
                    
                    Text(relativeDate(project.modifiedAt))
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.12, green: 0.12, blue: 0.18))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                appModel.deleteProject(project)
            }
        } message: {
            Text("Are you sure you want to delete \(project.name)? This action cannot be undone.")
        }
    }
    
    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
