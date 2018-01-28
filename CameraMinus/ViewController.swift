//
//  ViewController.swift
//  CameraMinus
//
//  Created by Ryan Larsen on 4/15/17.
//  Copyright © 2017 Ryan Larsen. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
//    private var myDev : AVCaptureDevice?
    private var currentCameraPosition = AVCaptureDevice.Position.back
    private let session = AVCaptureSession()
    private var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var defaultVideoDevice: AVCaptureDevice?
    
    @IBOutlet private var previewView: UIView!
    override func viewDidLoad() {
        // If we find a device we'll store it here for later use
        
        // Choose the back dual camera if available, otherwise default to a wide angle camera.
        if let dualCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back){
            defaultVideoDevice = dualCameraDevice
        }
        else if let backCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) {
            // If the back dual camera is not available, default to the back wide angle camera.
            defaultVideoDevice = backCameraDevice
        }
        else if let frontCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front) {
            // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
            defaultVideoDevice = frontCameraDevice
        }
        let tapRec = UITapGestureRecognizer(target: self, action: #selector(tappedView)) //_:
        previewView.addGestureRecognizer(tapRec)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        startDeviceDisplay(device: defaultVideoDevice!, rotation: AVCaptureVideoOrientation.portrait)
    }
    
    @IBOutlet var screenTap: UITapGestureRecognizer!
    
    @objc func tappedView() { //_ sender: UITapGestureRecognizer
        if let nextCamera = selectNextCamera(){
            startDeviceDisplay(device: nextCamera, rotation: AVCaptureVideoOrientation.portrait)
        }
    }
    
    private var nCamera = 0;
    func selectNextCamera() -> AVCaptureDevice?{
        let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera,AVCaptureDevice.DeviceType.builtInDualCamera],
            mediaType: AVMediaType.video,
            position: AVCaptureDevice.Position.unspecified)
            // Since we look at the count here again, we don't have to worry about the length of the list of devices changing (is that even possible?)
            nCamera = (nCamera + 1) % deviceDescoverySession.devices.count
            return deviceDescoverySession.devices[nCamera]
//        return defaultVideoDevice
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let deviceOrientation = UIDevice.current.orientation
        guard let _ = deviceOrientation.videoOrientation, deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
            return
        }
        
        coordinator.animateAlongsideTransition(in: nil,animation: {
            (UIViewControllerTransitionCoordinatorContext) in
            let deltaTransform = coordinator.targetTransform
            let deltaAngle = atan2f(Float(deltaTransform.b), Float(deltaTransform.a))
            var currentRotation : Float = ((self.previewView!.layer.value(forKeyPath: "transform.rotation.z") as AnyObject).floatValue)!
            // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
            currentRotation += -1 * deltaAngle + 0.0001;
            self.previewView!.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
            self.previewView!.layer.frame = self.view.bounds}, completion: {
                (UIViewControllerTransitionCoordinatorContext) in
                // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
                var currentTransform : CGAffineTransform = self.previewView!.transform
                currentTransform.a = round(currentTransform.a)
                currentTransform.b = round(currentTransform.b)
                currentTransform.c = round(currentTransform.c)
                currentTransform.d = round(currentTransform.d)
                self.previewView!.transform = currentTransform
        })
        
        /* First Verse */
//        coordinator.animateAlongsideTransition(in: nil,animation: { context in
//            switch newVideoOrientation {
//            case .portrait:
//                self.videoPreviewLayer.setAffineTransform(CGAffineTransform(rotationAngle: 0.0))
//                break
//            case .landscapeLeft:
//                self.videoPreviewLayer.setAffineTransform(CGAffineTransform(rotationAngle: .pi/2))
//                break
//            case .landscapeRight:
//                self.videoPreviewLayer.setAffineTransform(CGAffineTransform(rotationAngle: -.pi/2))
//                break
//            default:
//                break
//            }
//            self.videoPreviewLayer.frame = CGRect(origin: CGPoint(x: size.width / 2, y: size.height / 2), size: size)
//            self.videoPreviewLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
//            context.viewController(forKey: UITransitionContextViewControllerKey.from)
//        }, completion: nil)
//        videoPreviewLayer.removeAllAnimations()
        /* Second Verse */
//        self.videoPreviewLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        self.videoPreviewLayer.connection.videoOrientation = newVideoOrientation
//        self.videoPreviewLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        self.videoPreviewLayer.bounds = CGRect(origin: CGPoint(x: size.width / 2, y: size.height / 2), size: size)
    }

    func startDeviceDisplay(device : AVCaptureDevice, rotation : AVCaptureVideoOrientation){
        let sessionOutput = AVCapturePhotoOutput()
        do {
            for input in session.inputs {
                // Remove any previous capture inputs
                session.removeInput(input)
            }
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input){
                session.addInput(input)
                if session.canAddOutput(sessionOutput) {
                    session.addOutput(sessionOutput)
                    session.startRunning()
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                    videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    videoPreviewLayer.position = CGPoint(x: self.previewView.frame.width / 2, y: self.previewView.frame.height / 2)
                    videoPreviewLayer.bounds = previewView.frame
                    previewView.layer.addSublayer(videoPreviewLayer)
                }
            }
        }
        catch {
            print("Ryan is cool? :( Not really.")
        }
    }

    
    private func maxResolutionPreset() -> String {
        let allSessionPresets = [AVCaptureSession.Preset.high,
                                 AVCaptureSession.Preset.photo,
                                 AVCaptureSession.Preset.hd4K3840x2160,
                                 AVCaptureSession.Preset.hd1920x1080,
                                 AVCaptureSession.Preset.hd1280x720,
                                 AVCaptureSession.Preset.iFrame1280x720,
                                 AVCaptureSession.Preset.medium,
                                 AVCaptureSession.Preset.iFrame960x540,
                                 AVCaptureSession.Preset.vga640x480,
                                 AVCaptureSession.Preset.low,
                                 AVCaptureSession.Preset.cif352x288]
        
        for sessionPreset in allSessionPresets {
            if session.canSetSessionPreset(sessionPreset) {
                return sessionPreset.rawValue
            }
        }
        
        return AVCaptureSession.Preset.high.rawValue
    }
    
//    func getDevice(discoverySession : AVCaptureDeviceDiscoverySession, devicePosition : AVCaptureDevicePosition) -> AVCaptureDevice{
//        for device in discoverySession.devices{
//            if device.position == devicePosition{
//                return device
//            }
//        }
//        return discoverySession.devices[0] //Return the first camera
//    }
    
    /********************* 1. Sessions *************************/
//    private enum SessionSetupResult {
//        case success
//        case notAuthorized
//        case configurationFailed
//    }
//    
//    private let session = AVCaptureSession()
//    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
//    private var isSessionRunning = false
//    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.
//    private var setupResult: SessionSetupResult = .success
//    
//    var videoDeviceInput: AVCaptureDeviceInput!
//    
//    // Call this on the session queue.
//    private func configureSession() {
//        if self.setupResult != .success {
//            return
//        }
//        
//        session.beginConfiguration()
//        
//        // Add video input.
//        do {
//            var defaultVideoDevice: AVCaptureDevice?
//            // Choose the back dual camera if available, otherwise default to a wide angle camera.
//            if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDualCamera, mediaType: AVMediaTypeVideo, position: .back) {
//                defaultVideoDevice = dualCameraDevice
//            }
//            else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
//                // If the back dual camera is not available, default to the back wide angle camera.
//                defaultVideoDevice = backCameraDevice
//            }
//            else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
//                // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
//                defaultVideoDevice = frontCameraDevice
//            }
//            
//            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
//            
//            if session.canAddInput(videoDeviceInput) {
//                session.addInput(videoDeviceInput)
//                self.videoDeviceInput = videoDeviceInput
//                
//                DispatchQueue.main.async {
//                    /*
//                     Why are we dispatching this to the main queue?
//                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
//                     can only be manipulated on the main thread.
//                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
//                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
//                     
//                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
//                     handled by CameraViewController.viewWillTransition(to:with:).
//                     */
//                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
//                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
//                    if statusBarOrientation != .unknown {
//                        if let videoOrientation = statusBarOrientation.videoOrientation {
//                            initialVideoOrientation = videoOrientation
//                        }
//                    }
//                    self.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation
//                }
//            }
//            else {
//                print("Could not add video device input to the session")
//                setupResult = .configurationFailed
//                session.commitConfiguration()
//                return
//            }
//        }
//        catch {
//            print("Could not create video device input: \(error)")
//            setupResult = .configurationFailed
//            session.commitConfiguration()
//            return
//        }
//        
//        session.commitConfiguration()
//    }
    
//    override func viewDidLoad() {
//        
//        /********************* 2. Permission *************************/
//        super.viewDidLoad()
//        /*
//         Check video authorization status. Video access is required and audio
//         access is optional. If audio access is denied, audio is not recorded
//         during movie recording.
//         */
//        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
//            case .authorized:
//                // The user has previously granted access to the camera.
//                break
//            case .notDetermined:
//                /*
//                 The user has not yet been presented with the option to grant
//                 video access. We suspend the session queue to delay session
//                 setup until the access request has completed.
//                 */
//                sessionQueue.suspend()
//                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
//                    if !granted {
//                        self.setupResult = .notAuthorized
//                    }
//                    self.sessionQueue.resume()
//                })
//            default:
//                // The user has previously denied access.
//                setupResult = .notAuthorized
//        }
//        // Do any additional setup after loading the view, typically from a nib.
//        session.sessionPreset = maxResolutionPreset() //AVCaptureSessionPresetLow
//        
//        changeCamera()
//    }
    
//    func sessionRuntimeError(notification: NSNotification) {
//        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else { return }
//        
//        let error = AVError(_nsError: errorValue)
//        print("Capture session runtime error: \(error)")
//        
//        /*
//         Automatically try to restart the session running if media services were
//         reset and the last start running succeeded. Otherwise, enable the user
//         to try to resume the session running.
//         */
//        if error.code == .mediaServicesWereReset {
//            sessionQueue.async { [unowned self] in
//                if self.isSessionRunning {
//                    self.session.startRunning()
//                    self.isSessionRunning = self.session.isRunning
//                }
//            }
//        }
//    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

//    func changeCamera() {
//        
//        DispatchQueue.main.async { [unowned self] in
//            let currentVideoDevice = self.videoDeviceInput.device
//            let currentPosition = currentVideoDevice!.position
//            
//            let preferredPosition: AVCaptureDevicePosition
//            let preferredDeviceType: AVCaptureDeviceType
//            
//            switch currentPosition {
//            case .unspecified, .front:
//                preferredPosition = .back
//                preferredDeviceType = .builtInDualCamera
//                
//            case .back:
//                preferredPosition = .front
//                preferredDeviceType = .builtInWideAngleCamera
//            }
//            let videoDeviceDiscoverySession = AVCaptureDeviceDiscoverySession.init(
//                        deviceTypes: [AVCaptureDeviceType.builtInDualCamera, AVCaptureDeviceType.builtInWideAngleCamera],
//                        mediaType: AVMediaTypeVideo,
//                        position: AVCaptureDevicePosition.unspecified)
//            let devices = videoDeviceDiscoverySession?.devices!
//            var newVideoDevice: AVCaptureDevice? = nil
//            
//            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
//            if let device = devices?.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
//                newVideoDevice = device
//            }
//            else if let device = devices?.filter({ $0.position == preferredPosition }).first {
//                newVideoDevice = device
//            }
//            
//            if let videoDevice = newVideoDevice {
//                do {
//                    let videoDeviceInput = try AVCaptureDeviceInput.init(device: videoDevice)
//                    
//                    self.session.beginConfiguration()
//                    
//                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
//                    self.session.removeInput(self.videoDeviceInput)
//                    
//                    /*
//                     When changing devices, a session preset that may be supported
//                     on one device may not be supported by another. To allow the
//                     user to successfully switch devices, we must save the previous
//                     session preset, set the default session preset (High), and
//                     attempt to restore it after the new video device has been
//                     added. For example, the 4K session preset is only supported
//                     by the back device on the iPhone 6s and iPhone 6s Plus. As a
//                     result, the session will not let us add a video device that
//                     does not support the current session preset.
//                     */
//                    let previousSessionPreset = self.session.sessionPreset
//                    self.session.sessionPreset = self.maxResolutionPreset() //AVCaptureSessionPresetHigh
//                    
//                    if self.session.canAddInput(videoDeviceInput) {
//                        self.session.addInput(videoDeviceInput)
//                        self.videoDeviceInput = videoDeviceInput
//                    }
//                    else {
//                        self.session.addInput(self.videoDeviceInput)
//                    }
//                    
//                    // Restore the previous session preset if we can.
//                    if self.session.canSetSessionPreset(previousSessionPreset) {
//                        self.session.sessionPreset = previousSessionPreset
//                    }
//                    
//                    self.session.commitConfiguration()
//                }
//                catch {
//                    print("Error occured while creating video device input: \(error)")
//                }
//            }
//            
//        }
//    }
}

extension AVCaptureDevice.DiscoverySession
{
    func uniqueDevicePositionsCount() -> Int {
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        
        for device in devices {
            if !uniqueDevicePositions.contains(device.position) {
                uniqueDevicePositions.append(device.position)
            }
        }
        
        return uniqueDevicePositions.count
    }
}

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}

