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
var GlobalRef: DatabaseReference? = nil
var GlobalcurrentExperienceIndex:Int = 0

var GlobalExperienceSnapshots: Array<DataSnapshot> = []
var GlobalCurrentExperienceID: String? = ""
var GlobalUserID: String? = ""
extension UIRefreshControl {
    func refreshManually() {
        if let scrollView = superview as? UIScrollView {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - frame.height), animated: false)
        }
        beginRefreshing()
        sendActions(for: .valueChanged)
    }
}

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var arrayOfColors = [UIColor]()
    private let leftAndRightPaddings: CGFloat = 20
    private let numberOfItemsPerRow: CGFloat = 3
    private let heightAdjustment: CGFloat = 150
    private let refreshControl = UIRefreshControl()
    var cellSelected:IndexPath?
    
    var ref: DatabaseReference!
    var userRef: DatabaseReference!
    var _refHandle: DatabaseHandle!
    var kSection = 1
    
    @IBOutlet weak var fetchprogress: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = "My Collection"
        //initializePreMades()
        //navigationItem.hidesBackButton = true
        
        addButton.isEnabled = false
        // Set the Firebase reference
        ref = Database.database().reference()
        GlobalRef = ref
        // Monitor Connection to Wifi
        Reach().monitorReachabilityChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        network().checkConnection()
        // Loading Icon
        self.collectionView.refreshControl = refreshControl
        self.refreshControl.beginRefreshing()
        floatingButton()
        // Listen for new experience in the Firebase database
        fetchExperience()
        // Reload data after 'Back' button is clicked on Experience viewer page
        collectionView.reloadData()
        // Stop spinner when no data to show on home page
        Timer.scheduledTimer(withTimeInterval: 8, repeats: false, block: { (timer) in
            self.refreshControl.endRefreshing()
            if (hasConnection == false) {
                self.showMessagePrompt("We're having trouble connecting to Prep right now. Check your connection or try again in a bit")
            } else {
                if(GlobalExperienceSnapshots.count == 0) {
                    self.showMessagePrompt("No experience to show. Select '+' button to create your first experience")
                }
            }
        })
    }
    
    func fetchExperience() {
        var exp: Experience?
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("user is not logged in")
            return
        }
        
        arrayOfExperiences.removeAll()
        GlobalExperienceSnapshots.removeAll()
        
        // Do not assign a reference to database when offline
        guard (hasConnection == true) else {return}
        
        // Assign unqiue user id from FireaseAuth to global variable
        GlobalUserID = uid
        
        // Assign a database reference
        userRef = ref.child("user").child(uid)
        
        // Listen for any add child node events in the database and update collection view
        userRef.queryLimited(toLast: 10).observe(.childAdded, with: { (snapshot) -> Void in
            // Store Id in the newly created experience object
            exp = Experience(Name: "", Description: "", Id: snapshot.key )
            if let snapshotObject = snapshot.value as? [String: AnyObject] {
                
                if let snapName = snapshotObject["name"], let snapDescription = snapshotObject["description"] {
                    exp?.setTitle(newtitle: snapName as! String)
                    exp?.setDescription(newDescription: snapDescription as! String)
                }
            }
            var panoindex = 0 //each snap Object is one panorama
            for snap in snapshot.children.allObjects as! [DataSnapshot] {
                if let snapObject = snap.value as? [String: AnyObject] {
                    if let image = snapObject ["image"] {
                        //Convert Url to UIImage
                        let url = URL(string:image as! String)
                        if let data = try? Data(contentsOf: url!) {
                            exp?.addPanorama(newImage: UIImage(data: data)!, Id: snap.key)
                        }
                        if let buttons = snapObject["button"]{
                            for button in buttons as! NSMutableArray{
                                let temp = button as! [String : AnyObject]
                                let x = temp["locationx"] as! Float
                                let y = temp["locationy"] as! Float
                                let z = temp["locationz"] as! Float
                                
                                let actionurl = temp["action"] as! String
                                if let data = try? Data(contentsOf: url!) {
                                    if(panoindex >= (exp?.panoramas.count)!){
                                    exp?.panoramas[panoindex].addButton(
                                        newButtonLocation: SCNVector3(x:Float(x),y:Float(y),z:Float(z)),
                                        newObject: actionurl)
                                    }
                                }
                            }
                        }
                    }
                    panoindex += 1
                }
            }
            //Append the data to our array
            arrayOfExperiences.append(exp!)
            GlobalExperienceSnapshots.append(snapshot)
            
            //Update collection view
            self.collectionView.insertItems(at: [IndexPath(row: arrayOfExperiences.count-1, section: 0)])
            DispatchQueue.main.async(execute: {
                self.refreshControl.endRefreshing() // execute this line once, before leaving .observe
            })
        }, withCancel: {(err) in
            
            print(err) //The cancelBlock will be called if you will no longer receive new events due to no longer having permission.
            
        })
        
        
        // Listen for any remove child node events in the database and update collection view
        //ref.child("user").child(uid).observe(.childRemoved, with: { (snapshot) -> Void in
        //    let index = self.indexOfMessage(snapshot)
        //    GlobalExperienceSnapshots.remove(at: index)
        //    arrayOfExperiences.remove(at: index)
        //    DispatchQueue.main.async(execute: {
        //        self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        //    })
        //
        //}, withCancel: nil)
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
        if(userRef != nil ) {
            userRef.removeAllObservers()
        }
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
        
        let desc = cell.desc
        desc?.text = cellExperiences.getDescription()
        desc?.sizeToFit()
        
        let imageView = cell.previewImage
        imageView!.image = cellExperiences.getPanorama(index: 0)
        
        // Add Style
        //let randomIndex = Int(arc4random_uniform(UInt32(arrayOfColors.count)))
        //cell.backgroundColor = arrayOfColors[randomIndex]
        cell.layer.cornerRadius = 10
        cell.clipsToBounds = true
        
        // Add guesture recognizer
        let longPressGestureRecong = UILongPressGestureRecognizer(target: self, action: #selector(longPress(press:)))
        longPressGestureRecong.minimumPressDuration = 1.3
        cell.addGestureRecognizer(longPressGestureRecong)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        GlobalCurrentExperience = arrayOfExperiences[indexPath.row]
        GlobalcurrentExperienceIndex = indexPath.row
        //performSegue(withIdentifier: "HomeToViewer", sender: self)
    }
    
    @IBAction func uploadPreMades(_ sender: UIButton) {
        
        if let uid = Auth.auth().currentUser?.uid {
            //First Pre-made Experience
            let ExperienceID = ref.child(uid).childByAutoId().key
            
            let b1ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let b2ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let b3ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let b4ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            
            let button1ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let button2ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let button3ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let button4ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            
            
            let button1 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/flock-of-seagulls_daniel-simion.mp3?alt=media&token=e1a85ea4-0e8c-48f7-8a62-ae011d25c7a2", "locationx": 5, "locationy": 0, "locationz": 5] as [String : Any]
            let button2 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Beach%20Soundscape%203-SoundBible.com-416299667.mp3?alt=media&token=b0c1f305-9091-4782-a2f3-8d7ce086ae3c", "locationx": -5, "locationy": 0, "locationz": -5] as [String : Any]
            let button3 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Beach%20Waves-SoundBible.com-1024681188.mp3?alt=media&token=a6161914-360e-4d98-bad1-8a34665e1889", "locationx": 7, "locationy": 1, "locationz": 5] as [String : Any]
            let button4 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/South%20Beach%20Ocean%20View.mp4?alt=media&token=332c03b7-502e-40a6-86c1-6ca5d2ff20f2", "locationx": 7, "locationy": 1, "locationz": 5] as [String : Any]
            let buttonsl = [button1]
            let buttons24 = [button2, button4]
            let beachPan1 = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/beachPan2.jpg?alt=media&token=bfa010fd-023e-4811-a61f-a881d8ad59fc", "button" : buttonsl] as [String : Any]
            let beachPan2 = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/beachpan3.jpg?alt=media&token=f040e8e4-d02d-4a89-9cf3-97325dedf682","button" : buttons24] as [String : Any]
            let beachPan3 = ["image": "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/beachpan4.jpg?alt=media&token=12d1dcf5-be1c-479e-aea3-c4a14dae22cb"]
            let beachPan4 = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/panorama_beach_1.jpg?alt=media&token=a8f692bd-47fa-4030-bb82-c0e2c5297ba8","button" : [button3]] as [String : Any]
            
            let premadeObject = ["name": "Day at Miami Beach", "description": "A nice relaxing walk through the beach all the way to the ocean for a swim.",  b1ID : beachPan1, b2ID : beachPan2,  b3ID : beachPan3, b4ID : beachPan4 ] as [String : Any]
            ref.child("user").child(uid).child(ExperienceID).setValue(premadeObject)
            
            /////////////////////////////////////////////////////////////////////////////////
            
            let Experience2ID = ref.child(uid).childByAutoId().key
            let CityafterdarkID = ref.child(uid).child(Experience2ID).childByAutoId().key
            
            let E2_button1ID = ref.child(uid).child(Experience2ID).childByAutoId().key
            let E2_button2ID = ref.child(uid).child(Experience2ID).childByAutoId().key
            
            let E2_button1 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/car-pass.wav?alt=media&token=39f3ef28-bf27-4708-9f92-ecd61982b193", "locationx": 2, "locationy": 0, "locationz": -2 ] as [String : Any]
            let E2_button2 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/car_honk.wav?alt=media&token=d046dca0-4008-477c-9b18-ff5b1f28b0dc", "locationx": -5, "locationy": 0, "locationz": -5] as [String : Any]
            let E2_buttonall = [E2_button1, E2_button2]
            let CityafterdarkImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience8.jpg?alt=media&token=d4df86a4-9e8d-4f9e-8dc7-c418bbe39e6c", "button" : E2_buttonall] as [String : Any]
            
            let E2_premadeObject = ["name": "Night at The City Center", "description": "Downtown's noisy, ain't it? Let's be sure to look both ways when crossing the street.",  CityafterdarkID : CityafterdarkImg ] as [String : Any]
            
            ref.child("user").child(uid).child(Experience2ID).setValue(E2_premadeObject)
            
            let ExperienceID3 = ref.child(uid).childByAutoId().key
            
            let rest1 = ref.child(uid).child(ExperienceID3).childByAutoId().key
            let rest2 = ref.child(uid).child(ExperienceID3).childByAutoId().key
            
            let r1ID = ref.child(uid).child(ExperienceID3).childByAutoId().key
            let r2ID = ref.child(uid).child(ExperienceID3).childByAutoId().key
            let r3ID = ref.child(uid).child(ExperienceID3).childByAutoId().key
            
            let rB1 = ["action" : "hhttps://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/baristainteraction.mp4?alt=media&token=76c3911a-fdcf-45df-be2f-9e8846a989ef", "locationx": 5, "locationy": 0, "locationz": 5] as [String : Any]
            let rB2 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Restaurant%20Ambiance%20-SoundBible.com-628640170.mp3?alt=media&token=39f0bb6b-6889-4688-bdbf-3a4bd1d6fed3", "locationx": 5, "locationy": 0, "locationz": 5] as [String : Any]
            let rB3 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/outdoor-crowd-noise.wav?alt=media&token=d6a92193-9e39-4d57-8ae3-4c7688351574", "locationx": 5, "locationy": 0, "locationz": 5] as [String : Any]
            let insideRest = [rB1, rB2]
            
            let restPan1 = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/rPan1.jpeg?alt=media&token=dcd8f6cd-30f2-4f5c-82a0-7bd197c6d9b0", "button" : insideRest] as [String : Any]
            let restPan2 = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/rPan2.jpeg?alt=media&token=63ddc5b0-edd7-4475-9ced-09a26074a2bb", "button" : [rB3]] as [String : Any]
            
            let restPremadeObject = ["name": "Forage Restaurant in Vancouver", "description": "Wineing and Dining inside Forage on Robson.",  rest1 : restPan1, rest2 : restPan2] as [String : Any]
            
            ref.child("user").child(uid).child(ExperienceID3).setValue(restPremadeObject)

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
                let sheet = UIAlertController(title: "Options", message: "Please Choose an Option", preferredStyle: .actionSheet)
                let goToEditor = UIAlertAction(title: "Edit", style: .default) { (action) in
                    GlobalcurrentExperienceIndex = indexPath!.row
                    self.performSegue(withIdentifier: "HomePageToEditorStartPage", sender: self)
                }
                let shareExp = UIAlertAction(title: "Share", style: .default) { (action) in
                    var snapshot = GlobalExperienceSnapshots[indexPath!.row] // get snapshot object for particular index
                    var experienceID = snapshot.key // get experience id
                    if let snapshotObject = snapshot.value as? [String: AnyObject] {
                        
                        if let snapName = snapshotObject["name"], let snapDescription = snapshotObject["description"] {
                            // Add title and description field to database
                            self.ref.child("shared/\(experienceID)/name").setValue("\(snapName)")
                            self.ref.child("shared/\(experienceID)/description").setValue("\(snapDescription)")
                        }
                    }
                    for snap in snapshot.children.allObjects as! [DataSnapshot] {
                        let panoramaID = snap.key
                        if let snapObject = snap.value as? [String: AnyObject] {
                            if let image = snapObject ["image"] {
                                // Add image to database
                                self.self.ref.child("shared/\(experienceID)/\(panoramaID)/image").setValue("\(image)")
                                var i = 0
                                if let buttons = snapObject["button"]{
                                    for button in buttons as! NSMutableArray{
                                        let temp = button as! [String : AnyObject]
                                        let a = temp["action"] as! String
                                        let x = temp["locationx"] as! Int
                                        let y = temp["locationy"] as! Int
                                        let z = temp["locationz"] as! Int
                                        // Add button data to database
                                        self.ref.child("shared/\(experienceID)/\(panoramaID)/button").child("\(i)").updateChildValues(["action":a])
                                        self.ref.child("shared/\(experienceID)/\(panoramaID)/button").child("\(i)").updateChildValues(["locationx":x])
                                        self.ref.child("shared/\(experienceID)/\(panoramaID)/button").child("\(i)").updateChildValues(["locationy":y])
                                        self.ref.child("shared/\(experienceID)/\(panoramaID)/button").child("\(i)").updateChildValues(["locationz":z])
                                        i += 1
                                    }
                                }
                            }
                        }
                    }
                }
                let deleteExp = UIAlertAction(title: "Delete", style: .default) { (action) in
                    //arrayOfExperiences.remove(at: indexPath!.row)
                    if GlobalcurrentExperienceIndex != -1 {
                        self.ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
                    } else {
                        self.ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
                    }
                    GlobalExperienceSnapshots.remove(at: indexPath!.row)
                    arrayOfExperiences.remove(at: indexPath!.row)
                    DispatchQueue.main.async(execute: {
                        self.collectionView.deleteItems(at: [indexPath!])
                    })
                }
                let backToHome = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                sheet.addAction(goToEditor)
                sheet.addAction(shareExp)
                sheet.addAction(deleteExp)
                sheet.addAction(backToHome)
                
                let popOver = sheet.popoverPresentationController
                popOver?.sourceView = collectionView.cellForItem(at: indexPath!)
                popOver?.sourceRect = (collectionView.cellForItem(at: indexPath!)?.bounds)!
                popOver?.permittedArrowDirections = UIPopoverArrowDirection.any
                
                present(sheet, animated: true, completion: nil)
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
            network().checkConnection()
            if hasConnection == true {
                if arrayOfExperiences.count >= 10{
                    self.showMessagePrompt("You can create up to 10 experiences")
                } else {
                    GlobalcurrentExperienceIndex = -1 // -1 for new experience
                    self.performSegue(withIdentifier: "HomePageToEditorStartPage", sender: self)
                }
            } else {
                self.showMessagePrompt("We're having trouble connecting to Prep right now. Check your connection or try again in a bit")
            }
        }
        
        actionButton.layer.shadowColor = UIColor.darkGray.cgColor
        actionButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        actionButton.layer.shadowRadius = 3
        actionButton.layer.shadowOpacity = 0.3
        actionButton.buttonColor = UIColor.PrepPurple
        actionButton.isScrollView = true
        self.view.addSubview(actionButton)
    }
    @IBAction func GoToSharedExperiences(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "HomePageToSharedExperiences", sender: self)
    }
    
    
}

