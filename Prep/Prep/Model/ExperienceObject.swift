//  File: ExperienceObject.swift
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

import Foundation
import UIKit
import SceneKit

class Experience{
    var name:String
    var description:String
    var panoramas: [Panorama] //Each Experience has an Array to hold all its Panorama
    var key:String // unique id in database
    
    init (Name:String, Description:String, Id: String){
        name = Name
        description = Description
        key = Id
        panoramas = [Panorama]()//Empty
    }
    func addPanorama(newPanorama:Panorama){
        panoramas.append(newPanorama)
    }
    func addPanorama(newImage:UIImage,Id:String) {
        let newPanorama:Panorama = Panorama(Image:newImage, Id: Id)
        panoramas.append(newPanorama)
    }
    func getPanorama(index:Int)->UIImage{
        return panoramas[index].image
    }
    func numPanorama()-> Int{
        return panoramas.count
    }
    func getTitle()->String{
        return name
    }
    func getDescription()->String{
        return description
    }
    func getId()->String{
        return key
    }
    func setTitle(newtitle: String){
        name = newtitle
    }
    func setDescription(newDescription: String){
        description = newDescription
    }
    func setId(newId: String){
        key = newId
    }
}

class Panorama{
    var image:UIImage
    var buttonLocation: [SCNVector3] //the index between buttonLocation and Button object should match, does not include the next panorama button
    var buttonObject : [String?]
    var buttonsPressed : Int //A counter? You could probably check how many buttons there are in buttonObect Array and compare against this value
    var nextPanoramaButtonLocation: SCNVector3
    var key :String
    
    init(Image:UIImage, Id:String){
        image = Image
        buttonsPressed = 0
        buttonLocation = [SCNVector3]()
        buttonObject = [String?]()
        nextPanoramaButtonLocation = SCNVector3Make(0, 0, 0)
        key = Id
    }
    func addButton(newButtonLocation:SCNVector3,newObject:String?){
        buttonLocation.append(newButtonLocation)
        buttonObject.append(newObject)
    }
    func addNextPanoramaButton(nextButtonLocation:SCNVector3){
        nextPanoramaButtonLocation=nextButtonLocation
    }
    func getImage()->UIImage{
        return image
    }
    func setId(newId: String){
        key = newId
    }
    func getId()->String{
        return key
    }
    
}
