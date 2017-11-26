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
var firstload = false
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
    
    var userRef: DatabaseReference!
    var _refHandle: DatabaseHandle!
    var kSection = 1
    
    var arrayOfSnapshotKeys = [String]()
    
    @IBOutlet weak var fetchprogress: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = "My Collection"
        //initializePreMades()
        floatingButton()
        //navigationItem.hidesBackButton = true
        addButton.isEnabled = false
        self.collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshExperienceData(_:)), for: .valueChanged)
        // Set the Firebase reference
        ref = Database.database().reference()
        // Listen for new experience in the Firebase database
        //DispatchQueue.main.async {
            self.refreshControl.beginRefreshing()
        //}
        //if(firstload == false){
        fetchExperience()
        //   firstload = true;
        //}
        //self.collectionView.reloadData()
        //self.collectionView.reloadData()
        //fetchprogress.text = "Done Retrieving Data"
        
    }

    @objc private func refreshExperienceData(_ sender: Any) {
        // Fetch Weather Data
        //fetchExperience()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        self.refreshControl.endRefreshing()
        //self.activityIndicatorView.stopAnimating()
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
            
            
            
            var panoindex = 0 //each snap Object is one panorama
            for snap in snapshot.children.allObjects as! [DataSnapshot] {
                self.arrayOfSnapshotKeys.append(snap.key)
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
                                let x = temp["locationx"] as! Int
                                let y = temp["locationy"] as! Int
                                let z = temp["locationz"] as! Int
                            
                                let actionurl = temp["action"] as! String
                                if let data = try? Data(contentsOf: url!) {
                                    exp?.panoramas[panoindex].addButton(
                                    newButtonLocation: SCNVector3(x:Float(x),y:Float(y),z:Float(z)),
                                        newObject: actionurl)
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
            
            //ß Update collection view
            //DispatchQueue.main.async {
                self.collectionView.insertItems(at: [IndexPath(row: arrayOfExperiences.count-1, section: 0)])
            self.refreshControl.endRefreshing()
            //}

            
        }, withCancel: nil)
        
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
        //let viewController = storyboard?.instantiateViewController(withIdentifier: "viewer")
        //self.navigationController?.hidesBottomBarWhenPushed = true
        //self.navigationController?.pushViewController(viewController!, animated: true)
        //performSegue(withIdentifier: "HomeToViewer", sender: self)
        
    }
    
    @IBAction func uploadPreMades(_ sender: UIButton) {
        
        
        if let uid = Auth.auth().currentUser?.uid {
            //First Pre-made Experience
            let ExperienceID = ref.child(uid).childByAutoId().key
            
            
            let panCoffeeID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let panTrainID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let panTownID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let panparkID = ref.child(uid).child(ExperienceID).childByAutoId().key
            

            let button1ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let button2ID = ref.child(uid).child(ExperienceID).childByAutoId().key
            let button3ID = ref.child(uid).child(ExperienceID).childByAutoId().key

            
            let button1 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/waitinginline.mp4?alt=media&token=e9bf2128-26db-4327-8ed8-a486f1efecda", "locationx": 5, "locationy": 0, "locationz": 5] as [String : Any]
            let button2 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/outdoor-crowd-noise.wav?alt=media&token=d6a92193-9e39-4d57-8ae3-4c7688351574", "locationx": -5, "locationy": 0, "locationz": -5] as [String : Any]
            let button3 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/baristainteraction.mp4?alt=media&token=76c3911a-fdcf-45df-be2f-9e8846a989ef", "locationx": 7, "locationy": 1, "locationz": 5] as [String : Any]
            let buttonall = [button1, button2, button3]
            let coffeeImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience2.jpg?alt=media&token=20b85093-1ed5-4fee-9014-64cf394c19d6", "button" : buttonall] as [String : Any]
            let parkImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience5.jpg?alt=media&token=24420a39-9526-42c6-ba73-1f142fa3c834"]
            let trainImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience9.jpg?alt=media&token=6b16efef-00d8-4be5-b058-d74970131324"]
            let townImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience4.jpg?alt=media&token=026b35e4-e01c-413f-92db-fd433a3a113c"]
            
            let premadeObject = ["name": "Day in London", "description": "We'll be riding the train into London. Maybe some tea and biscuits with 'Nan. We'll head off to shop for knick-knacks and have a jolly good time by Big Ben",  panTrainID : trainImg, panCoffeeID : coffeeImg,  panTownID : townImg, panparkID : parkImg ] as [String : Any]
            
            ref.child("user").child(uid).child(ExperienceID).setValue(premadeObject)
            //End First Pre-made Experience
            //Second Pre-made Experience
            let Experience2ID = ref.child(uid).childByAutoId().key
            
            
            let CityafterdarkID = ref.child(uid).child(Experience2ID).childByAutoId().key
            
            
            let E2_button1ID = ref.child(uid).child(Experience2ID).childByAutoId().key
            let E2_button2ID = ref.child(uid).child(Experience2ID).childByAutoId().key
        
            let E2_button1 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/car-pass.wav?alt=media&token=39f3ef28-bf27-4708-9f92-ecd61982b193", "locationx": 2, "locationy": 0, "locationz": -2 ] as [String : Any]
            let E2_button2 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/car_honk.wav?alt=media&token=d046dca0-4008-477c-9b18-ff5b1f28b0dc", "locationx": -5, "locationy": 0, "locationz": -5] as [String : Any]
            let E2_buttonall = [E2_button1, E2_button2]
            let CityafterdarkImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience8.jpg?alt=media&token=d4df86a4-9e8d-4f9e-8dc7-c418bbe39e6c", "button" : E2_buttonall] as [String : Any]
            
            let E2_premadeObject = ["name": "Night at the city center", "description": "Downtown's noisy, ain't it? Let's be sure to look both ways when crossing the street",  CityafterdarkID : CityafterdarkImg ] as [String : Any]
            
            ref.child("user").child(uid).child(Experience2ID).setValue(E2_premadeObject)
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
                    //let viewController = self.storyboard?.instantiateViewController(withIdentifier: "editorStartPage")
                    //self.navigationController?.pushViewController(viewController!, animated: true)
                    self.performSegue(withIdentifier: "HomePageToEditorStartPage", sender: self)
                }
                let deleteExp = UIAlertAction(title: "Share", style: .default) { (action) in
//                    //arrayOfExperiences.remove(at: indexPath!.row)
//                    if GlobalcurrentExperienceIndex != -1 {
//                        ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
//                    } else {
//                        ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
//                    }
//                    GlobalExperienceSnapshots.remove(at: indexPath!.row)
//                    arrayOfExperiences.remove(at: indexPath!.row)
//                    DispatchQueue.main.async(execute: {
//                        self.collectionView.deleteItems(at: [indexPath!])
//                    })
                }
                let shareExp = UIAlertAction(title: "Delete", style: .default) { (action) in
                    //arrayOfExperiences.remove(at: indexPath!.row)
                    if GlobalcurrentExperienceIndex != -1 {
                        ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
                    } else {
                        ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).removeValue()
                    }
                    GlobalExperienceSnapshots.remove(at: indexPath!.row)
                    arrayOfExperiences.remove(at: indexPath!.row)
                        DispatchQueue.main.async(execute: {
                            self.collectionView.deleteItems(at: [indexPath!])
                        })
                }
                let backToHome = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                sheet.addAction(shareExp)
                sheet.addAction(goToEditor)
                sheet.addAction(deleteExp)
                sheet.addAction(backToHome)
                
                let popOver = sheet.popoverPresentationController
                popOver?.sourceView = collectionView.cellForItem(at: indexPath!)
                popOver?.sourceRect = (collectionView.cellForItem(at: indexPath!)?.bounds)!
                popOver?.permittedArrowDirections = UIPopoverArrowDirection.any
                
                present(sheet, animated: true, completion: nil)
                
                //let viewController = storyboard?.instantiateViewController(withIdentifier: "viewer")
                //self.navigationController?.pushViewController(viewController!, animated: true)
                //performSegue(withIdentifier: "HomePageToEditorStartPage", sender: self)
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
