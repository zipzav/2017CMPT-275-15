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

class PanoramaTableViewCell : UITableViewCell{
    var previewImage = UIImageView()
    
}
class PanoramaTableView : UITableView, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    convenience init(){
        self.init(frame:CGRect(x: 74, y: 232, width: 401, height: 482), style: UITableViewStyle.plain)
    }
}



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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // configure storage
        storageRef = Storage.storage().reference()
        
        // Setup TextView
        currentExperience = arrayOfExperiences[GlobalcurrentExperienceIndex]
        experienceTitle.text = currentExperience?.getTitle()
        experienceDescription.text = currentExperience?.getDescription()
        
//        experienceTitle.lineBreakMode = .byWordWrapping // notice the 'b' instead of 'B'
//        experienceTitle.numberOfLines = 0
//        experienceDescription.lineBreakMode = .byWordWrapping // notice the 'b' instead of 'B'
//        experienceDescription.numberOfLines = 0
        
        
        // Setup table view
        panoramatableview = PanoramaTableView()
        panoramatableview.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        panoramatableview.dataSource = self
        panoramatableview.delegate = self
        panoramatableview.rowHeight = 150
        self.view.addSubview(panoramatableview)
        
        // Configuring the TextView
        //experienceTitle.backgroundColor = UIColor.PrepPurple
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
    
    // MARK: - Image Picker
    
    @IBAction func didTapTakPicture(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        
        //if UIImagePickerController.isSourceTypeAvailable(.camera) {
        //    picker.sourceType = .camera
        //} else {
            picker.sourceType = .photoLibrary // Assume photo sphere is stiched up by another app
        //}
        
        picker.delegate = self
        picker.modalPresentationStyle = .overCurrentContext // keep the screen in landscape mode
        present(picker, animated: true, completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        
        urlTextView.text = "Beginning Upload"
        // if it's a photo from the library, not an image from the camera
        if #available(iOS 8.0, *), let referenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl], options: nil)
            let asset = assets.firstObject
            asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                let imageFile = contentEditingInput?.fullSizeImageURL
                let filePath = GlobalUserID! +
                "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(imageFile!.lastPathComponent)"
                // [START uploadimage]
                self.storageRef.child(filePath)
                    .putFile(from: imageFile!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading: \(error)")
                            self.urlTextView.text = "Upload Failed"
                            return
                        }
                        self.uploadSuccess(metadata!, storagePath: filePath)
                }
                // [END uploadimage]
            })
        } else {
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
            guard let imageData = UIImageJPEGRepresentation(image, 0.8) else { return }
            let imagePath = GlobalUserID! +
            "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            self.storageRef.child(imagePath).putData(imageData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error)")
                    self.urlTextView.text = "Upload Failed"
                    return
                }
                self.uploadSuccess(metadata!, storagePath: imagePath)
            }
        }
    }
    
    func uploadSuccess(_ metadata: StorageMetadata, storagePath: String) {
        print("Upload Succeeded!")
        self.urlTextView.text = metadata.downloadURL()?.absoluteString
        UserDefaults.standard.set(storagePath, forKey: "storagePath")
        UserDefaults.standard.synchronize()
        //self.downloadPicButton.isEnabled = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with: UIEvent?){
        experienceTitle.resignFirstResponder()
        experienceDescription.resignFirstResponder()
    }
    
}
