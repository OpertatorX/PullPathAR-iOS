import SwiftUI
import SwiftData

struct CableProfilesView: View {
    @Query(sort: \CableProfile.name) private var profiles: [CableProfile]
    @State private var showingCreate = false

    var body: some View {
        Group {
            if profiles.isEmpty {
                ContentUnavailableView(
                    "profiles.empty.title",
                    systemImage: "cable.connector",
                    description: Text("profiles.empty.message")
                )
            } else {
                List(profiles) { profile in
                    NavigationLink {
                        CableProfileEditorView(profile: profile)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.name)
                                .font(.headline)
                            Text(profile.category.localizedTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("profiles.title")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("profiles.create", systemImage: "plus") {
                    showingCreate = true
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateCableProfileView()
        }
    }
}

private struct CreateCableProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var category = CableCategory.cat6
    @State private var diameter = 0.0
    @State private var bendRadius = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("profiles.details") {
                    TextField("profiles.name", text: $name)
                    Picker("profiles.category", selection: $category) {
                        ForEach(CableCategory.allCases) { category in
                            Text(category.localizedTitle).tag(category)
                        }
                    }
                }
                Section("profiles.specs") {
                    TextField("profiles.diameter.mm", value: $diameter, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                    TextField("profiles.bend.mm", value: $bendRadius, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("profiles.new.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
                        modelContext.insert(
                            CableProfile(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                category: category,
                                diameterMillimeters: diameter,
                                minimumBendRadiusMillimeters: bendRadius
                            )
                        )
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct CableProfileEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: CableProfile

    var body: some View {
        Form {
            Section("profiles.details") {
                TextField("profiles.name", text: $profile.name)
                Picker("profiles.category", selection: $profile.categoryRaw) {
                    ForEach(CableCategory.allCases) { category in
                        Text(category.localizedTitle).tag(category.rawValue)
                    }
                }
            }
            Section("profiles.specs") {
                TextField("profiles.diameter.mm", value: $profile.diameterMillimeters, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                TextField("profiles.bend.mm", value: $profile.minimumBendRadiusMillimeters, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? modelContext.save() }
    }
}

extension CableCategory {
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .cat6: return "cable.category.cat6"
        case .cat6a: return "cable.category.cat6a"
        case .fiber: return "cable.category.fiber"
        case .coax: return "cable.category.coax"
        case .custom: return "cable.category.custom"
        }
    }
}
