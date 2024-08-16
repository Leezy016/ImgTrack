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
    static var isTracking = false
    var arView = ARView(frame: .zero)
    var player: AVAudioPlayer?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    mutating func playSound(isTracking:Bool) {
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
            if isTracking{
                player.play()
                print("play sound")
            } else {
                player.stop()
                print("stop sound")
            }

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private struct Resources {
        static let imgToTrack = "toy_drummer_img"
        static let videoToPlay = "ReiLateForSchool"
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
            
            
            // Assigns reference image that will be detected
            if let imageName = imageAnchor.name, imageName == Resources.imgToTrack {
                let anchor = AnchorEntity(anchor: imageAnchor)
                // Adds model to the anchor
                parent.arView.scene.addAnchor(anchor)
                anchor.position = [0, 0, -0.5]
            }
            
            
            // Add model to anchor
            let entity = try! Entity.load(named: ARViewContainer.Resources.modelToShow)
            let anchor = AnchorEntity()
            anchor.addChild(entity)
            anchor.position = [0, 0, -0.5]
            parent.arView.scene.anchors.append(anchor)
            
        }
        
        // Checks for tracking status
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let imageAnchor = anchors[0] as? ARImageAnchor else {
                print("Problems loading anchor, time second")
                return
            }
            
            // Plays/pauses the model animation when tracked/loses tracking
            if imageAnchor.isTracked {
                for entity in parent.arView.scene.anchors[1].children {
                    for animation in entity.availableAnimations {
                        entity.playAnimation(animation.repeat())
                    }
                }
                ARViewContainer.isTracking = true
            } else {
                ARViewContainer.isTracking = false
            }
            parent.playSound(isTracking: !ARViewContainer.isTracking)
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
        
        let configuration = ARImageTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
        
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

