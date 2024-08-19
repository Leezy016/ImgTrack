//
//  ContentView.swift
//  imgTrackSimple
//
//  Created by Rice on 2024/8/13.
//
import ARKit
import RealityKit
import AVFoundation
import SwiftUI

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    static var imgTracked = false
    var arView = ARView(frame: .zero)
    var player: AVAudioPlayer?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    mutating func playSound() {
        guard let url = Bundle.main.url(forResource: "drum_sound", withExtension: "mp3") else {
            print("can not find sound file")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = player else { return }
            // repeat until .stop
            player.numberOfLoops = -1
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private struct Resources {
        static let imgToTrack = "toy_drummer_img"
        static let musicToPlay = "drum_sound"
        static let modelToShow = "toy_drummer_idle.usdz"
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let imageAnchor = anchors[0] as? ARImageAnchor else {
                print("Problems loading anchor, time first")
                return
            }
            
            // Assigns reference image that will be tracked
            if let imageName = imageAnchor.name, imageName == Resources.imgToTrack {
                // get img position
                let anchor = AnchorEntity(world: imageAnchor.transform)
                // model face out of screen
                let rotationAngle = simd_quatf(angle: -90, axis: SIMD3(x: 1, y: 0, z: 0))
                anchor.setOrientation(rotationAngle, relativeTo: anchor)
                // place model at img position
                let entity = try! Entity.load(named: ARViewContainer.Resources.modelToShow)
                anchor.addChild(entity)
                parent.arView.scene.anchors.append(anchor)
                
                //play model animation
                if anchor.isActive{
                    for entity in anchor.children {
                        for animation in entity.availableAnimations {
                            entity.playAnimation(animation.repeat())
                        }
                    }
                }
                parent.playSound()
            }
        }
    }
    
    
    
    func makeUIView(context: Context) -> ARView {
        
        guard let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources", bundle: nil)
        else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Assigns coordinator to delegate the AR View
        arView.session.delegate = context.coordinator
        arView.automaticallyConfigureSession = false
        
        let configuration = ARImageTrackingConfiguration()
        configuration.isAutoFocusEnabled = false
        configuration.trackingImages = referenceImages
        // once tracked, stop
        configuration.maximumNumberOfTrackedImages = 0
        
        // Enables People Occulusion on supported iOS Devices
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            print("People Segmentation not enabled.")
        }
        
        arView.session.run(configuration)

        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
