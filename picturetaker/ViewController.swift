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
import Mapbox;

class ViewController: UIViewController, CLLocationManagerDelegate,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate {
    let locationManager = CLLocationManager()
    var imagePicker: UIImagePickerController!
    var selected_location: CLLocationCoordinate2D!

    @IBOutlet weak var map_view: MGLMapView!
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var image : UIImage?

    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var image_view: UIImageView!
    @IBOutlet weak var picture_button: UIButton!
    @IBOutlet weak var submit_button: UIButton!

    @IBAction func submit_clicked(_ sender: Any) {
        self.post_photo({(response: URLResponse?, data: Data?, error: Error?) -> Void in
            OperationQueue.main.addOperation {
                print("got response", data)}})}

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
        map_view.isHidden = true
        picture_button.isHidden = false
        submit_button.isHidden = true
        print("pressed post message in")
        let url        : String   = "https://google.com/post_image"
        let request               = NSMutableURLRequest()

        request.url = URL(string: url)
        request.httpMethod = "PUT"

        let location = get_selected_location_object()

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
        self.test_location()
            self.image_view.image = image
                return;
            self.post_photo({(response: URLResponse?, data: Data?, error: Error?) -> Void in
                OperationQueue.main.addOperation {
                    print("got response", data)}}) }})}}


    func set_up_map() {
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        longPressRecogniser.minimumPressDuration = 1.0
        map_view.addGestureRecognizer(longPressRecogniser)
    }

    func handleLongPress(_ getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .began { return }

        let touchPoint = getstureRecognizer.location(in: map_view)
        let touchMapCoordinate = map_view.convert(touchPoint, toCoordinateFrom: map_view)


        let dropPin = MGLPointAnnotation()
        dropPin.coordinate = touchMapCoordinate
        dropPin.title = "User posted location"
        map_view.addAnnotation(dropPin)

        selected_location = touchMapCoordinate

        map_view.addAnnotation(dropPin)
    }

    func test_location() {
        map_view.isHidden = false
        submit_button.isHidden = false
        picture_button.isHidden = true

        if (map_view.annotations != nil) {
            map_view.removeAnnotations(map_view.annotations!) }
        let location = get_location_object()
        var camera = MGLMapCamera(lookingAtCenter:
        locationManager.location!.coordinate, fromDistance: CLLocationDistance(2.0), pitch: 1.0, heading: locationManager.heading!.magneticHeading)
        let dropPin = MGLPointAnnotation()
        dropPin.coordinate = locationManager.location!.coordinate
        selected_location = locationManager.location!.coordinate
        dropPin.title = "Is this location correct?"
        map_view.addAnnotation(dropPin)
        map_view.fly(to: camera) {
            print("flown", self.locationManager.location)
        }
    }
    

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

    func get_selected_location_object() -> [String: String] {
        if (locationManager.location == nil) {
            return [:] }
        var heading = ""
        if (locationManager.heading! != nil) {
            heading = String(locationManager.heading!.magneticHeading)
        }
        return ["altitude": String(locationManager.location!.altitude),
                "course":   String(locationManager.location!.course),
                "heading":   heading,
                "latitude": String(selected_location!.latitude),
                "longitude": String(selected_location!.longitude),
                "floor": String(locationManager.location!.floor != nil ? String(locationManager.location!.floor!.level) : "")]}

    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds        = UIScreen.main.bounds
        preview.frame = CGRect(x: 0, y: 0, width: bounds.width, height:bounds.height - 100)
        map_view.frame = CGRect(x: 0, y: 0, width: bounds.width, height:bounds.height - 100)

        picture_button.frame = CGRect(x: 30, y: bounds.height - 70, width: bounds.width / 2,height: 70)
        submit_button.frame = CGRect(x: 30, y: bounds.height - 70, width: bounds.width / 2,height: 70)
        submit_button.isHidden = true

        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
        map_view.isHidden = true
        set_up_map()
        load_camera() }

    func load_camera() {
        print("loading camera")
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera

        present(imagePicker, animated: true, completion: nil)

    }

}

