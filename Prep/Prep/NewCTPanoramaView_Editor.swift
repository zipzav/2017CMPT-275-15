//  File: NewCTPanoramaView.swift
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
import CoreMotion
import ImageIO
import AVFoundation
import AVKit
import SpriteKit
//import SCNSceneRenderer
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

import MobileCoreServices
import AssetsLibrary

func CGPointToSCNVector3(view: SCNView, depth: Float, point: CGPoint) -> SCNVector3 {
    let projectedOrigin = view.projectPoint(SCNVector3Make(0, 0, depth))
    let locationWithz   = SCNVector3Make(Float(point.x), Float(point.y), projectedOrigin.z)
    return view.unprojectPoint(locationWithz)
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}

func * (left: SCNVector3, right: SCNVector3) -> CGFloat {
    return CGFloat(left.x * right.x + left.y * right.y + left.z * right.z)
}

let radius: CGFloat = 20

@objc public class NewCTPanoramaView_Editor: UIView, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var move_Flag = false
    var mark : SCNNode? = nil
    var selection:SCNHitTestResult? = nil
    var hitOld = SCNVector3Zero
    var buttonToEditIndex = 0
    // MARK: Public properties
    
    public var panSpeed = CGPoint(x: 0.005, y: 0.005)
    public var image: UIImage? {
        didSet {
            panoramaType = panoramaTypeForCurrentImage
        }
    }
    public var overlayView: UIView? {
        didSet {
            replace(overlayView: oldValue, with: overlayView)
        }
    }
    public var panoramaType: CTPanoramaType = .cylindrical {
        didSet {
            createGeometryNode()
            resetCameraAngles()
        }
    }
    public var controlMethod: CTPanoramaControlMethod! {
        didSet {
            switchControlMethod(to: controlMethod!)
            resetCameraAngles()
        }
    }
    public var compass: CTPanoramaCompass?
    public var movementHandler: ((_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat) -> ())?
    
    // MARK: Private properties

    private let sceneView = SCNView()
    private let scene = SCNScene()
    private let motionManager = CMMotionManager()
    private var geometryNode: SCNNode?
    private var buttonLocations:[SCNVector3] = [SCNVector3]()
    public var nextbuttonLocations:SCNVector3 = SCNVector3Make(0, 0, 0)
    private var buttonActions: [String?] = [String]() //array to keep buttons' corresponding action items(video, sound)
    private var buttonNodes: [SCNNode] = [SCNNode]() //array to keep made button Node
    public var buttonPressedFlag:[Bool] = [Bool]()
    private var prevLocation = CGPoint.zero
    private var prevBounds = CGRect.zero
    private var prevLocation_move: SCNVector3 = SCNVector3Make(0, 0, 0)
    private var oldpoint = SCNVector3Make(0, 0, 0)
    private lazy var cameraNode: SCNNode? = {
        let node = SCNNode()
        let camera = SCNCamera()
        camera.yFov = 70
        node.camera = camera
        return node
    }()
    private var recordVideo = false
    private var nextButton: SCNNode? = nil
    private lazy var fovHeight: CGFloat = {
        return CGFloat(tan(self.cameraNode!.camera!.yFov/2 * .pi / 180.0)) * 2 * radius
    }()
    
    private var xFov: CGFloat {
        return CGFloat(self.cameraNode!.camera!.yFov) * self.bounds.width / self.bounds.height
    }
    
    private var panoramaTypeForCurrentImage: CTPanoramaType {
        if let image = image {
            if image.size.width / image.size.height == 2 {
                return .spherical
            }
        }
        return .cylindrical
    }
    
    //MARK: Class lifecycle methods
    public func setButtonInfo(location:[SCNVector3], action:[String?]){
        buttonLocations = location
        buttonActions = action
    }
    //Initialize Tap Gesture Recognizer to capture button taps
    public func initialize_tap(){
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleButtonTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.addTarget(self, action: #selector(NewCTPanoramaView.handleButtonTap(_:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    //Handles the button tap events and excecutes corresponding trigger
    @objc func handleButtonTap(_ gestureReconizer: UITapGestureRecognizer){
        let location = gestureReconizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            let result = hitResults[0]
            let node = result.node
            if(node != geometryNode && node != nextButton){
                for index in 0...buttonNodes.count-1{
                    if (buttonNodes[index] == node){
                        buttonToEditIndex = index
                        let sheet = UIAlertController(title: "Options", message: "Please Choose an Option", preferredStyle: .actionSheet)
                        let MoveButton = UIAlertAction(title: "Move", style: .default) { (action) in
                            self.move_Flag = true
                            self.selection = result
                        }
                        let PlayButton = UIAlertAction(title: "Play", style: .default) { (action) in
                            self.move_Flag = false
                            self.buttonPressedFlag[index] = true
                            let urlStr = self.buttonActions[index]
                            let url = NSURL(string: urlStr!)
                            ExperienceViewController().Video(movieUrl: url as! URL)
                        }
                        let DeleteButton = UIAlertAction(title: "Delete", style: .default) { (action) in
                            self.move_Flag = false
                            node.removeFromParentNode()
                            self.buttonLocations.remove(at: index)
                            self.buttonActions.remove(at: index)
                            self.buttonNodes.remove(at: index)
                            
                            var loop_index = 0
                            var newButton_array: Array<[String: Any]> = []
                            for button in self.buttonLocations{
                                newButton_array.append(["action" : self.buttonActions[loop_index], "locationx": button.x, "locationy": button.y, "locationz": button.z])
                                loop_index += 1
                            }
                            GlobalRef?.child("user").child((Auth.auth().currentUser?.uid)!).child(GlobalCurrentExperienceID!).child((GlobalCurrentPanorama?.getId())!).child("button").setValue(newButton_array)
                            
                        }
                        let backToHome = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        sheet.addAction(MoveButton)
                        sheet.addAction(PlayButton)
                        sheet.addAction(DeleteButton)
                        sheet.addAction(backToHome)
                        
                        let popOver = sheet.popoverPresentationController
                        popOver?.sourceView = self
                        //popOver?.sourceRect = (collectionView.cellForItem(at: indexPath!)?.bounds)!
                        popOver?.permittedArrowDirections = UIPopoverArrowDirection.any
                        
                        var topController = UIApplication.shared.keyWindow?.rootViewController
                        while let presentedViewController = topController?.presentedViewController {
                            topController = presentedViewController
                        }
                        topController?.present(sheet, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    //Creates the buttons of the current panorama and sets them in 3d space and links the proper audio/video files
    public func addButtons(){
        buttonPressedFlag = [Bool]()
        buttonNodes = [SCNNode]()
        for index in 0..<buttonLocations.count{
            //let newNode: SCNNode = SCNNode(buttonLocations[index])
            let geometry:SCNPlane = SCNPlane(width: 1, height: 1)
            
            geometry.firstMaterial?.diffuse.contents = UIImage(named: "Button1")
            geometry.firstMaterial?.isDoubleSided = true;
            
            let newNode:SCNNode = SCNNode()
            newNode.geometry = geometry
            newNode.position = buttonLocations[index]
            let it = SCNLookAtConstraint(target: cameraNode)
            it.isGimbalLockEnabled = true
            newNode.constraints = [it]
            buttonNodes += [newNode]

            scene.rootNode.addChildNode(newNode)
            buttonPressedFlag += [false]
        }
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public convenience init(frame: CGRect, image: UIImage) {
        self.init(frame: frame)
        ({self.image = image})() // Force Swift to call the property observer by calling the setter from a non-init context
    }
    
    deinit {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    private func commonInit() {
        add(view: sceneView)
        
        scene.rootNode.addChildNode(cameraNode!)
        
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black
        
        if controlMethod == nil {
            controlMethod = .motion
        }
    }
    
    // MARK: Configuration helper methods
    
    //Creats the panoramic sphere/cylinder of the current panorama
    private func createGeometryNode() {
        guard let image = image else {return}
        //delete buttons and panorama from scene
        for node in buttonNodes{
            node.removeFromParentNode()
        }
        geometryNode?.removeFromParentNode()
        
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.diffuse.mipFilter = .nearest
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .repeat
        material.cullMode = .front
        
        if panoramaType == .spherical {
            let sphere = SCNSphere(radius: radius)
            sphere.segmentCount = 300
            sphere.firstMaterial = material
            
            let sphereNode = SCNNode()
            sphereNode.geometry = sphere
            geometryNode = sphereNode
        }
        else {
            let tube = SCNTube(innerRadius: radius, outerRadius: radius, height: fovHeight)
            tube.heightSegmentCount = 50
            tube.radialSegmentCount = 300
            tube.firstMaterial = material
            
            let tubeNode = SCNNode()
            tubeNode.geometry = tube
            geometryNode = tubeNode
        }
        scene.rootNode.addChildNode(geometryNode!)
    }
    
    private func replace(overlayView: UIView?, with newOverlayView: UIView?) {
        overlayView?.removeFromSuperview()
        guard let newOverlayView = newOverlayView else {return}
        add(view: newOverlayView)
    }
    
    private func switchControlMethod(to method: CTPanoramaControlMethod) {
        sceneView.gestureRecognizers?.removeAll()
        
        if method == .touch {
            let panGestureRec = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panRec:)))
            sceneView.addGestureRecognizer(panGestureRec)
            initialize_tap()
            
            if motionManager.isDeviceMotionActive {
                motionManager.stopDeviceMotionUpdates()
            }
        }
        else {
            initialize_tap()
            guard motionManager.isDeviceMotionAvailable else {return}
            motionManager.deviceMotionUpdateInterval = 0.015
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: OperationQueue.main, withHandler: {[weak self] (motionData, error) in
                guard let panoramaView = self else {return}
                guard panoramaView.controlMethod == .motion else {return}
                
                guard let motionData = motionData else {
                    print("\(error?.localizedDescription)")
                    panoramaView.motionManager.stopDeviceMotionUpdates()
                    return
                }
                
                let rm = motionData.attitude.rotationMatrix
                var userHeading = .pi - atan2(rm.m32, rm.m31)
                userHeading += .pi/2
                
                if panoramaView.panoramaType == .cylindrical {
                    panoramaView.cameraNode!.eulerAngles = SCNVector3Make(0, Float(-userHeading), 0) // Prevent vertical movement in a cylindrical panorama
                }
                else {
                    // Use quaternions when in spherical mode to prevent gimbal lock
                    panoramaView.cameraNode!.orientation = motionData.orientation()
                }
                panoramaView.reportMovement(CGFloat(userHeading), panoramaView.xFov.toRadians())
                
            })
        }
    }
    
    private func resetCameraAngles() {
        cameraNode!.eulerAngles = SCNVector3Make(0, 0, 0)
        self.reportMovement(0, xFov.toRadians(), callHandler: false)
    }
    
    private func reportMovement(_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat, callHandler: Bool = true) {
        compass?.updateUI(rotationAngle: rotationAngle, fieldOfViewAngle: fieldOfViewAngle)
        if callHandler {
            movementHandler?(rotationAngle, fieldOfViewAngle)
        }
    }
    
    // MARK: Gesture handling
    @objc private func handlePan(panRec: UIPanGestureRecognizer) {
        if(self.move_Flag == false){
            if panRec.state == .began {
                prevLocation = CGPoint.zero
            }
            else if panRec.state == .changed {
                var modifiedPanSpeed = panSpeed
            
                if panoramaType == .cylindrical {
                    modifiedPanSpeed.y = 0 // Prevent vertical movement in a cylindrical panorama
                }
            
                let location = panRec.translation(in: sceneView)
                let orientation = cameraNode!.eulerAngles
                var newOrientation = SCNVector3Make(orientation.x + Float(location.y - prevLocation.y) * Float(modifiedPanSpeed.y),
                                                orientation.y + Float(location.x - prevLocation.x) * Float(modifiedPanSpeed.x),
                                                orientation.z)
            
                if controlMethod == .touch {
                    newOrientation.x = max(min(newOrientation.x, 1.1),-1.1)
                }
            
                cameraNode!.eulerAngles = newOrientation
                prevLocation = location
            
                reportMovement(CGFloat(-cameraNode!.eulerAngles.y), xFov.toRadians())
            }
        }
        else{ //When we are moving the buttons
            if panRec.state == .began {
                let mouse   = panRec.translation(in:sceneView)
                mark = selection!.node.clone()
                
                let geometry:SCNPlane = SCNPlane(width: 1, height: 1)
                geometry.firstMaterial?.diffuse.contents = UIImage(named: "Button1")
                geometry.firstMaterial?.isDoubleSided = true;
                
                mark!.geometry = geometry
                mark!.opacity = 0.80
                //mark!.position = selection!.node.position
                mark!.position = sceneView.unprojectPoint(SCNVector3(x: Float(mouse.x*1.4), y: Float(mouse.y*1.4), z: 0.8))
                print(mark!.position)
                print(selection!.node.position)
            
                scene.rootNode.addChildNode(mark!)
                print("Initial points:")
                print(mark!.position)
            }
            else if (panRec.state == .changed){

                let mouse   = panRec.translation(in:sceneView)
                var point = sceneView.unprojectPoint(SCNVector3(x: Float(mouse.x*1.4), y: Float(mouse.y*1.4), z: 0.8))
                mark!.position = point
                print("New Point: ")
                print( mark!.position)
            }
            else if (panRec.state == .ended){
                selection!.node.position = mark!.position
                buttonLocations[buttonToEditIndex].x = selection!.node.position.x
                buttonLocations[buttonToEditIndex].y = selection!.node.position.y
                buttonLocations[buttonToEditIndex].z = selection!.node.position.z
                //selection!.node.convertPosition(mark!.position, from: selection!.node)
                mark!.removeFromParentNode()
                selection = nil
                mark = nil
                move_Flag = false

                
                //Remove Old Button
                let E2_button1 = ["action" : buttonActions[buttonToEditIndex], "locationx": buttonLocations[buttonToEditIndex].x, "locationy": buttonLocations[buttonToEditIndex].y, "locationz": buttonLocations[buttonToEditIndex].z ] as [String : Any]
                GlobalRef?.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).child((GlobalCurrentPanorama?.key)!).child("button").child(String(buttonToEditIndex)).updateChildValues(E2_button1)
                //ref.child("user").child(GlobalUserID!).child(GlobalCurrentExperienceID!).child((GlobalCurrentPanorama?.key)!).child("button").child(String(buttonToEditIndex)).removeValue()
                //Add New Button
                //Add New Button

            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width != prevBounds.size.width || bounds.size.height != prevBounds.size.height {
            sceneView.setNeedsDisplay()
            reportMovement(CGFloat(-cameraNode!.eulerAngles.y), xFov.toRadians(), callHandler: false)
        }
    }
    
    //MARK: BUTTON UPLOAD BUTTONS
    public func Add_Video(){
        recordVideo = true
        let picker = UIImagePickerController()
        
        // Configure ImagePickerController
        picker.sourceType = .photoLibrary // Assume photo sphere is stiched up by another app so didn't
        picker.delegate = self
        picker.allowsEditing = true
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.modalPresentationStyle = .overCurrentContext // keep the screen in landscape mode
        //picker.mediaTypes
        
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        topController?.present(picker, animated: true, completion:nil)
        
    }
    public func Add_Sound(){
        recordVideo = false
        let picker = UIImagePickerController()
        
        // Configure ImagePickerController
        picker.sourceType = .photoLibrary // Assume photo sphere is stiched up by another app so didn't
        picker.delegate = self
        picker.allowsEditing = true
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.modalPresentationStyle = .overCurrentContext // keep the screen in landscape mode
        //picker.mediaTypes
        
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        topController?.present(picker, animated: true, completion:nil)
    }
    
   public func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
    
    if (recordVideo == true){
        if let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL {
            let videoUploadManager = UploadManager()
            let videoPath = Constants.Exp.userPath + "/" + "\(Int(Date.timeIntervalSinceReferenceDate * 1000)).mp4"
        
            videoUploadManager.uploadVideo(videoURL, path: videoPath, progressBlock: { (percentage) in
                print(percentage)
            }, completionBlock: { [weak self] (fileURL, errorMessage) in
                guard let strongself = self else {return}
                // Handle Error
                if let error = errorMessage {
                    print("Error uploading: \(error)")
                    //self.urlTextView.text = "Upload Failed"
                    return
                }
                // Handle fileURL by real time database
                self?.uploadSuccess(fileURL!)
        })
        }
    }
    else { //audio recording
        let audioUploadManager = UploadManager()
        let url = info[UIImagePickerControllerMediaURL] as? NSURL
        let asset = AVURLAsset(url: url as! URL)
        //let newurl = Bundle.url(forResource: "temp", ofType: "m4a")
        let audioPath = "\(Int(Date.timeIntervalSinceReferenceDate * 1000)).m4a"
        let newurl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(audioPath) as NSURL
        
        asset.writeAudioTrackToURL(URL: newurl, completion: { (success, error) -> () in
            if !success {
                print(error)
            }
        }
        )
        let videoPath = Constants.Exp.userPath + "/" + audioPath
        
        audioUploadManager.uploadAudio(newurl, path: videoPath, progressBlock: { (percentage) in
            print(percentage)
        }, completionBlock: { [weak self] (fileURL, errorMessage) in
            guard let strongself = self else {return}
            // Handle Error
            if let error = errorMessage {
                print("Error uploading: \(error)")
                //self.urlTextView.text = "Upload Failed"
                return
            }
            // Handle fileURL by real time database
            self?.uploadSuccess(fileURL!)
    })
    }
    }

    
func uploadSuccess(_ fileURL: URL) {
    if let uid = Auth.auth().currentUser?.uid {
        // Photo uploaded to firebase storage, now add image URL to realtime database
        print("Upload Succeeded!")

        let button1 = ["action" : fileURL.absoluteString, "locationx": 5, "locationy": 0, "locationz": -5] as [String : Any]
        
                let panoindex = GlobalCurrentPanoramaIndex_Edit
        let panorama = GlobalCurrentExperience?.panoramas[panoindex] as! Panorama
        let numButts = String(buttonLocations.count)
        let uid = Auth.auth().currentUser?.uid
        GlobalRef?.child("user").child(uid!).child(GlobalCurrentExperienceID as! String).child(panorama.getId()).child("button").child(numButts).setValue(button1)
        
        //ADD NEW BUTTON
        let new_button = SCNVector3(x:6, y:0, z:-5)
        buttonLocations.append(new_button)
        buttonActions.append(fileURL.absoluteString)
        let geometry:SCNPlane = SCNPlane(width: 1, height: 1)
        geometry.firstMaterial?.diffuse.contents = UIImage(named: "Button1")
        geometry.firstMaterial?.isDoubleSided = true;
        
        let newNode:SCNNode = SCNNode()
        newNode.geometry = geometry
        newNode.position = buttonLocations[buttonLocations.count-1]
        let it = SCNLookAtConstraint(target: cameraNode)
        it.isGimbalLockEnabled = true
        newNode.constraints = [it]
        buttonNodes += [newNode]
        
        scene.rootNode.addChildNode(newNode)
        buttonPressedFlag += [false]
    }
    }
}

fileprivate extension CMDeviceMotion {
    func orientation() -> SCNVector4 {
        
        let attitude = self.attitude.quaternion
        let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
        
        var result: SCNVector4
        
        switch UIApplication.shared.statusBarOrientation {
            
        case .landscapeRight:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(.pi/2, 0, 1, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            var q = GLKQuaternionMultiply(cq1, aq)
            q = GLKQuaternionMultiply(cq2, q)
            
            result = SCNVector4(x: -q.y, y: q.x, z: q.z, w: q.w)
            
        case .landscapeLeft:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 0, 1, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            var q = GLKQuaternionMultiply(cq1, aq)
            q = GLKQuaternionMultiply(cq2, q)
            
            result = SCNVector4(x: q.y, y: -q.x, z: q.z, w: q.w)
            
        case .portraitUpsideDown:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1)
            var q = GLKQuaternionMultiply(cq1, aq)
            q = GLKQuaternionMultiply(cq2, q)
            
            result = SCNVector4(x: -q.x, y: -q.y, z: q.z, w: q.w)
            
        case .unknown:
            fallthrough
        case .portrait:
            let cq = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            result = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
        }
        return result
    }
}

fileprivate extension UIView {
    func add(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let views = ["view": view]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
    }
}

fileprivate extension FloatingPoint {
    func toDegrees() -> Self {
        return self * 180 / .pi
    }
    
    func toRadians() -> Self {
        return self * .pi / 180
    }
}

class Tab_Editor_NewClass : UITabBar {
    
}

extension AVAsset {
    
    func writeAudioTrackToURL(URL: NSURL, completion: @escaping (Bool, NSError?) -> ()) {
        
        do {
            
            let audioAsset = try self.audioAsset()
            audioAsset.writeToURL(URL: URL, completion: completion)
            
        } catch (let error as NSError){
            
            completion(false, error)
            
        } catch {
            
            print("error")
        }
    }
    
    func writeToURL(URL: NSURL, completion: @escaping (Bool, NSError?) -> ()) {
        
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, nil)
            return
        }
        
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL      = URL as URL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                completion(false, nil)
            }
        }
    }
    
    func audioAsset() throws -> AVAsset {
        
        let composition = AVMutableComposition()
        
        let audioTracks = tracks(withMediaType: AVMediaType.audio)
        
        for track in audioTracks {
            
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack?.preferredTransform = track.preferredTransform
        }
        return composition
    }
}



