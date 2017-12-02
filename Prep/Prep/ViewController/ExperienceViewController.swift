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
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabase

class ExperienceViewController: UIViewController {
    var currentPanoramaIndex:Int = 0;
    var currentExperience:Experience? = nil
    var playerController = AVPlayerViewController()
    var avPlayer : AVPlayer?
    @IBOutlet weak var experience_viewer_panorama: NewCTPanoramaView!
    @IBAction func next_panorama(_ sender: UIBarButtonItem) {
        if(currentPanoramaIndex ==  (currentExperience?.panoramas.count)!-1){//If the user is at the last panorama, send a congratulations
            let alert = UIAlertController(title: "Congratulations", message: "You have finished the experience. Congratulations", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                //self.performSegue(withIdentifier: "GoToHomePage", sender: self)
                let viewController = self.storyboard?.instantiateViewController(withIdentifier: "homepage")
                self.navigationController?.pushViewController(viewController!, animated: true)
                
            }))
            
            var topController = UIApplication.shared.keyWindow?.rootViewController
            while let presentedViewController = topController?.presentedViewController {
                topController = presentedViewController
            }
            topController?.present(alert, animated: true, completion: nil)
        }
        else{
            for flag in experience_viewer_panorama.buttonPressedFlag{
                if(flag == false){
                    let alert = UIAlertController(title: "Panorama unfinished", message: "There's still some triggers remaining.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                    }))
                    
                    var topController = UIApplication.shared.keyWindow?.rootViewController
                    while let presentedViewController = topController?.presentedViewController {
                        topController = presentedViewController
                    }
                    topController?.present(alert, animated: true, completion: nil)
                    return
                }
            }
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
        updateControlMethod(value)
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

