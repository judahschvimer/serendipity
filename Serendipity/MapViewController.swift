//
//  ViewController.swift
//  Serendipity
//
//  Created by Rahul Dhodapkar on 10/31/14.
//  Copyright (c) 2014 Rahul Dhodapkar. All rights reserved.
//

import UIKit
import CoreLocation


class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate  {
    let DRIVE_TYPE:Int = 0
    let WALK_TYPE:Int = 1
    
    @IBOutlet weak var destinationLabel: UILabel!
    
    var destinationText:NSString!
    var transitType:Int!
    var serendipityOn:Bool!
    
    @IBOutlet var mapView: GMSMapView!
    
    var firstLocationUpdate: Bool?
    let locationManager = CLLocationManager()
    let dataProvider = GoogleDataProvider()
    var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
    let mapRadius = 2000.0
    var path:GMSMutablePath?
    let strokeWidth: CGFloat = 5
    var stepList: [AnyObject]!
    var stepNum = 0
    var end = CLLocationCoordinate2D(latitude: 37.33500926, longitude: -118.03272188)
    let tolerate:CLLocationDistance = CLLocationDistance(0.002)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        let camera = GMSCameraPosition.cameraWithLatitude(-33.86, longitude: 151.20, zoom: 12)
        mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.delegate = self
        mapView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.myLocationEnabled = true
        })
        
        view = mapView
        
        cameraLocationSetter()
        
        path = GMSMutablePath(path: GMSPath())
        let start = CLLocationCoordinate2D(latitude: 37.33500926, longitude: -120.03272188)
        path!.addCoordinate(start)
        path!.addCoordinate(self.end)
        
        drawSampleRoute(start, end: self.end)
        
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: Selector("handleTimer:"), userInfo: nil, repeats: true)


        
        // set up all functionality after loading in a view.
        println("managed to successfully load view")
        //self.destinationLabel.text = "Destination: \(destinationText)"
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.removeObserver(self, forKeyPath: "myLocation")
    }
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        mapView.clear()
        dataProvider.fetchPlacesNearCoordinate(coordinate, radius:mapRadius, types: searchedTypes) { places in
            for place: GooglePlace in places {
                let marker = PlaceMarker(place: place)
                println(place.name)
                marker.map = self.mapView
            }
        }
    }
    
    
    func handleTimer(timer: NSTimer) {
        cameraLocationSetter()
        
    }
    
    func cameraLocationSetter() {
        let currLoc = mapView.myLocation
        if(currLoc != nil){
            println(currLoc)
            mapView.animateToLocation(currLoc.coordinate)
            
            if (isPointOnPath(self.stepList[self.stepNum] as [String: AnyObject], p: currLoc.coordinate) == false){
                if (isPointOnPath(self.stepList[self.stepNum+1] as [String: AnyObject], p: currLoc.coordinate) == true){
                    println("next")
                    nextStep()
                }
                else{
                    println("recalc")
                    recalculate()
                }
            }
            
            
        }
        
    }
    
    func isPointOnPath(step: [String: AnyObject], p: CLLocationCoordinate2D) -> Bool{
        if let start = step["start_location"] as AnyObject? as? [String : Double] {
            if let start_lat = start["lat"] as AnyObject? as? Double {
                if let start_lng = start["lng"] as AnyObject? as? Double {
                    if let end = step["end_location"] as AnyObject? as? [String : Double] {
                        if let end_lat = end["lat"] as AnyObject? as? Double {
                            if let end_lng = end["lng"] as AnyObject? as? Double {
                                return (isBetween(p.latitude, s1: start_lat, s2: end_lat, tolerance:self.tolerate) && isBetween(p.longitude, s1: start_lng, s2: end_lng, tolerance:self.tolerate))
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    
    func isBetween(mid: Double, s1: Double, s2:Double, tolerance:Double) -> Bool{
        return ((mid > (s1-tolerance) && mid < (s2+tolerance)) || (mid < (s1+tolerance) && mid > (s2-tolerance)))
        
    }
    
    // returns a path using the poly line for the step
    func getPathFromStep(step: [String: AnyObject]) -> GMSPath!{
        if let line = step["polyline"] as AnyObject? as? [String : String] {
            if let points = line["points"] as AnyObject? as? String {
                return GMSPath(fromEncodedPath: points)
            }
        }
        return nil
    }
    
    //returns the html for the direction
    func getDirFromStep(step: [String: AnyObject]) -> String?{
        if let dir = step["html_instructions"] as AnyObject? as? String {
            return dir
        }
        return nil
    }
    
    // returns a path using the poly line for the step
    func getDurationTextFromStep(step: [String: AnyObject]) -> String?{
        if let dur = step["duration"] as AnyObject? as? [String : String] {
            if let durtext = dur["text"] as AnyObject? as? String {
                return durtext
            }
        }
        return nil
    }
    
    // returns a path using the poly line for the step
    func getDistanceTextFromStep(step: [String: AnyObject]) -> String?{
        if let dist = step["distance"] as AnyObject? as? [String : String] {
            if let disttext = dist["text"] as AnyObject? as? String {
                return disttext
            }
        }
        return nil
    }
    
    func nextStep(){
        self.stepNum++
        
    }
    
    func recalculate(){
        mapView.clear()
        path!.addCoordinate(mapView.myLocation.coordinate)
        path!.addCoordinate(self.end)
        drawSampleRoute(mapView.myLocation.coordinate, end: self.end)
        
    }
    
    func drawSampleRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        
        println("getting to drawing the sample route function")
        
        let locMap = mapView!
        dataProvider.fetchDirectionsFrom(start, to: end)
            {optionalRoute, routeSteps in
                //println("call resolving \(optionalRoute)")
                println("callback")
                //println(routeSteps)
                if let encodedRoute = optionalRoute {
                    //println(encodedRoute)
                    let path = GMSPath(fromEncodedPath: encodedRoute)
                    let line = GMSPolyline(path: path)
                    
                    line.strokeWidth = 5.0
                    line.map = locMap
                }
                self.stepList = routeSteps
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendValues(destination: NSString, transitType: Int, serendipityOn: Bool) {
        self.destinationText = destination
        self.transitType = transitType
        self.serendipityOn = serendipityOn
    }
    
}

