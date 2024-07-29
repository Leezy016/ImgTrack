//
//  ViewController.swift
//  imgTrack
//
//  Created by Pete on 2024/7/29.
//

import UIKit
import ARKit
import AVKit
import RealityKit

class ViewController: UIViewController, ARSessionDelegate {
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Starting image tracking
        startImgTrackign()
        
        arView.session.delegate = self
    }
    
    func startImgTrackign() {
        guard let imgToTrack = ARReferenceImage.referenceImages(inGroupNamed:"Img", bundle:Bundle.main)else{
            print("Img not available, import one")
            return
        }
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = imgToTrack
        configuration.maximumNumberOfTrackedImages = 5
        
        //Start Session
        arView.session.run(configuration)
                
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imgAnchor = anchor as? ARImageAnchor{
                let width = Float(imgAnchor.referenceImage.physicalSize.width)
                let height = Float(imgAnchor.referenceImage.physicalSize.height)
                let videoScreen = createVideoScreen(width: width, height: height)
                
                placeVideoScreen(videoScreen: videoScreen, imgAnchor: imgAnchor)
            }
        }
    }
    
    
// MARK: - Object placement
    func placeVideoScreen(videoScreen: ModelEntity, imgAnchor: ARImageAnchor) {
        let imgAnchorEntity = AnchorEntity(anchor: imgAnchor)
        
        let rotationAngle = simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: SIMD3(x: 1, y: 0, z: 0))
        videoScreen.setOrientation(rotationAngle, relativeTo: imgAnchorEntity)
        
        let bookWidth = Float(imgAnchor.referenceImage.physicalSize.width)
        videoScreen.setPosition(SIMD3(x: bookWidth, y: 0, z: 0), relativeTo: imgAnchorEntity)
        
        imgAnchorEntity.addChild(videoScreen)
        
        // add anchor to scene
        arView.scene.addAnchor(imgAnchorEntity)
        
    }
    
// MARK: - VideoScreen
    
    func createVideoItem(with fileName:String) -> AVPlayerItem?{
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else
            { return nil }
        let asset = AVURLAsset(url:url)
        let videoItem = AVPlayerItem(asset: asset)
        return videoItem
    }
    
    func createVideoMaterial(videoItem: AVPlayerItem) -> VideoMaterial{
        let player = AVPlayer()
        let videoMaterial = VideoMaterial(avPlayer: player)
        player.replaceCurrentItem(with: videoItem)
        player.play()
        return videoMaterial
    }
    
    func createVideoScreen(width: Float, height: Float) -> ModelEntity {
        let screenMesh = MeshResource.generatePlane(width: width, depth: height)
        let videoItem = createVideoItem(with: "ReiIsLateForSchool")
        let videoMaterial = createVideoMaterial(videoItem: videoItem!)
        let videoScreenModel = ModelEntity(mesh: screenMesh, materials: [videoMaterial])
        return videoScreenModel
    }
    
    
    
}
