//
//  ViewController.swift
//  Prep
//
//  Created by Zavier Patrick David Aguila on 9/27/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import UIKit
import CTPanoramaView

class ViewController: UIViewController {
    
    @IBOutlet weak var experience_viewer_panorama: CTPanoramaView!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCylindricalImage()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadCylindricalImage() {
        experience_viewer_panorama.image = UIImage(named: "Experience1")
    }
}

