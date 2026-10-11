import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct RoutePhotosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PhotoNote.createdAt, order: .reverse) private var allPhotos: [PhotoNote]
    let route: CableRoute
    @State private var selectedItem: PhotosPickerItem?

    private var photos: [PhotoNote] {
        allPhotos.filter { $0.routeID == route.id }
    }

    var body: some View {
        Group {
            if photos.isEmpty {
                ContentUnavailableView(
                    "photos.empty.title",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("photos.empty.message")
                )
            } else {
                List {
                    ForEach(photos) { photo in
                        PhotoNoteRow(photo: photo)
                    }
                    .onDelete(perform: deletePhotos)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("photos.title")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("photos.add", systemImage: "plus")
                }
                .accessibilityHint("photos.add.hint")
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { @MainActor in
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                let photo = PhotoNote(routeID: route.id, imageData: data)
                modelContext.insert(photo)
                modelContext.insert(
                    HistoryEntry(
                        routeID: route.id,
                        kind: .photoAdded,
                        detail: String(localized: "photos.history.added")
                    )
                )
                route.updatedAt = .now
                try? modelContext.save()
                selectedItem = nil
            }
        }
    }

    private func deletePhotos(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(photos[index])
        }
        route.updatedAt = .now
        try? modelContext.save()
    }
}

private struct PhotoNoteRow: View {
    @Bindable var photo: PhotoNote

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
                .frame(width: 74, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                TextField("photos.caption", text: $photo.caption, axis: .vertical)
                    .lineLimit(1...4)
                Text(photo.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = photo.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .accessibilityLabel(photo.caption.isEmpty ? "photos.image" : photo.caption)
        } else {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("photos.image.unavailable")
        }
    }
}
