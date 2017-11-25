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
import SceneKit

class PanoramaTableViewCell : UITableViewCell{
    var previewImage = UIImageView()
    
}
class PanoramaTableView : UITableView, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    convenience init(){
        self.init(frame:CGRect(x: 74, y: 232, width: 401, height: 482), style: UITableViewStyle.plain)
    }

}
var GlobalCurrentPanoramaIndex_Edit = 0
//var GlobalPanoramaSnapshots: Array<DataSnapshot> = []
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
        //Swipe left to delete//
        // During startup (-viewDidLoad or in storyboard) do:
        //self.panoramatableview.allowsMultipleSelectionDuringEditing = false;

        storageRef = Storage.storage().reference()
        
        if GlobalcurrentExperienceIndex != -1 {
            // Setup TextView when existing experience have been selected
            currentExperience = arrayOfExperiences[GlobalcurrentExperienceIndex]
            experienceTitle.text = currentExperience?.getTitle()
            experienceDescription.text = currentExperience?.getDescription()
            // Setup identifier 
            ExperienceID = GlobalCurrentExperienceID!
            PanoramaID = ref.child(ExperienceID).childByAutoId().key
        } else {
            // Create an object for New experience
            ExperienceID = ref.child(GlobalUserID!).childByAutoId().key
            currentExperience = Experience(Name: "", Description: "", Id: ExperienceID);
            // Disable save and trash button because we have not create a child node that is 
            // named after ExperienceID in database
            trashButtonOutlet.isEnabled = false 
            saveButtonOutlet.isEnabled = false
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
        
        // array will only be clear when scene is being initialized
        currentExperience?.panoramas.removeAll()
        
        // Create a Reference to particular child node in database
        experienceRef = ref.child("user").child(uid).child(ExperienceID)

        // Load Panoramas and listen for any new child node being added to database
        _refHandle = experienceRef.observe(.childAdded, with: { (snapshot) -> Void in
            
            // TODO: Perhaps use snapshot.children to improve loading speed
            let snapObject = snapshot.value as? [String: AnyObject]
            if let image = snapObject?["image"] {
                
                //GlobalPanoramaSnapshots.append(snapshot)
                
                // Convert Url to UIImage
                let url = URL(string:image as! String)
                if let data = try? Data(contentsOf: url!) {
                    self.currentExperience?.addPanorama(newImage: UIImage(data: data)!, Id:
                    snapshot.key)
                    if let buttons = snapObject?["button"]{
                        for button in buttons as! NSMutableArray{
                            let temp = button as! [String : AnyObject]
                            let x = temp["locationx"] as! Int
                            let y = temp["locationy"] as! Int
                            let z = temp["locationz"] as! Int
                            
                            let actionurl = temp["action"] as! String
                            if let data = try? Data(contentsOf: url!) {
                                self.currentExperience?.panoramas[(self.currentExperience?.panoramas.count)!-1].addButton(
                                    newButtonLocation: SCNVector3(x:Float(x),y:Float(y),z:Float(z)),
                                    newObject: actionurl)
                            }
                        }
                    }

                    // Reloads table view
                    self.panoramatableview.insertRows(at: [IndexPath(row: (self.currentExperience?.panoramas.count)!-1, section: 0)], with: UITableViewRowAnimation.automatic)
                }
            }
            GlobalExperienceSnapshots.append(snapshot)
        }, withCancel: nil)
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        experienceRef.removeAllObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return currentExperience!.numPanorama()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cellIdentifier = "UITableViewCell"
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: Go to ExperienceEditor
        GlobalCurrentPanoramaIndex_Edit = indexPath.row
        self.performSegue(withIdentifier: "EditorStarttoEditor", sender: self)
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            
            let alert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this Panorama?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete action"), style: .`default`, handler: { _ in
                if GlobalcurrentExperienceIndex != -1 {
                    ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).child((self.currentExperience?.panoramas[indexPath.row].key)!).removeValue()
                } else {
                    ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).child((self.currentExperience?.panoramas[indexPath.row].key)!).removeValue()
                }
                //GlobalExperienceSnapshots.remove(at: indexPath!.row)
                self.currentExperience?.panoramas.remove(at: indexPath.row)
                DispatchQueue.main.async(execute: {
                    self.panoramatableview.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                })
            }
            ))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Canel", comment: "Cancel action"), style: .`default`, handler: { _ in
                //do nothing
            }))
            var topController = UIApplication.shared.keyWindow?.rootViewController
            while let presentedViewController = topController?.presentedViewController {
                topController = presentedViewController
            }
            topController?.present(alert, animated: true, completion: nil)
        }
    }
    @IBAction func trashButton(_ sender: UIButton) {
        // Remove child node and its subfields from database
        if GlobalcurrentExperienceIndex != -1 {
            ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
        } else {
            ref.child("user").child(GlobalUserID!).child(ExperienceID).removeValue()
        }
        self.performSegue(withIdentifier: "EditorStartPageToHomePage", sender: self)
    }
    
    @IBAction func saveAndUploadButton(_ sender: UIButton) {
        if let uid = Auth.auth().currentUser?.uid {
            // Note that the node that is named after the ExperienceID already contain all
            // the panorama uploaded to storage and database
            let name = experienceTitle.text
            let description = experienceDescription.text

            let object = ["name": name ?? "default name",
                          "description": description ?? "default description"
                ]
            // Store name and description
            ref.child("user/\(uid)/\(ExperienceID)").updateChildValues(object)
            self.performSegue(withIdentifier: "EditorStartPageToHomePage", sender: self)
        }
    }
    
    // MARK: - Image Picker
    
    @IBAction func didTapTakPicture(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        
        // Configure ImagePickerController
        picker.sourceType = .photoLibrary // Assume photo sphere is stiched up by another app so didn't use .camera
        picker.delegate = self
        picker.allowsEditing = false
        picker.modalPresentationStyle = .overCurrentContext // keep the screen in landscape mode
        present(picker, animated: true, completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        
        urlTextView.text = "Beginning Upload" // TODO: Use UI Framework to notify user about the upload status
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
                    self?.uploadSuccess(fileURL!)
                })
            }
    }
    
    func uploadSuccess(_ fileURL: URL) {
        if let uid = Auth.auth().currentUser?.uid {
             // Photo uploaded to firebase storage, nowa add image URL to realtime database
            print("Upload Succeeded!")
            
            // Generate a unique ID for the panorama object and store it to realtime database
            PanoramaID = ref.child(ExperienceID).childByAutoId().key
            ref.child("user/\(uid)/\(ExperienceID)").child(PanoramaID).setValue(["image":"\(fileURL.absoluteString)"])
            
            // Enable save and trash button because a child node that is named after ExperienceID have been
            // added to the database so there is stuff the delete
            // for the same reason, back button must be disabled
            trashButtonOutlet.isEnabled = true
            saveButtonOutlet.isEnabled = true
            self.navigationItem.setHidesBackButton(true, animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with: UIEvent?){
        // Hide keyboard when user tap screen
        experienceTitle.resignFirstResponder()
        experienceDescription.resignFirstResponder()
        
    }
    
    
    
}

