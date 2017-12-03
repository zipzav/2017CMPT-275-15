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

class ExperienceEditorViewController: UIViewController {
    @IBOutlet weak var experience_viewer_panorama: NewCTPanoramaView_Editor!
    
    @IBAction func Add_Sound(_ sender: Any) {
        experience_viewer_panorama.Add_Sound()
    }
    @IBAction func Add_Video(_ sender: Any) {
        experience_viewer_panorama.Add_Video()
    }
    var currentPanoramaIndex:Int = 0;
    var currentExperience:Experience? = nil
   
    
    @IBOutlet weak var add_Sound_button: UIButton!
    @IBOutlet weak var add_Video_button: UIButton!
    
    var playerController = AVPlayerViewController()
    var avPlayer : AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        add_Sound_button.backgroundColor = UIColor.PrepPurple
        add_Video_button.backgroundColor = UIColor.PrepPurple
        
        add_Sound_button.layer.cornerRadius = 5
        add_Sound_button.layer.borderWidth = 1
        add_Sound_button.layer.borderColor = UIColor.PrepPurple.cgColor
        
        add_Video_button.layer.cornerRadius = 5
        add_Video_button.layer.borderWidth = 1
        add_Video_button.layer.borderColor = UIColor.PrepPurple.cgColor
        
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


