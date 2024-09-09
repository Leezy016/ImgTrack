//
//  ContentView.swift
//  iTdragon
//
//  Created by Pete on 2024/9/9.
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
        guard let url = Bundle.main.url(forResource: Resources.soundToPlay, withExtension: "m4a") else {
            print("can not find sound file")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue)
            guard let player = player else { return }
            // repeat until .stop
            player.numberOfLoops = -1
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private struct Resources {
        static let imgToTrack = "DragonHead"
        static let soundToPlay = "DragonRoaring"
        static let modelToShow = "DragonFlyWithTexture.usdz"
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
                let imgAnchor = AnchorEntity(world: imageAnchor.transform)
                // move away to see clearly
                var translation = imgAnchor.transform.translation
                translation.z = translation.z - 3
                let modelAnchor = AnchorEntity(world: translation)
                // model face out of screen
                let rotationAngle = simd_quatf(angle: -90, axis: SIMD3(x: 1, y: 0, z: 0))
                modelAnchor.setOrientation(rotationAngle, relativeTo: imgAnchor)
                // place model at img position
                let entity = try! Entity.load(named: ARViewContainer.Resources.modelToShow)
                modelAnchor.addChild(entity)
                parent.arView.scene.anchors.append(modelAnchor)
                
                //play model animation
                if modelAnchor.isActive{
                    for entity in modelAnchor.children {
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
