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
class Cell: ScalingCarouselCell {}

class SharedExperienceViewController: UIViewController {
    
    var arrayOfExperienceSnapshots: Array<DataSnapshot> = []
    var arrayOfSharedExperiences = [Experience]()
    var sharedExperienceRef: DatabaseReference!
    
    private let refreshControl = UIRefreshControl()
    
    // MARK: - IBOutlets
    @IBOutlet weak var carousel: ScalingCarouselView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Shared Experiences"
        
        rref = Database.database().reference()
        navigationItem.hidesBackButton = true
        
        carousel.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshExperienceData(_:)), for: .valueChanged)
        self.refreshControl.beginRefreshing()
        fetchSharedExperience()
        
        floatingButton()
//        carousel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
//        carousel.heightAnchor.constraint(equalToConstant: 500).isActive = true
//
//        carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        carousel.topAnchor.constraint(equalTo: view.topAnchor, constant: 180).isActive = true
        
    }
    
    @objc private func refreshExperienceData(_ sender: Any) {
        // Fetch Weather Data
        //fetchExperience()
        DispatchQueue.main.async {
            self.carousel.reloadData()
        }
        self.refreshControl.endRefreshing()
        //self.activityIndicatorView.stopAnimating()
    }
    
    // MARK: - Button Actions
    
    
    
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
        rref.child("shared").observe(.childAdded, with: { (snapshot) -> Void in
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
            self.carousel.refreshControl?.endRefreshing()

        }, withCancel: nil)
        
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
            //scalingCell.mainView.backgroundColor = .red
            scalingCell.cellImage.image = cellExperiences.getPanorama(index: 0)
            scalingCell.cellTitle.text = cellExperiences.getTitle()
            
            // Add style
            scalingCell.clipsToBounds = true
            scalingCell.layer.cornerRadius = 10
        }
        return cell
    }
}

typealias CarouselDelegate = SharedExperienceViewController
extension SharedExperienceViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        carousel.didScroll()
        
        //guard let currentCenterIndex = carousel.currentCenterCellIndex?.row else { return }
        
    }

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 300, height: 450)
//    }

    
}


