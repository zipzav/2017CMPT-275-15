//
//  Created by Pete Smith
//  http://www.petethedeveloper.com
//
//
//  License
//  Copyright © 2017-present Pete Smith
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import UIKit
import ScalingCarousel
import SceneKit
import FirebaseAuth
import FirebaseDatabase
import DTZFloatingActionButton

var rref: DatabaseReference!
//class Cell: ScalingCarouselCell {}

class SharedExperienceViewController: UIViewController {
    
    var arrayOfExperienceSnapshots: Array<DataSnapshot> = []
    var arrayOfSharedExperiences = [Experience]()
    var sharedExperienceRef: DatabaseReference!
    
    // MARK: - IBOutlets
    @IBOutlet weak var carousel: ScalingCarouselView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI Config
        //floatingButton() // upload premade experiences for development purpose
        self.title = "Shared Experiences"
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        // Database
        rref = Database.database().reference()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationItem.setHidesBackButton(true, animated: false)
        showSpinner()
        fetchSharedExperience()
        carousel.reloadData()
        Timer.scheduledTimer(withTimeInterval: 7, repeats: false, block: { (timer) in
            self.hideSpinner()
        })
    }
    
    // MARK: - Configuration
    
    func fetchSharedExperience() {
        var exp: Experience?
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("user is not logged in")
            return
        }
        
        arrayOfSharedExperiences.removeAll()
        arrayOfExperienceSnapshots.removeAll()
        
        // Assign unqiue user id from FireaseAuth to global variable
        GlobalUserID = uid
        
        // Assign a database reference
        //sharedExperienceRef = Ref.child("user").child(uid)
        
        // Listen for any add child node events in the database and update collection view
        rref.child("shared").queryLimited(toLast: 10).observe(.childAdded, with: { (snapshot) -> Void in
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
            self.arrayOfSharedExperiences.append(exp!)
            self.arrayOfExperienceSnapshots.append(snapshot)
            
            //Update collection view
            self.carousel.insertItems(at: [IndexPath(row: self.arrayOfSharedExperiences.count-1, section: 0)])
            
        }, withCancel: nil)
        
        //Listen for any remove child node events in the database and update collection view
        rref.child("shared").observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot)
            self.arrayOfExperienceSnapshots.remove(at: index)
            DispatchQueue.main.async(execute: {
                self.carousel.deleteItems(at: [IndexPath(row: index, section: 0)])
            })
            
        }, withCancel: {(err) in
            
            print(err) //The cancelBlock will be called if you will no longer receive new events due to no longer having permission.
            
            })
        
    }
    
    func indexOfMessage(_ snapshot: DataSnapshot) -> Int {
        var index = 0
        for  snap in arrayOfExperienceSnapshots {
            if snapshot.key == snap.key {
                return index
            }
            index += 1
        }
        return -1
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        rref.child("shared").removeAllObservers()
    }
    
    // MARK: - Button Actions
    
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
            
            if let uid = Auth.auth().currentUser?.uid {
                
                //First Pre-made Experience
                var Node = "shared"
                let ExperienceID = rref.child(Node).childByAutoId().key
                
                let panCoffeeID = rref.child(Node).child(ExperienceID).childByAutoId().key
                let panTrainID = rref.child(Node).child(ExperienceID).childByAutoId().key
                let panTownID = rref.child(Node).child(ExperienceID).childByAutoId().key
                let panparkID = rref.child(Node).child(ExperienceID).childByAutoId().key
                
                let button1 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/waitinginline.mp4?alt=media&token=e9bf2128-26db-4327-8ed8-a486f1efecda", "locationx": 5, "locationy": 0, "locationz": 5] as [String : Any]
                let button2 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/outdoor-crowd-noise.wav?alt=media&token=d6a92193-9e39-4d57-8ae3-4c7688351574", "locationx": -5, "locationy": 0, "locationz": -5] as [String : Any]
                let button3 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/baristainteraction.mp4?alt=media&token=76c3911a-fdcf-45df-be2f-9e8846a989ef", "locationx": 7, "locationy": 1, "locationz": 5] as [String : Any]
                let buttonall = [button1, button2, button3]
                let coffeeImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience2.jpg?alt=media&token=20b85093-1ed5-4fee-9014-64cf394c19d6", "button" : buttonall] as [String : Any]
                let parkImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience5.jpg?alt=media&token=24420a39-9526-42c6-ba73-1f142fa3c834"]
                let trainImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience9.jpg?alt=media&token=6b16efef-00d8-4be5-b058-d74970131324"]
                let townImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience4.jpg?alt=media&token=026b35e4-e01c-413f-92db-fd433a3a113c"]
                
                let premadeObject = ["name": "Day in London", "description": "We'll be riding the train into London. Maybe some tea and biscuits with 'Nan. We'll head off to shop for knick-knacks and have a jolly good time by Big Ben",  panTrainID : trainImg, panCoffeeID : coffeeImg,  panTownID : townImg, panparkID : parkImg ] as [String : Any]
                
                rref.child("shared").child(ExperienceID).setValue(premadeObject)
                
                //Second Pre-made Experience
                let Experience2ID = rref.child(Node).childByAutoId().key
                
                let CityafterdarkID = rref.child(Node).child(Experience2ID).childByAutoId().key
                
                let E2_button1ID = rref.child(Node).child(Experience2ID).childByAutoId().key
                let E2_button2ID = rref.child(Node).child(Experience2ID).childByAutoId().key
                
                let E2_button1 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/car-pass.wav?alt=media&token=39f3ef28-bf27-4708-9f92-ecd61982b193", "locationx": 2, "locationy": 0, "locationz": -2 ] as [String : Any]
                let E2_button2 = ["action" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/car_honk.wav?alt=media&token=d046dca0-4008-477c-9b18-ff5b1f28b0dc", "locationx": -5, "locationy": 0, "locationz": -5] as [String : Any]
                let E2_buttonall = [E2_button1, E2_button2]
                let CityafterdarkImg = ["image" : "https://firebasestorage.googleapis.com/v0/b/cmpt-275-group11-8d3c8.appspot.com/o/Experience8.jpg?alt=media&token=d4df86a4-9e8d-4f9e-8dc7-c418bbe39e6c", "button" : E2_buttonall] as [String : Any]
                
                let E2_premadeObject = ["name": "Night at the city center", "description": "Downtown's noisy, ain't it? Let's be sure to look both ways when crossing the street",  CityafterdarkID : CityafterdarkImg ] as [String : Any]
                
                rref.child("shared").child(Experience2ID).setValue(E2_premadeObject)
                
            }
        }
        actionButton.isScrollView = true
        self.view.addSubview(actionButton)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}


typealias CarouselDatasource = SharedExperienceViewController
extension CarouselDatasource: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayOfExperienceSnapshots.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let scalingCell = cell as? ScalingCarouselCell {
            let cellExperiences = arrayOfSharedExperiences[indexPath.row]
            scalingCell.cellImage.image = cellExperiences.getPanorama(index: 0)
            scalingCell.cellTitle.text = cellExperiences.getTitle()
            
            // Add style
            scalingCell.clipsToBounds = true
            scalingCell.mainView.clipsToBounds = true
            scalingCell.layer.cornerRadius = 20
            scalingCell.mainView.layer.cornerRadius = 20
            scalingCell.mainView.backgroundColor = .red
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        GlobalCurrentExperience = arrayOfSharedExperiences[indexPath.row]
        performSegue(withIdentifier: "SharedExperienceToViewer", sender: self)
    }
}

typealias CarouselDelegate = SharedExperienceViewController
extension SharedExperienceViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        carousel.didScroll()
        
        //guard let currentCenterIndex = carousel.currentCenterCellIndex?.row else { return }
    }
}


