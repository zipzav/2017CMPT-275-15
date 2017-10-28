//
//  ExperienceObject.swift
//  Prep
//
//  Created by Zavier Patrick David Aguila on 10/28/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import Foundation
import UIKit


class Experience{
    var name:String
    var description:String
    var panoramas: [Panorama] //Each Experience has an Array to hold all its Panorama
    
    init (Name:String, Description:String){
        name = Name
        description = Description
        panoramas = [Panorama]()//Empty
    }
    func addPanorama(newPanorama:Panorama){
        panoramas.append(newPanorama)
    }
    func addPanorama(newImage:UIImage){
        var newPanorama:Panorama = Panorama(Image:newImage)
        panoramas.append(newPanorama)
    }
    func getPanorama(index:Int)->UIImage{
        return panoramas[index].image
    }
}
class Location{
    var x: Int
    var y: Int
    
    init(X: Int, Y:Int){
        x = X
        y = Y
    }
    
    func updateLocation(X: Int, Y:Int){
        x = X
        y = Y
    }
}
class Panorama{
    var image:UIImage
    var buttonLocation: [Location] //the index between buttonLocation and Button object should match, does not include the next panorama button
    var buttonObject : [Any]
    var buttonsPressed : Int //A counter? You could probably check how many buttons there are in buttonObect Array and compare against this value
    var nextPanoramaButtonLocation: [Location]
    
    init(Image:UIImage){
        image = Image
        buttonsPressed = 0
        buttonLocation = [Location]()
        buttonObject = [Any]()
        nextPanoramaButtonLocation = [Location]()
    }
    func addButton(newButtonLocation:Location,newObject:Any){
        buttonLocation.append(newButtonLocation)
        buttonObject.append(newObject)
    }
}
