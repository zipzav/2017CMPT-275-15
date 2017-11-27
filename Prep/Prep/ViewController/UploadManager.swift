//
//  UploadManager.swift
//  Prep
//
//  Created by sychung on 11/13/17.
//  Copyright © 2017 Zavier Patrick David Aguila. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

struct Constants {
    struct Exp {
        static let userPath = "user/\(Auth.auth().currentUser!.uid)"
    }
}

class UploadManager: NSObject {

    func uploadImage(_ image: UIImage, path: String, progressBlock: @escaping (_ percentage: Double)-> Void, completionBlock: @escaping (_ url: URL?, _ errorMessage: String?) -> Void) {
        let storage = Storage.storage()
        let storageReference = storage.reference()
        
        // storage/user/{user id}/{experience id}/image.jpeg
        let imagesReference = storageReference.child(path)
        if let imageData = UIImageJPEGRepresentation(image, 0.0) {
            let metaData = StorageMetadata()
            metaData.contentType = "images/jpeg"
            
            let uploadTask = imagesReference.putData(imageData, metadata: metaData, completion: { (metaData, error) in
                
                    if let metaData = metaData {
                        completionBlock(metaData.downloadURL(), nil) // Has meta, Return URL
                    } else {
                        completionBlock(nil, error?.localizedDescription)
                    }
                })
            uploadTask.observe(.progress, handler: { (snapshot) in
                guard let progress = snapshot.progress else {
                    return
                }
                let percentage = (Double(progress.completedUnitCount) / Double(progress.totalUnitCount)) * 100
                progressBlock(percentage)
            })
        }else {
            completionBlock(nil, "Image couldn't be converted to Data.")
        }
    }
    
}
