import SwiftUI
import UniformTypeIdentifiers

struct AssetImportView: View {
    let project: Project
    @Environment(\.dismiss) var dismiss
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var importing = false
    @State private var importMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0, green: 0.94, blue: 1))
                    
                    Text("Import Assets")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Add images and audio files to your project")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    Button(action: { showingFilePicker = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "doc")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                            
                            Text("Choose File")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.18))
                        .cornerRadius(12)
                    }
                    
                    if let url = selectedFileURL {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 0, green: 0.94, blue: 1))
                            
                            Text(url.lastPathComponent)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                if let url = selectedFileURL {
                    Button(action: importAsset) {
                        Text("Import")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(importing ? Color(red: 0.3, green: 0.3, blue: 0.4) : Color(red: 0, green: 0.94, blue: 1))
                            .cornerRadius(12)
                    }
                    .disabled(importing)
                }
            }
            .padding(20)
            .background(Color(red: 0.04, green: 0.04, blue: 0.06))
            .navigationTitle("Import Assets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.image, .audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        selectedFileURL = url
                    }
                case .failure:
                    break
                }
            }
            .alert("Import", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importMessage)
            }
        }
    }
    
    private func importAsset() {
        guard let url = selectedFileURL else { return }
        
        importing = true
        
        Task {
            let projectStore = ProjectStore()
            
            if let asset = projectStore.importAsset(from: url, to: project, as: nil) {
                await MainActor.run {
                    importMessage = "Successfully imported \(asset.name)"
                    showingAlert = true
                    selectedFileURL = nil
                    importing = false
                }
            } else {
                await MainActor.run {
                    importMessage = "Failed to import asset"
                    showingAlert = true
                    importing = false
                }
            }
        }
    }
}
