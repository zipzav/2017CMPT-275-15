//
//  EditorViewController.swift
//  Prep
//
//  Created by sychung on 11/10/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import UIKit

class PanoramaTableViewCell : UITableViewCell{
    var previewImage = UIImageView()
    
}
class PanoramaTableView : UITableView{
    convenience init(){
        self.init(frame:CGRect(x: 74, y: 232, width: 401, height: 482), style: UITableViewStyle.plain)
    }
}
class EditorStartPageViewController :UIViewController, UITableViewDataSource, UITableViewDelegate {
  //  @IBOutlet weak var panoramatableview: PanoramaTableView!
    @IBOutlet weak var experienceTitle: UILabel!
    @IBOutlet weak var experienceDescription: UILabel!
    var panoramatableview: PanoramaTableView!
    var currentExperience: Experience? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        currentExperience = arrayOfExperiences[0]
        experienceTitle.text = currentExperience?.getTitle()
        experienceDescription.text = currentExperience?.getDescription()
        experienceTitle.lineBreakMode = .byWordWrapping // notice the 'b' instead of 'B'
        experienceTitle.numberOfLines = 0
        experienceDescription.lineBreakMode = .byWordWrapping // notice the 'b' instead of 'B'
        experienceDescription.numberOfLines = 0
        
        panoramatableview = PanoramaTableView()
        panoramatableview.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        panoramatableview.dataSource = self
        panoramatableview.delegate = self
        panoramatableview.rowHeight = 150
        self.view.addSubview(panoramatableview)
        // Do any additional setup after loading the view.
    }



    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentExperience!.numPanorama()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cellIdentifier = "UITableViewCell"
        //let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UITableViewCell  else {
            fatalError("The dequeued cell is not an instance of PanoramaTableViewCell.")
        }
        let panorama = currentExperience?.panoramas[indexPath.row]
        cell.imageView?.image = panorama?.getImage()
        cell.imageView?.frame = CGRect(x: 0,y: 0,width: 401,height: 150)
        cell.imageView?.contentMode = UIViewContentMode.scaleToFill
        cell.imageView?.clipsToBounds = true
        return cell
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func trashButton(_ sender: UIButton) {
        //let childUpdates = ["/user/\(uid)" : nil] as [String : Any?] // set to nil deletes it from database
        //ref.updateChildValues(childUpdates)
        ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
        self.navigationController?.popViewController(animated: true)
    }
    
}
