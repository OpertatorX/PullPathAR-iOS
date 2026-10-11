import SwiftUI
import SwiftData
import ARKit
import RealityKit
import UIKit
import simd

struct ARRouteCaptureView: UIViewRepresentable {
    let points: [RouteVector3]
    let onPointPlaced: (RouteVector3) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.render(points: points, in: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.render(points: points, in: uiView)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject {
        var parent: ARRouteCaptureView
        private var renderedPoints: [RouteVector3] = []

        init(parent: ARRouteCaptureView) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let location = recognizer.location(in: arView)
            guard let result = arView.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .any
            ).first else {
                return
            }

            let translation = result.worldTransform.columns.3
            let point = RouteVector3(
                x: Double(translation.x),
                y: Double(translation.y),
                z: Double(translation.z)
            )
            parent.onPointPlaced(point)
        }

        func render(points: [RouteVector3], in arView: ARView) {
            guard points != renderedPoints else { return }
            renderedPoints = points
            arView.scene.anchors.removeAll()

            let pointMaterial = SimpleMaterial(color: .systemTeal, isMetallic: false)
            let lineMaterial = SimpleMaterial(color: .systemTeal.withAlphaComponent(0.9), isMetallic: false)

            for point in points {
                let position = SIMD3<Float>(Float(point.x), Float(point.y), Float(point.z))
                let anchor = AnchorEntity(world: position)
                let marker = ModelEntity(
                    mesh: .generateSphere(radius: 0.028),
                    materials: [pointMaterial]
                )
                anchor.addChild(marker)
                arView.scene.addAnchor(anchor)
            }

            guard points.count > 1 else { return }
            for (start, end) in zip(points, points.dropFirst()) {
                addSegment(from: start, to: end, material: lineMaterial, in: arView)
            }
        }

        private func addSegment(
            from start: RouteVector3,
            to end: RouteVector3,
            material: SimpleMaterial,
            in arView: ARView
        ) {
            let a = SIMD3<Float>(Float(start.x), Float(start.y), Float(start.z))
            let b = SIMD3<Float>(Float(end.x), Float(end.y), Float(end.z))
            let delta = b - a
            let length = simd_length(delta)
            guard length > 0.000_1 else { return }

            let midpoint = (a + b) / 2
            let anchor = AnchorEntity(world: midpoint)
            let segment = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(0.012, length, 0.012)),
                materials: [material]
            )
            segment.orientation = simd_quatf(
                from: SIMD3<Float>(0, 1, 0),
                to: simd_normalize(delta)
            )
            anchor.addChild(segment)
            arView.scene.addAnchor(anchor)
        }
    }
}

struct ARCaptureScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoutePoint.orderIndex) private var allPoints: [RoutePoint]
    let route: CableRoute
    @State private var confirmingClear = false

    private var routePoints: [RoutePoint] {
        allPoints.filter { $0.routeID == route.id }.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var vectors: [RouteVector3] {
        RouteMath.vectors(from: routePoints)
    }

    private var totalMeters: Double {
        RouteMath.totalLength(points: vectors)
    }

    var body: some View {
        ZStack {
            ARRouteCaptureView(points: vectors, onPointPlaced: addPoint)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("capture.ar.title")
                            .font(.headline)
                        Text("capture.ar.instruction")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(RouteMath.formattedLength(meters: totalMeters, unitSystem: route.unitSystem))
                            .font(.title3.monospacedDigit().weight(.bold))
                        Text("\(String(localized: "capture.points.label")): \(routePoints.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding()

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        undoLastPoint()
                    } label: {
                        Label("common.undo", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.bordered)
                    .disabled(routePoints.isEmpty)

                    Button(role: .destructive) {
                        confirmingClear = true
                    } label: {
                        Label("common.clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(routePoints.isEmpty)

                    Spacer()

                    Button {
                        recordMeasurementHistory()
                        dismiss()
                    } label: {
                        Label("common.done", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(14)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("capture.clear.confirm", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("common.clear", role: .destructive) { clearPoints() }
            Button("common.cancel", role: .cancel) { }
        }
    }

    private func addPoint(_ vector: RouteVector3) {
        let nextIndex = (routePoints.map(\.orderIndex).max() ?? -1) + 1
        let point = RoutePoint(
            routeID: route.id,
            orderIndex: nextIndex,
            xMeters: vector.x,
            yMeters: vector.y,
            zMeters: vector.z,
            source: .augmentedReality,
            label: "P\(nextIndex + 1)"
        )
        modelContext.insert(point)
        route.updatedAt = .now
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    private func undoLastPoint() {
        guard let last = routePoints.last else { return }
        modelContext.delete(last)
        route.updatedAt = .now
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func clearPoints() {
        routePoints.forEach { modelContext.delete($0) }
        route.updatedAt = .now
        try? modelContext.save()
    }

    private func recordMeasurementHistory() {
        modelContext.insert(
            HistoryEntry(
                routeID: route.id,
                kind: .measured,
                detail: RouteMath.formattedLength(meters: totalMeters, unitSystem: route.unitSystem)
            )
        )
        route.updatedAt = .now
        try? modelContext.save()
    }
}
