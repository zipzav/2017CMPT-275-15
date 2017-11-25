//  File: ExperienceViewController.swift
//  Team Name: Invincible
//  Developers:
//      Zavier Aguila
//      John Ko
//      Gary Chung
//  Known Bugs:
//  Prep
//
//  Created by Zavier Patrick David Aguila on 9/27/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.

import UIKit
import AVFoundation
import AVKit
import SceneKit

func round(val: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: round(val.x), y: round(val.y), z: round(val.z))
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}

func * (left: SCNVector3, right: SCNVector3) -> CGFloat {
    return CGFloat(left.x * right.x + left.y * right.y + left.z * right.z)
}


func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3(x: left.x * right, y: left.y * right, z: left.z * right)
}

func * (left: Float, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left * right.x, y: left * right.y, z: left * right.z)
}

class ExperienceEditorViewController: UIViewController {
    @IBOutlet weak var experience_viewer_panorama: NewCTPanoramaView!
    var currentPanoramaIndex:Int = 0;
    var currentExperience:Experience? = nil
    var playerController = AVPlayerViewController()
    var avPlayer : AVPlayer?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentPanoramaIndex = GlobalCurrentPanoramaIndex_Edit;
        //currentExperience = initializeFirstExperience() we have to obtain the Experience from the Collection
        currentExperience = GlobalCurrentExperience
        loadImage()
        if(experience_viewer_panorama != nil){
            experience_viewer_panorama.initialize_tap()
            experience_viewer_panorama.addButtons()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        let value = UserDefaults.standard.bool(forKey: "lButtonSelected")
        updateControlMethod(true) //always touch
    }
    
    func updateControlMethod(_ isTouch: Bool) {
        //Editor is always through touch
            experience_viewer_panorama.controlMethod = .touch
    }
    
    //loads Panorama Image with the current currentPanoramaIndex, also sets the button locations and object
    func loadImage() {
        if(experience_viewer_panorama != nil){
            experience_viewer_panorama.setButtonInfo(location:
                (currentExperience?.panoramas[currentPanoramaIndex].buttonLocation)!, action: (currentExperience?.panoramas[currentPanoramaIndex].buttonObject)!)
            
            experience_viewer_panorama.image = currentExperience?.getPanorama(index: currentPanoramaIndex)
            experience_viewer_panorama.nextbuttonLocations = (currentExperience?.panoramas[currentPanoramaIndex].nextPanoramaButtonLocation)!
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}


