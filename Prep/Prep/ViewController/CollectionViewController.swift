//  File: CollectionViewController.swift
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
import SceneKit
import AVFoundation
import DTZFloatingActionButton
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

// Global Variables
var GlobalCurrentExperience:Experience? = nil
var arrayOfExperiences = [Experience]()

var GlobalcurrentExperienceIndex:Int = 0

var GlobalExperienceSnapshots: Array<DataSnapshot> = []
var GlobalCurrentExperienceID: String? = ""
var GlobalUserID: String? = ""
var ref: DatabaseReference!

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var arrayOfColors = [UIColor]()
    private let leftAndRightPaddings: CGFloat = 20
    private let numberOfItemsPerRow: CGFloat = 3
    private let heightAdjustment: CGFloat = 150
    var cellSelected:IndexPath?
    
    var userRef: DatabaseReference!
    var _refHandle: DatabaseHandle!
    var kSection = 1
    
    var arrayOfSnapshotKeys = [String]()
    
//    func initializePreMades(){
//        var Experience1: Experience = Experience(Name: "Day at the Park", Description: "A whole day trip around London. We'll ride the train in the moring . We'll go shopping at the city centre, eat lunch at the park");
//
//        //add Panorama
//        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience2"))
//        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience9"))
//        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience4"))
//        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience5"))
//
//        Experience1.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 5 , y: 0 ,z: 5), newObject: Bundle.main.path(forResource: "waitinginline", ofType: "mp4")!)
//        Experience1.panoramas[0].addButton(newButtonLocation: SCNVector3(x: -5 , y: 0 ,z: -5), newObject: Bundle.main.path(forResource: "outdoor-crowd-noise", ofType: "wav")!)
//        Experience1.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 7 , y: 1 ,z: 5), newObject: Bundle.main.path(forResource: "baristainteraction", ofType: "mp4")!)
//        Experience1.panoramas[0].addNextPanoramaButton(nextButtonLocation: SCNVector3(x: 3 , y: 1 ,z: 5))
//
//        Experience1.panoramas[1].addButton(newButtonLocation: SCNVector3(x: 5 , y: 0 ,z: 5), newObject: Bundle.main.path(forResource: "car_honk", ofType: "wav")!)
//        Experience1.panoramas[1].addButton(newButtonLocation: SCNVector3(x: -5 , y: 0 ,z: -5), newObject: Bundle.main.path(forResource: "car-pass", ofType: "wav")!)
//        Experience1.panoramas[1].addButton(newButtonLocation: SCNVector3(x: 7 , y: 1 ,z: 5), newObject: Bundle.main.path(forResource: "dogs-barking", ofType: "wav")!)
//        Experience1.panoramas[1].addNextPanoramaButton(nextButtonLocation: SCNVector3(x: 3 , y: 1 ,z: 5))
//        arrayOfExperiences += [Experience1]
//
//        var Experience2: Experience = Experience(Name: "Out at night", Description: "Strolling through the city centre at night")
//        Experience2.addPanorama(newImage: #imageLiteral(resourceName: "Experience8"))
//        Experience2.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 5 , y: 0 ,z: 5), newObject: Bundle.main.path(forResource: "car_honk", ofType: "wav")!)
//        Experience2.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 7 , y: 1 ,z: 5), newObject: Bundle.main.path(forResource: "dogs-barking", ofType: "wav")!)
//        arrayOfExperiences += [Experience2];
//
//    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initializePreMades()
        floatingButton()
        addButton.isEnabled = false
        
        // Set the Firebase reference
        ref = Database.database().reference()
        
        // Listen for new experience in the Firebase database
        fetchExperience()
        
        arrayOfColors = [UIColor.blue,UIColor.purple,UIColor.cyan,UIColor.brown,UIColor.gray,UIColor.yellow,UIColor.orange]
    }

    func fetchExperience() {
        var exp: Experience?
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("user is not logged in")
            return
        }
        
        arrayOfExperiences.removeAll()
        GlobalExperienceSnapshots.removeAll()
        
        // Assign unqiue user id from FireaseAuth to global variable
        GlobalUserID = uid
        
        // Assign a database reference
        userRef = ref.child("user").child(uid)
        
        // Listen for any add child node events in the database and update collection view
        userRef.observe(.childAdded, with: { (snapshot) -> Void in
            // Store Id in the newly created experience object
            exp = Experience(Name: "", Description: "", Id: snapshot.key )
            if let snapshotObject = snapshot.value as? [String: AnyObject] {

                if let snapName = snapshotObject["name"], let snapDescription = snapshotObject["description"] {
                    exp?.setTitle(newtitle: snapName as! String)
                    exp?.setDescription(newDescription: snapDescription as! String)
                }
                
            }
            
            for snap in snapshot.children.allObjects as! [DataSnapshot] {
                self.arrayOfSnapshotKeys.append(snap.key)
                if let snapObject = snap.value as? [String: String] {
                    
                    if let image = snapObject ["image"] {
                        //Convert Url to UIImage
                        let url = URL(string:image)
                        if let data = try? Data(contentsOf: url!) {
                            exp?.addPanorama(newImage: UIImage(data: data)!)
                        }
                    }
                }
            }
            //Append the data to our array
            arrayOfExperiences.append(exp!)
            GlobalExperienceSnapshots.append(snapshot)
            
            // Update collection view
            self.collectionView.insertItems(at: [IndexPath(row: arrayOfExperiences.count-1, section: 0)])
            
        }, withCancel: nil)
        
        // Listen for any remove child node events in the database and update collection view
        ref.child("user").child(uid).observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot)
            GlobalExperienceSnapshots.remove(at: index)
            arrayOfExperiences.remove(at: index)
            DispatchQueue.main.async(execute: {
                self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
            })
            
        }, withCancel: nil)
        
    }
    func indexOfMessage(_ snapshot: DataSnapshot) -> Int {
        var index = 0
        for  snap in GlobalExperienceSnapshots {
            if snapshot.key == snap.key {
                return index
            }
            index += 1
        }
        return -1
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         userRef.removeAllObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Getting the Size of Items
    // Note: For Collection View Box, Width: 942, Height: 656
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width  / numberOfItemsPerRow) - leftAndRightPaddings
        
        return CGSize(width: width, height: width + heightAdjustment)
    }
    
    //Getting the Section Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return leftAndRightPaddings * numberOfItemsPerRow
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return leftAndRightPaddings
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return GlobalExperienceSnapshots.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return kSection
    }
    // Getting the Header and Footer Sizes
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: leftAndRightPaddings*20, height: leftAndRightPaddings * 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: leftAndRightPaddings * 3)
    }

    // Cell Customization
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? CollectionViewCell else { return }
        let cellExperiences = arrayOfExperiences[indexPath.row]
        
        let title = cell.title
        title!.text = cellExperiences.getTitle()

        let imageView = cell.previewImage
        imageView!.image = cellExperiences.getPanorama(index: 0)
        
        // Add Style
        //let randomIndex = Int(arc4random_uniform(UInt32(arrayOfColors.count)))
        //cell.backgroundColor = arrayOfColors[randomIndex]
        cell.layer.cornerRadius = 10
        cell.clipsToBounds = true
        
        // Add guesture recognizer
        let longPressGestureRecong = UILongPressGestureRecognizer(target: self, action: #selector(longPress(press:)))
        longPressGestureRecong.minimumPressDuration = 1.5
        cell.addGestureRecognizer(longPressGestureRecong)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        GlobalCurrentExperience = arrayOfExperiences[indexPath.row]
        GlobalcurrentExperienceIndex = indexPath.row
        let viewController = storyboard?.instantiateViewController(withIdentifier: "viewer")
        //self.navigationController?.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(viewController!, animated: true)
    }
    
    @IBAction func uploadPreMades(_ sender: UIButton) {
        
        
        if let uid = Auth.auth().currentUser?.uid {
            let ExperienceID = ref.child(uid).childByAutoId().key
            let PanID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let numPanoramas = 4;
            let img = ["panorama1": "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience8.jpg?alt=media&token=d4df86a4-9e8d-4f9e-8dc7-c418bbe39e6c"]
            let object = ["name": "Day in the City",
                               "description": "We'll be riding a train to the city, ",
                               PanID : img
                ] as [String : Any]
            
            ref.child("user").child(uid).child(ExperienceID).setValue(object)
            
        }
    }
    
    @objc func longPress(press:UILongPressGestureRecognizer)
    {
        if press.state == .began
        {
            let touchPoint = press.location(in: collectionView)
            let indexPath = collectionView.indexPathForItem(at: touchPoint)
            if indexPath != nil {
                GlobalcurrentExperienceIndex = indexPath!.row
                GlobalCurrentExperience = arrayOfExperiences[indexPath!.row]
                GlobalCurrentExperienceID = GlobalCurrentExperience?.key // get experience id
                
                performSegue(withIdentifier: "HomePageToEditorStartPage", sender: self)
                //let viewController = storyboard?.instantiateViewController(withIdentifier: "editorStartPage")
                //self.navigationController?.pushViewController(viewController!, animated: true)
                
            }
        }
        
    }
    
    // Add button
    func floatingButton() {
        let actionButton = DTZFloatingActionButton(frame:CGRect(x: view.frame.size.width - 56 - 14,
                                                                y: view.frame.size.height - 56 - 14,
                                                                width: 56,
                                                                height: 56
        ))
        actionButton.handler = {
            button in
            // Did Tap Button
            GlobalcurrentExperienceIndex = -1 // -1 for new experience
            self.performSegue(withIdentifier: "HomePageToEditorStartPage", sender: self)
//            let viewController = self.storyboard?.instantiateViewController(withIdentifier: "editorStartPage")
//            self.navigationController?.pushViewController(viewController!, animated: true)
        }
        actionButton.isScrollView = true
        self.view.addSubview(actionButton)

    }
}
