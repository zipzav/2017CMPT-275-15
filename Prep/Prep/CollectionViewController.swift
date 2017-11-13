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

var GlobalCurrentExperience:Experience? = nil
var arrayOfExperiences = [Experience]()
var arrayOfImages = [UIImage]()
var arrayOfTitles = [String]()
var GlobalcurrentExperienceIndex:Int = 0
var experiences: Array<DataSnapshot> = []

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    var arrayOfIDs = [String]()
    var arrayOfColors = [UIColor]()
    private let leftAndRightPaddings: CGFloat = 20
    private let numberOfItemsPerRow: CGFloat = 3
    private let heightAdjustment: CGFloat = 150
    var cellSelected:IndexPath?
    
    var ref: DatabaseReference!
    
    func initializePreMades(){
        var Experience1: Experience = Experience(Name: "Day at the Park", Description: "A whole day trip around London. We'll ride the train in the moring . We'll go shopping at the city centre, eat lunch at the park");
        
        //add Panorama
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience2"))
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience9"))
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience4"))
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience5"))

        Experience1.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 5 , y: 0 ,z: 5), newObject: Bundle.main.path(forResource: "waitinginline", ofType: "mp4")!)
        Experience1.panoramas[0].addButton(newButtonLocation: SCNVector3(x: -5 , y: 0 ,z: -5), newObject: Bundle.main.path(forResource: "outdoor-crowd-noise", ofType: "wav")!)
        Experience1.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 7 , y: 1 ,z: 5), newObject: Bundle.main.path(forResource: "baristainteraction", ofType: "mp4")!)
        Experience1.panoramas[0].addNextPanoramaButton(nextButtonLocation: SCNVector3(x: 3 , y: 1 ,z: 5))
        
        Experience1.panoramas[1].addButton(newButtonLocation: SCNVector3(x: 5 , y: 0 ,z: 5), newObject: Bundle.main.path(forResource: "car_honk", ofType: "wav")!)
        Experience1.panoramas[1].addButton(newButtonLocation: SCNVector3(x: -5 , y: 0 ,z: -5), newObject: Bundle.main.path(forResource: "car-pass", ofType: "wav")!)
        Experience1.panoramas[1].addButton(newButtonLocation: SCNVector3(x: 7 , y: 1 ,z: 5), newObject: Bundle.main.path(forResource: "dogs-barking", ofType: "wav")!)
        Experience1.panoramas[1].addNextPanoramaButton(nextButtonLocation: SCNVector3(x: 3 , y: 1 ,z: 5))
        arrayOfExperiences += [Experience1]

        var Experience2: Experience = Experience(Name: "Out at night", Description: "Strolling through the city centre at night")
        Experience2.addPanorama(newImage: #imageLiteral(resourceName: "Experience8"))
        Experience2.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 5 , y: 0 ,z: 5), newObject: Bundle.main.path(forResource: "car_honk", ofType: "wav")!)
        Experience2.panoramas[0].addButton(newButtonLocation: SCNVector3(x: 7 , y: 1 ,z: 5), newObject: Bundle.main.path(forResource: "dogs-barking", ofType: "wav")!)
        arrayOfExperiences += [Experience2];

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //initializePreMades()
        floatingButton()
        addButton.isEnabled = false
        
        // Set the Firebase reference
        ref = Database.database().reference()
        
        //experiences.removeAll()
        // [START child_event_listener]
        // Listen for new comments in the Firebase database
        fetchExperience()
        
        
        for experience in arrayOfExperiences{
            arrayOfImages += [experience.getPanorama(index: 0)] //to-do: obtained from saved experience
            arrayOfTitles += [experience.name] //to-do: obtained from saved experience
        }
        
        arrayOfColors = [UIColor.blue,UIColor.purple,UIColor.cyan,UIColor.brown,UIColor.gray,UIColor.yellow,UIColor.orange]
    }
    
    func fetchExperience() {
        var exp: Experience?
        ref.child("user").observe(.childAdded, with: { (snapshot) -> Void in
            if let snapObject = snapshot.value as? [String: AnyObject] { // Database is not empty
            if let snapName = snapObject["name"], let snapDescription = snapObject["description"] {
                exp = Experience(Name: snapName as! String, Description: snapDescription as! String)
                
                // Search for a child call panoramas
                for childsnap in snapshot.children.allObjects as! [DataSnapshot] {
                    print("key of child \(childsnap.key)")
                    
                    let snapObject = childsnap.value as? [String: AnyObject]
                    if let image = snapObject?["image"] {
                        //print(image)
                        
                        // Convert Url to UIImage
                        let url = URL(string:image as! String)
                        if let data = try? Data(contentsOf: url!) {
                            exp?.addPanorama(newImage: UIImage(data: data)!)
                        }
                    }
                }
                    //Append the data to our array
                    arrayOfExperiences += [exp!]
                
                    DispatchQueue.main.async(execute: {
                        self.collectionView.reloadData()
                })
            }
            }
        }, withCancel: nil)
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
        return arrayOfExperiences.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
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
        cell.layer.cornerRadius = 10
        cell.clipsToBounds = true
        
        let cellExperiences = arrayOfExperiences[indexPath.item]

        
        let title = cell.title
        title!.text = cellExperiences.name
        
        let imageView = cell.previewImage
        imageView!.image = cellExperiences.getPanorama(index: 0)
        
        let randomIndex = Int(arc4random_uniform(UInt32(arrayOfColors.count)))
        cell.backgroundColor = arrayOfColors[randomIndex]
        
        
        
        // add guesture recognizer
        let longPressGestureRecong = UILongPressGestureRecognizer(target: self, action: #selector(longPress(press:)))
        longPressGestureRecong.minimumPressDuration = 1.5
        cell.addGestureRecognizer(longPressGestureRecong)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    }
    
    //func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //    CurrentExperience = userExperience[indexPath.item]
    //}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        GlobalCurrentExperience = arrayOfExperiences[indexPath.row]
        GlobalcurrentExperienceIndex = indexPath.row
        let viewController = storyboard?.instantiateViewController(withIdentifier: "viewer")
        //self.navigationController?.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(viewController!, animated: true)
    }
    
    @objc func longPress(press:UILongPressGestureRecognizer)
    {
        if press.state == .began
        {
            //addButton.isEnabled = true
            let touchPoint = press.location(in: collectionView)
            let indexPath = collectionView.indexPathForItem(at: touchPoint)
            if indexPath != nil {
                GlobalCurrentExperience = arrayOfExperiences[indexPath!.row]
                
                let viewController = storyboard?.instantiateViewController(withIdentifier: "viewer")
                self.navigationController?.pushViewController(viewController!, animated: true)
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
            if let uid = Auth.auth().currentUser?.uid {
                print("pass")
                //                let user = self.ref.child(uid)
                //                let exp = user.child("Experience3")
                //                exp.child("name").setValue("Out at night")
                //                exp.child("description").setValue("Strolling through the city centre at night")
                //                exp.child("panoramas").child("image").setValue("https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/cylindrical.jpg?alt=media&token=7b78da27-160f-4150-9479-81ad93e462bf")
                
                let userObjInfo = ["name": "Out at night",
                                   "description": "Strolling through the city centre at night"
                ]
                let imgObjInfo = ["image": "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/cylindrical.jpg?alt=media&token=7b78da27-160f-4150-9479-81ad93e462bf"]
                let PanID = self.ref.child(uid).childByAutoId().key
                let childUpdates = ["/user/\(uid)" : userObjInfo]
                self.ref.updateChildValues(childUpdates)
                
                let childUpdate = [ "/user/\(uid)/\(PanID)" : imgObjInfo]
                self.ref.updateChildValues(childUpdate)
                
            } else {
                print("fail")
            }
        }
        actionButton.isScrollView = true
        self.view.addSubview(actionButton)

    }
}
