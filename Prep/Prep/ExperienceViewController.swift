//
//  ViewController.swift
//  Prep
//
//  Created by Zavier Patrick David Aguila on 9/27/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import UIKit
//import CTPanoramaView

class ExperienceViewController: UIViewController {
    var currentPanoramaIndex:Int = 0;
    var currentExperience:Experience? = nil
    
    @IBOutlet public weak var experience_viewer_panorama: NewCTPanoramaView!
    @IBAction func next_panorama(_ sender: UIBarButtonItem) {
        if(currentPanoramaIndex ==  (currentExperience?.panoramas.count)!-1){
            currentPanoramaIndex = 0
        }
        else{
            currentPanoramaIndex += 1
        }
        loadImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentPanoramaIndex = 0;
        //currentExperience = initializeFirstExperience() we have to obtain the Experience from the Collection
        currentExperience = CurrentExperience
        loadImage()
        experience_viewer_panorama.initialize_tap()
        experience_viewer_panorama.addButtons()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //hardcoded Experience Initialization
   // func initializeFirstExperience() -> Experience{
    //    var initExperience: Experience
    //    initExperience = Experience(Name: "City Strolling", Description: "Visit the train Station and Park")
    //    initExperience.addPanorama(newImage: UIImage(named: "Experience2")!)
    //    initExperience.addPanorama(newImage: UIImage(named: "Experience9")!) //Train
    //    initExperience.addPanorama(newImage: UIImage(named: "Experience5")!) //Park
    //    initExperience.addPanorama(newImage: UIImage(named: "Experience4")!) //Shops
    //    return initExperience
    //}

    //loads Panorama Image with the current currentPanoramaIndex
    func loadImage() {
        experience_viewer_panorama.setButtonInfo(location:
            (currentExperience?.panoramas[currentPanoramaIndex].buttonLocation)!, action: (currentExperience?.panoramas[currentPanoramaIndex].buttonObject)!)
            
        experience_viewer_panorama.image = currentExperience?.getPanorama(index: currentPanoramaIndex)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

