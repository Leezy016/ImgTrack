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
            }
        }
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
