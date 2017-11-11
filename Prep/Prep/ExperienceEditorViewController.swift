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


class ExperienceEditorViewController: UIViewController {
    var currentPanoramaIndex:Int = 0;
    var currentExperience:Experience? = nil
    var playerController = AVPlayerViewController()
    var avPlayer : AVPlayer?
    @IBOutlet weak var experience_viewer_panorama: NewCTPanoramaView!
    @IBAction func next_panorama(_ sender: UIBarButtonItem) {
        if(currentPanoramaIndex ==  (currentExperience?.panoramas.count)!-1){
            currentPanoramaIndex = 0
            loadImage()
            experience_viewer_panorama.addButtons()
        }
        else{
            currentPanoramaIndex += 1
            loadImage()
            experience_viewer_panorama.addButtons()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentPanoramaIndex = 0;
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
        if(isTouch) {
            experience_viewer_panorama.controlMethod = .touch
        } else {
            experience_viewer_panorama.controlMethod = .motion
        }
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


