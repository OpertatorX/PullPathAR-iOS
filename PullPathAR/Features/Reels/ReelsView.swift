import SwiftUI
import SwiftData

struct ReelsView: View {
    @Query(sort: \CableReel.updatedAt, order: .reverse) private var reels: [CableReel]
    @Query private var profiles: [CableProfile]
    @AppStorage("preferredUnitSystem") private var preferredUnitSystemRaw = UnitSystem.metric.rawValue
    @State private var showingCreateReel = false
    @State private var includeArchived = false

    private var preferredUnitSystem: UnitSystem {
        UnitSystem(rawValue: preferredUnitSystemRaw) ?? .metric
    }

    private var visibleReels: [CableReel] {
        includeArchived ? reels : reels.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleReels.isEmpty {
                    ContentUnavailableView(
                        "reels.empty.title",
                        systemImage: "circle.dotted",
                        description: Text("reels.empty.message")
                    )
                } else {
                    List(visibleReels) { reel in
                        NavigationLink {
                            ReelEditorView(reel: reel)
                        } label: {
                            ReelRow(
                                reel: reel,
                                profileName: profiles.first(where: { $0.id == reel.profileID })?.name,
                                unitSystem: preferredUnitSystem
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("tab.reels")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Toggle("reels.show.archived", isOn: $includeArchived)
                        NavigationLink("profiles.manage") {
                            CableProfilesView()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("common.more")

                    Button("reels.create", systemImage: "plus") {
                        showingCreateReel = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateReel) {
                CreateReelView()
            }
        }
    }
}

private struct ReelRow: View {
    let reel: CableReel
    let profileName: String?
    let unitSystem: UnitSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(reel.name)
                    .font(.headline)
                Spacer()
                if !reel.isActive {
                    Image(systemName: "archivebox")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("reel.archived")
                }
            }

            if let profileName, !profileName.isEmpty {
                Text(profileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("reels.remaining")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(RouteMath.formattedLength(meters: reel.remainingLengthMeters, unitSystem: unitSystem))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }

            ProgressView(
                value: reel.initialLengthMeters == 0 ? 0 : reel.remainingLengthMeters,
                total: max(reel.initialLengthMeters, 0.001)
            )
            .accessibilityLabel("reels.remaining")
        }
        .padding(.vertical, 5)
    }
}

private struct CreateReelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CableProfile.name) private var profiles: [CableProfile]
    @State private var name = ""
    @State private var profileID: UUID?
    @State private var lengthMeters = 305.0
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("reels.new.details") {
                    TextField("reels.name", text: $name)
                    Picker("profiles.profile", selection: $profileID) {
                        Text("profiles.none").tag(nil as UUID?)
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(Optional(profile.id))
                        }
                    }
                    TextField("reels.length.meters", value: $lengthMeters, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                }

                Section("common.notes") {
                    TextField("common.notes.optional", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("reels.new.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
                        let reel = CableReel(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            profileID: profileID,
                            initialLengthMeters: max(0, lengthMeters),
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        modelContext.insert(reel)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || lengthMeters <= 0)
                }
            }
        }
    }
}

private struct ReelEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var reel: CableReel
    @Query(sort: \CableProfile.name) private var profiles: [CableProfile]

    var body: some View {
        Form {
            Section("reels.edit.details") {
                TextField("reels.name", text: $reel.name)
                Picker("profiles.profile", selection: $reel.profileID) {
                    Text("profiles.none").tag(nil as UUID?)
                    ForEach(profiles) { profile in
                        Text(profile.name).tag(Optional(profile.id))
                    }
                }
            }

            Section("reels.edit.length") {
                LabeledContent("reels.initial") {
                    TextField("reels.initial", value: $reel.initialLengthMeters, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("reels.remaining") {
                    TextField("reels.remaining", value: $reel.remainingLengthMeters, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("common.notes") {
                TextField("common.notes.optional", text: $reel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Toggle("reels.active", isOn: $reel.isActive)
            }
        }
        .navigationTitle(reel.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: reel.initialLengthMeters) { _, newValue in
            reel.initialLengthMeters = max(0, newValue)
            reel.remainingLengthMeters = min(max(0, reel.remainingLengthMeters), reel.initialLengthMeters)
            reel.updatedAt = .now
        }
        .onChange(of: reel.remainingLengthMeters) { _, newValue in
            reel.remainingLengthMeters = min(max(0, newValue), max(0, reel.initialLengthMeters))
            reel.updatedAt = .now
        }
        .onDisappear {
            reel.updatedAt = .now
            try? modelContext.save()
        }
    }
}
