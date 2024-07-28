//
//  ViewController.swift
//  ImgTrack
//
//  Created by Rice on 2024/7/27.
//

import UIKit
import ARKit
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
                
            }
        }
    }
    
}
