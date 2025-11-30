//
//  ARFaceTrackingView.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import SwiftUI
import ARKit
import SceneKit

/// SwiftUI wrapper for ARSCNView with face tracking
struct ARFaceTrackingView: UIViewRepresentable {

    let detector: ARFaceDetector
    let showDebugOverlay: Bool

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)

        // Configure scene view
        sceneView.session = detector.session
        sceneView.automaticallyUpdatesLighting = true

        // Show statistics if debug mode
        if showDebugOverlay {
            sceneView.showsStatistics = true
        }

        // Optional: Add face mesh (commented out for cleaner look)
        // sceneView.scene.rootNode.addChildNode(createFaceMeshNode())

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Updates handled by detector
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: ()) {
        uiView.session.pause()
    }

    // MARK: - Optional Face Mesh

    private func createFaceMeshNode() -> SCNNode {
        let node = SCNNode()
        node.geometry = ARSCNFaceGeometry(device: MTLCreateSystemDefaultDevice()!)
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 0.5
        return node
    }
}
