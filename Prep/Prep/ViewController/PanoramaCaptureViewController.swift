//
//  PanoramaCaptureViewController.swift
//  Prep
//
//  Created by Zavier Patrick David Aguila on 11/11/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CameraManager

class PanoramaCaptureViewController : UIViewController{
    let cameraManager = CameraManager()
    @IBOutlet weak var cameraview: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraManager.cameraOutputMode = .stillImage
        cameraManager.cameraDevice = .back
        cameraManager.cameraOutputQuality = .high
        cameraManager.flashMode = .off
        cameraManager.shouldEnableTapToFocus = true
        cameraManager.addPreviewLayerToView(self.cameraview)
        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    

}
