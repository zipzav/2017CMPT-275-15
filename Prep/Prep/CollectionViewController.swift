//
//  CollectionViewController.swift
//  Prep
//
//  Created by sychung on 10/30/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation

var CurrentExperience:Experience? = nil

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var arrayOfImages = [UIImage]()
    var arrayOfIDs = [String]()
    var arrayOfTitles = [String]()
    var arrayOfColors = [UIColor]()
    var arrayOfExperiences = [Experience]()
    private let leftAndRightPaddings: CGFloat = 20
    private let numberOfItemsPerRow: CGFloat = 3
    private let heightAdjustment: CGFloat = 150
    
    func initializePreMades(){
        var Experience1: Experience = Experience(Name: "Day at the Park", Description: "A whole day trip around London. We'll ride the train in the moring . We'll go shopping at the city centre, eat lunch at the park");
        //add Panorama
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience2"))
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience9"))
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience4"))
        Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience5"))
        //Experience1.addPanorama(newImage: #imageLiteral(resourceName: "Experience8"))
        //add PanoramaButtons
        //let urlPathString:String? = Bundle.main.path(forResource: "car-pass", ofType: ".wav")
        //let temp = Bundle.main.path(forResource: "car-pass", ofType: ".wav")
        //let url:URL = Bundle.main.url(forResource: "car-pass", withExtension: "wav")!

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
        initializePreMades()
        
        for experience in arrayOfExperiences{
            arrayOfImages += [experience.getPanorama(index: 0)] //to-do: obtained from saved experience
            arrayOfTitles += [experience.name] //to-do: obtained from saved experience
        }
        
        arrayOfColors = [UIColor.blue,UIColor.purple,UIColor.cyan,UIColor.brown,UIColor.gray,UIColor.yellow,UIColor.orange]
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
        return arrayOfImages.count
    }
    // Getting the Header and Footer Sizes
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: leftAndRightPaddings*20, height: leftAndRightPaddings * 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: leftAndRightPaddings * 3)
    }

    // Cell Customization
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        let title = cell.viewWithTag(1) as! UILabel
        title.text = arrayOfTitles[indexPath.row]
        
        let imageView = cell.viewWithTag(2) as! UIImageView
        imageView.image = arrayOfImages[indexPath.row]
        
        let randomIndex = Int(arc4random_uniform(UInt32(arrayOfColors.count)))
        cell.backgroundColor = arrayOfColors[randomIndex]
        return cell
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
        CurrentExperience = arrayOfExperiences[indexPath.row]
        
        let viewController = storyboard?.instantiateViewController(withIdentifier: "viewer")
        self.navigationController?.pushViewController(viewController!, animated: true)
    }
}
