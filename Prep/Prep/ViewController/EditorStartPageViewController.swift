//
//  EditorViewController.swift
//  Prep
//
//  Created by sychung on 11/10/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import UIKit
import Photos
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabase

class PanoramaTableViewCell : UITableViewCell{
    var previewImage = UIImageView()
    
}
class PanoramaTableView : UITableView, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    convenience init(){
        self.init(frame:CGRect(x: 74, y: 232, width: 401, height: 482), style: UITableViewStyle.plain)
    }
}

var GlobalPanoramaSnapshots: Array<DataSnapshot> = []

class EditorStartPageViewController :UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
  //  @IBOutlet weak var panoramatableview: PanoramaTableView!
    var panoramatableview: PanoramaTableView!
    var currentExperience: Experience? = nil
    
    @IBOutlet weak var experienceTitle: UITextField!
    
    
    @IBOutlet weak var experienceDescription: UITextView!
    
    @IBOutlet weak var trashButtonOutlet: UIButton!
    @IBOutlet weak var saveButtonOutlet: UIButton!
    
    @IBOutlet weak var urlTextView: UITextField!
    // Create a storage reference from our storage service
    var storageRef: StorageReference!
    
    // Database
    var _refHandle: DatabaseHandle!
    var experienceRef : DatabaseReference!
    
    var ExperienceID = ""
    var PanoramaID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // configure storage
        storageRef = Storage.storage().reference()
        
        // Setup TextView
        if GlobalcurrentExperienceIndex != -1 {
            // Setup textfield when user selects existing experience
            currentExperience = arrayOfExperiences[GlobalcurrentExperienceIndex]
            experienceTitle.text = currentExperience?.getTitle()
            experienceDescription.text = currentExperience?.getDescription()
            ExperienceID = GlobalCurrentExperienceID!
            PanoramaID = ref.child(ExperienceID).childByAutoId().key
        } else {
            // new experience
            trashButtonOutlet.isEnabled = false
            ExperienceID = ref.child(GlobalUserID!).childByAutoId().key
            currentExperience = Experience(Name: "", Description: "", Id: ExperienceID);
        }

        fetchPanoramas()
        
        // Setup table view
        panoramatableview = PanoramaTableView()
        panoramatableview.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        panoramatableview.dataSource = self
        panoramatableview.delegate = self
        panoramatableview.rowHeight = 150
        self.view.addSubview(panoramatableview)
        
        // Configuring the TextView
        //experienceTitle.backgroundColor = UIColor.PrepPurple
        experienceTitle.attributedPlaceholder = NSAttributedString(string:"Experience needs a title", attributes: [NSAttributedStringKey.foregroundColor: UIColor.black])
        experienceDescription.isEditable = true
        experienceDescription.backgroundColor = UIColor.lightGray
        
        // Configuring the Button
        trashButtonOutlet.tintColor = UIColor.white
        trashButtonOutlet.backgroundColor = UIColor.PrepPurple
        saveButtonOutlet.tintColor = UIColor.white
        saveButtonOutlet.backgroundColor = UIColor.PrepPurple
        trashButtonOutlet.layer.cornerRadius = 10
        trashButtonOutlet.clipsToBounds = true
        saveButtonOutlet.layer.cornerRadius = 10
        saveButtonOutlet.clipsToBounds = true
        
    }
    
    func fetchPanoramas() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("user is not logged in")
            return
        }
        
//        guard GlobalcurrentExperienceIndex == -1 else {
//            return
//        }
        experienceRef = ref.child("user").child(uid).child(ExperienceID)

        _refHandle = experienceRef.observe(.childAdded, with: { (snapshot) -> Void in
            
            // TODO: Perhaps use snapshot.children to improve loading speed
                
            let snapObject = snapshot.value as? [String: AnyObject]
            if let image = snapObject?["image"] {
                
                GlobalPanoramaSnapshots.append(snapshot)
                
                // Convert Url to UIImage
                let url = URL(string:image as! String)
                if let data = try? Data(contentsOf: url!) {
                    self.currentExperience?.addPanorama(newImage: UIImage(data: data)!)
                    //arrayOfExperiences += [self.currentExperience!]
                    
                    print("New count for arrayOfExperiences \(arrayOfExperiences.count)")
                    
                    if let sec = self.panoramatableview?.numberOfSections {
                        print("panoramatableview: num of sec \(sec) ")
                        let cell = self.panoramatableview.numberOfRows(inSection: 0)
                        print("panoramatableview: num of cell \(cell)")
                        
                    }
                    let num = self.currentExperience?.numPanorama()
                    print("currentExperience has pan : \(num)")
                    DispatchQueue.main.async(execute: {
                        // Reloads table view
                        self.panoramatableview.insertRows(at: [IndexPath(row: (self.currentExperience?.panoramas.count)!-1, section: 0)], with: UITableViewRowAnimation.automatic)
                    })
                }
            }
        }, withCancel: nil)
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if let refHandle = _refHandle {
//            ref.child("user").child((Auth.auth().currentUser?.uid)!).removeObserver(withHandle: refHandle)
//        }
        experienceRef.removeAllObservers()
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
    
    @IBAction func trashButton(_ sender: UIButton) {
        
        if GlobalcurrentExperienceIndex != -1 {
            ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
        } else {
            ref.child("user").child(GlobalUserID!).child(ExperienceID).removeValue()
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveAndUploadButton(_ sender: UIButton) {
        if let uid = Auth.auth().currentUser?.uid {
            // Store experience object along with image to database
            let name = experienceTitle.text
            let description = experienceDescription.text

            let object = ["name": name ?? "default name",
                          "description": description ?? "default description"
                ]
            //ref.child("user").child(uid).child(ExperienceID).child(PanoramaID).setValue(["image":fileURL])
            ref.child("user/\(uid)/\(ExperienceID)").updateChildValues(object)
            self.performSegue(withIdentifier: "SaveAndGoToHomePage", sender: self)
        }
    }
    
    // MARK: - Image Picker
    
    @IBAction func didTapTakPicture(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary // Assume photo sphere is stiched up by another app
        picker.delegate = self
        picker.allowsEditing = false
        picker.modalPresentationStyle = .overCurrentContext // keep the screen in landscape mode
        present(picker, animated: true, completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        
        urlTextView.text = "Beginning Upload"
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
            {
                var imageUploadManager = UploadManager()
                imageUploadManager.uploadImage(image, progressBlock: { (percentage) in
                    print(percentage)
                }, completionBlock: { [weak self] (fileURL, errorMessage) in
                    guard let strongself = self else {return}
                    // Handle Error
                    if let error = errorMessage {
                        print("Error uploading: \(error)")
                        //self.urlTextView.text = "Upload Failed"
                        return
                    }
                    // Handle fileURL by real time database
                    print("file URL is \(fileURL?.absoluteString)")
                    self?.uploadSuccess(fileURL!)
                })
            }
//        }
    }
    
    func uploadSuccess(_ fileURL: URL) {
        if let uid = Auth.auth().currentUser?.uid {
            print("Upload Succeeded!")
            trashButtonOutlet.isEnabled = true
            // Generate a unique ID for the panorama object and store it to realtime database
            PanoramaID = ref.child(ExperienceID).childByAutoId().key
            ref.child("user/\(uid)/\(ExperienceID)").child(PanoramaID).setValue(["image":"\(fileURL.absoluteString)"])
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with: UIEvent?){
        experienceTitle.resignFirstResponder()
        experienceDescription.resignFirstResponder()
    }
    
}

