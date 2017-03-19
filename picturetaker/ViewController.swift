//
//  ViewController.swift
//  picturetaker
//
//  Created by David Karn on 3/18/17.
//  Copyright © 2017 webdever. All rights reserved.
//

import UIKit
import CoreLocation;
import AVFoundation;

class ViewController: UIViewController, CLLocationManagerDelegate,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate {
    let locationManager = CLLocationManager()
    var imagePicker: UIImagePickerController!

    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var image_view: UIImageView!
    @IBOutlet weak var picture_button: UIButton!

    @IBAction func take_picture_tapped(_ sender: Any) {
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in

        if sampleBuffer != nil {
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            let dataProvider = CGDataProvider(data: imageData as! CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
            let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
            // ...
            // Add the image to captureImageView here...

            self.image_view.image = image }})}}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("calling this")
//        imagePicker.dismiss(animated: true, completion: nil)
        image_view.image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }


        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSessionPresetPhoto
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            // ...
            // The remainder of the session setup will go here...
        }
        stillImageOutput = AVCaptureStillImageOutput()
//        stillImageOutput.settings.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

        if session!.canAddOutput(stillImageOutput) {
            session!.addOutput(stillImageOutput)
            // ...
            // Configure the Live Preview here...
        }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
        videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        preview.layer.addSublayer(videoPreviewLayer!)
        session!.startRunning()
        videoPreviewLayer!.frame = preview.bounds

    }

    func get_location_object() -> [String: AnyObject] {
        if (locationManager.location == nil) {
            return [:] }
        return ["altitude": locationManager.location!.altitude as AnyObject,
                "latitude": locationManager.location!.coordinate.latitude as AnyObject,
                "longitude": locationManager.location!.coordinate.longitude as AnyObject,
                "floor": locationManager.location!.floor != nil ? locationManager.location!.floor!.level as AnyObject : false as AnyObject] }

    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds        = UIScreen.main.bounds
        preview.frame = CGRect(x: 0, y: 0, width: bounds.width, height:bounds.height - 100)
        picture_button.frame = CGRect(x: 30, y: bounds.height - 70, width: bounds.width / 2,height: 70)

        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;

        load_camera() }

    func load_camera() {
        print("loading camera")
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera

        present(imagePicker, animated: true, completion: nil)

    }

}

