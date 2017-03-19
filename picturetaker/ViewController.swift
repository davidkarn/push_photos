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
    var image : UIImage?

    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var image_view: UIImageView!
    @IBOutlet weak var picture_button: UIButton!


    func message_form_data(_ boundary:String,
                           parameters: [String: String]?) -> Data {
        var body = Data()

        if parameters != nil {
            for (key, value) in parameters! {
                body.append(Data("--\(boundary)\r\n".utf8))
                body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
                body.append(Data("\(value)\r\n".utf8)) }}

        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpeg\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        let image_data = UIImageJPEGRepresentation(self.image!, 0.85)
        body.append(image_data!)
        body.append(Data("\r\n".utf8))

        body.append(Data("--\(boundary)--\r\n".utf8))

        print("payload here:")
        print(parameters)
        print(String(describing: body))
        print(body)

        return body as Data}

    func generate_boundary() -> String {
        return "Boundary-\(UUID().uuidString)" }


    func post_photo(
        _ completion_handler: @escaping (URLResponse?, Data?, Error?) -> Void) {
        print("pressed post message in")
        let url        : String   = "https://google.com/post_image"
        let request               = NSMutableURLRequest()

        request.url = URL(string: url)
        request.httpMethod = "PUT"

        let location = get_location_object()

        let boundary = generate_boundary()
        let fullData = message_form_data(
            boundary,
            parameters: location)

        request.setValue("multipart/form-data; boundary=" + boundary,
                         forHTTPHeaderField: "Content-Type")
        // REQUIRED!
        request.setValue(String(fullData.count), forHTTPHeaderField: "Content-Length")

        request.httpBody                = fullData
        request.httpShouldHandleCookies = true

        let queue:OperationQueue       = OperationQueue()

        NSURLConnection.sendAsynchronousRequest(
            request as URLRequest,
            queue:               queue,
            completionHandler:   completion_handler as! (URLResponse?, Data?, Error?) -> Void) }

    @IBAction func take_picture_tapped(_ sender: Any) {
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in

        if sampleBuffer != nil {
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            let dataProvider = CGDataProvider(data: imageData as! CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
            let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
            self.image = image
            // ...
            // Add the image to captureImageView here...
            self.post_photo({(response: URLResponse?, data: Data?, error: Error?) -> Void in
                OperationQueue.main.addOperation {
                    print("got response", data)}})

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

    func get_location_object() -> [String: String] {
        if (locationManager.location == nil) {
            return [:] }
        var heading = ""
        if (locationManager.heading! != nil) {
            heading = String(locationManager.heading!.magneticHeading)
        }
        return ["altitude": String(locationManager.location!.altitude),
                "course":   String(locationManager.location!.course),
                "heading":   heading,
                "latitude": String(locationManager.location!.coordinate.latitude),
                "longitude": String(locationManager.location!.coordinate.longitude),
                "floor": String(locationManager.location!.floor != nil ? String(locationManager.location!.floor!.level) : "")]}

    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds        = UIScreen.main.bounds
        preview.frame = CGRect(x: 0, y: 0, width: bounds.width, height:bounds.height - 100)
        picture_button.frame = CGRect(x: 30, y: bounds.height - 70, width: bounds.width / 2,height: 70)

        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }

        load_camera() }

    func load_camera() {
        print("loading camera")
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera

        present(imagePicker, animated: true, completion: nil)

    }

}

