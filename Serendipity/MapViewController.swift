//
//  ViewController.swift
//  Serendipity
//
//  Created by Rahul Dhodapkar on 10/31/14.
//  Copyright (c) 2014 Rahul Dhodapkar. All rights reserved.
//

import UIKit
import CoreLocation
import Darwin           // support for mathematical manipulations and constants

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate  {
    let DRIVE_TYPE:Int = 0
    let WALK_TYPE:Int = 1
    
    /******************************************
    * Init Fields to pass Navigation parameters between ViewControllers
    */
    var destinationText:NSString!
    var transitType:Int!
    var serendipityOn:Bool!
    
    /******************************************
     * Init Fields for Main Map UI
     */
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var navInfo: UIWindow!
    @IBOutlet var navLabel: UILabel!
    @IBOutlet var detourInfo: UIWindow!
    @IBOutlet var detourLabel: UILabel!
    @IBOutlet var attButton: UIButton!
    @IBOutlet var foodButton: UIButton!
    @IBOutlet var gasButton: UIButton!
    @IBOutlet weak var destinationLabel: UILabel!

    
    /******************************************
    * Init Various other Globals
    */
    
    let FOOD_BUTTON_TAG:Int = 0
    let GAS_BUTTON_TAG:Int = 1
    let ATT_BUTTON_TAG:Int = 2
    
    let locationManager = CLLocationManager()
    let dataProvider = GoogleDataProvider()
    let strokeWidth: CGFloat = 5
    let mapRadius = 1000.0
    let tolerate:CLLocationDistance = CLLocationDistance(0.002)
    
    var firstLocationUpdate: Bool?
    var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
    var path:GMSMutablePath?
    var stepList: [AnyObject]!
    var stepNum = 0
    var end = CLLocationCoordinate2D(latitude: 37.33482105, longitude: -122.03450886)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        let camera = GMSCameraPosition.cameraWithLatitude(41.3111, longitude: -72.9267, zoom: 12)
        self.mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        self.mapView.settings.compassButton = true
        self.mapView.settings.myLocationButton = true
        self.mapView.delegate = self
        self.mapView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        self.mapView.myLocationEnabled = true
        
        mapView.frame = view.bounds         // REQUIRED for google maps to work properly with
        self.view.addSubview(mapView)       // additional buttons on top of the UI.
		cameraLocationSetter()              // ******************************************

        self.path = GMSMutablePath(path: GMSPath())
        let start = CLLocationCoordinate2D(latitude: 37.33500926, longitude: -120.03272188)
        self.path!.addCoordinate(start)
        self.path!.addCoordinate(self.end)
        
        drawSampleRoute(start, end: self.end)
        
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: Selector("handleTimer:"), userInfo: nil, repeats: true)

        // Do any additional setup after loading the view, typically from a nib.
        
        navInfo = UIWindow(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 120))
        navInfo.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.75)
        self.view.addSubview(navInfo)
        navInfo.makeKeyAndVisible()
        
        navLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        navLabel.text = "helloworld"
        navInfo.addSubview(navLabel)
        navLabel.center = navInfo.center
        
        /**
         * Attraction Button Configuration Options
         */
        attButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        attButton.frame = CGRectMake(10, 141, 36, 36)
        attButton.setImage(UIImage(named: "attractions.png"), forState: UIControlState.Normal)
        attButton.addTarget(self, action: "attButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        attButton.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
        attButton.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
        attButton.tag = ATT_BUTTON_TAG
        self.view.addSubview(attButton)
        
        /**
        * Food Button Configuration Options
        */
        foodButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        foodButton.frame = CGRectMake(10, 195, 36, 36)
        foodButton.setImage(UIImage(named: "food.png"), forState: UIControlState.Normal)
        foodButton.addTarget(self, action: "attButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        foodButton.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
        foodButton.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
        foodButton.tag = FOOD_BUTTON_TAG
        self.view.addSubview(foodButton)
        
        /**
        * Gas Button Configuration Options
        */
        gasButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        gasButton.frame = CGRectMake(10, 249, 36, 36)
        gasButton.setImage(UIImage(named: "gas.png"), forState: UIControlState.Normal)
        gasButton.addTarget(self, action: "attButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        gasButton.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
        gasButton.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
        gasButton.tag = GAS_BUTTON_TAG
        self.view.addSubview(gasButton)
        
        mapView.removeObserver(self, forKeyPath: "myLocation")
    }
    
    func getLocationForAddress(address: String) -> CLLocationCoordinate2D? {
        var loc = CLLocationCoordinate2D?()
        dataProvider.fetchCoordsForAddress(address){ outloc in
            loc = outloc
            println("close")
            println(loc)
        }

        return loc!
    }
    
    // a handler for the timer that simply calls the camera location setter
    func handleTimer(timer: NSTimer) {
        cameraLocationSetter()
    }
    
    
    //sets the camera location for the current map and checks that the point is still on the route
    func cameraLocationSetter() {
        let currLoc = mapView.myLocation
        if(currLoc != nil){
            println(currLoc)
            mapView.animateToLocation(currLoc.coordinate)
            println("Currently At: {\(currLoc.coordinate.latitude), \(currLoc.coordinate.longitude)}")
            //fetchNearbyPlaces(currLoc.coordinate)
            // TODO: find a more elegant way to exit early.
            if let tst = self.stepList {
            } else {
                return
            }
            
            if(isPointOnPath(self.stepList[self.stepNum] as [String: AnyObject], p: currLoc.coordinate) == false){
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
    
    // gets the end points of the step
    func getEndPointsofStep(step: [String: AnyObject]) -> (CLLocationCoordinate2D, CLLocationCoordinate2D)?{
        if let start = step["start_location"] as AnyObject? as? [String : Double] {
            if let start_lat = start["lat"] as AnyObject? as? Double {
                if let start_lng = start["lng"] as AnyObject? as? Double {
                    if let end = step["end_location"] as AnyObject? as? [String : Double] {
                        if let end_lat = end["lat"] as AnyObject? as? Double {
                            if let end_lng = end["lng"] as AnyObject? as? Double {
                                return (CLLocationCoordinate2DMake(CLLocationDegrees(start_lat), CLLocationDegrees(start_lng)),CLLocationCoordinate2DMake( CLLocationDegrees(start_lat), CLLocationDegrees(start_lng)))
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    // determines if a point is on the path in the current step
    func isPointOnPath(step: [String: AnyObject], p: CLLocationCoordinate2D) -> Bool{
        let (start, end) = getEndPointsofStep(step)!
        return (isBetween(p.latitude, s1: start.latitude, s2: end.latitude, tolerance:self.tolerate) && isBetween(p.longitude, s1: start.longitude, s2: end.longitude, tolerance:self.tolerate))

    }
    
    
    // determines if the mid double is between the other two doubles with a tolerance for some noise
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
    
    // gets the map ready for the next step in the directions
    func nextStep(){
        self.stepNum++
        // set helloworld label to the next one
        if let stepAsDict = stepList[stepNum] as? [String : AnyObject] {
            navLabel.text = self.getDirFromStep(stepAsDict)
        }
    }
    
    // recalculates the path and clears the map for the new path
    func recalculate(){
        mapView.clear()
        path!.addCoordinate(mapView.myLocation.coordinate)
        path!.addCoordinate(self.end)
        drawSampleRoute(mapView.myLocation.coordinate, end: self.end)
        stepNum = 0
        
        if let stepAsDict = stepList[stepNum] as? [String : AnyObject] {
            navLabel.text = self.getDirFromStep(stepAsDict)
        }
    }
    
    // draws a route from the start to the end on the map and gets the steps for the route
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
    
    func attButtonAction(sender:UIButton!)
    {
        println(sender.tag)
        println("Button tapped")
        performSerendipitySearch(4)
    }
    
    /**************************************************************************
    * set of functions to compute the "serendipity" rerouting on navigation.
    */
    
    func performSerendipitySearch(limit: Int) -> Void {
        let searchPoints = self.getRelevantSearchPointsOnRoute()
        self.getProximalPlaces(searchPoints) {
            proximalPlaces in
            
            // this shouldn't be a blocking function call.
            let scoredPlaces = self.getPlacesScore(proximalPlaces)
            let sortedScoredPlaces = self.sortPlacesByScore(scoredPlaces)
            
            var filteredPlaces:[GooglePlace] = []
            for i in 0...limit {
                filteredPlaces.append(sortedScoredPlaces[i])
            }
            
            // TODO: update UI here with the verified filteredPlaces array
            println("----------------- UPDATE TO UI ------------------")
            for pl in filteredPlaces {
                println(pl.address)
                println("{\(pl.coordinate.latitude), \(pl.coordinate.longitude)")
                // plot points down here! make sure that this damn thing actually works.
                let nwMarker:GMSMarker = GMSMarker(position: pl.coordinate)
                nwMarker.appearAnimation = kGMSMarkerAnimationPop               // pop animation
                nwMarker.map = self.mapView
            }
        }
    }
    
    // TODO: refine this method to sample points by equal *distance* along the
    //       projected path, rather than equal number of steps.
    func getRelevantSearchPointsOnRoute() -> [CLLocationCoordinate2D] {
        var retList:[CLLocationCoordinate2D] = []
        
        var distPassed:Int = 0
        for step:AnyObject in stepList[stepNum...stepList.count - 1] {
            if let stepDict = step as? [String : AnyObject] {           // WARN: how does this work?
                let (start, end) = self.getEndPointsofStep(stepDict)!
                retList.append(end)
            }
        }
        return retList
    }
    
    /**
     * Gets pointwise proximal places for a given CLLocationCoordinate2D.  Needs to 
     * support asynchronous callback gracefully without blocking execution of the rest
     * of the application.
     */
    func getProximalPlaces(sourcePoints: [CLLocationCoordinate2D], cb: ([GooglePlace] -> Void)) -> Void{
        var places:[GooglePlace] = []
        var nReturned:Int = 0
        
        for coord:CLLocationCoordinate2D in sourcePoints {
            self.fetchNearbyPlaces(coord) {
                newPlaces in
                places.extend(newPlaces)
                nReturned = nReturned + 1

                if nReturned == sourcePoints.count {
                    cb(places)
                }
            }
        }
    }
    
    /**
     * Scoring Function
     *      Score(D_curr->place, S_placerating, D_pathlen_increase) = val:Double
     *          -> D_pathlen_increase
     *
     *      lower score should indicate *higher* priority
     */
    func getPlaceScore(pl: GooglePlace) -> Double {
        let curToPoint:Double = getHaversineDistance(mapView.myLocation.coordinate, p2: pl.coordinate)
        let pointToEnd:Double = getHaversineDistance(pl.coordinate, p2: self.end)
        let curToEnd:Double = getHaversineDistance(mapView.myLocation.coordinate, p2: self.end)
        
        //let distAdded = (curToPoint + pointToEnd) - curToEnd
        let distAdded = curToPoint                              // TODO: remove this shim
        
        // TODO: need a way to add ratings in here, should scrape during proximity scan.
        return distAdded
    }
    
    func getPlacesScore(places: [GooglePlace]) -> [(GooglePlace, Double)] {
        var annotatedPlaces:[(GooglePlace, Double)] = []
        
        for place:GooglePlace in places {
            annotatedPlaces.append((place, getPlaceScore(place)))
        }
        
        return annotatedPlaces
    }
    
    /**
     * With current schema, lower score indicates *higher* prioirty, so should be sorted
     * in *ascending* order.
     */
    func sortPlacesByScore(scoredPlaces: [(GooglePlace, Double)]) -> [GooglePlace] {
        var sortedPlaces:[(GooglePlace, Double)] = sorted(scoredPlaces) {
            let (p1, v1) = $0
            let (p2, v2) = $1
            return v1 < v2
        }
        var sortedStrippedPlaces:[GooglePlace] = []
        for (place, val) in sortedPlaces {
            sortedStrippedPlaces.append(place)
        }

        return sortedStrippedPlaces
    }
    
    /**
     * Fetches a list of nearby places and uses the provided callback to modify the passed list
     * in the appropriate fashion.
     */
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, cb: ([GooglePlace] -> Void)) -> Void {
        dataProvider.fetchPlacesNearCoordinate(coordinate, radius:mapRadius, types: searchedTypes) {
            places in
            cb(places)
        }
    }
    
    /**************************************************************************
    * Haversine Formula for distance between two latitude and longitude points.
    * distance is returned in Meters - standard for Google Maps API.
    */
    
    // convert degrees to radians
    func rad(x:Double) -> Double {
        return x * M_PI / 180
    }
    
    // calculate Haversine Distance
    func getHaversineDistance(p1:CLLocationCoordinate2D, p2:CLLocationCoordinate2D) -> Double {
        let R:Double = 6378137; // Earth’s mean radius in meter
        
        let dLat = rad(p2.latitude - p1.latitude);
        let dLong = rad(p2.longitude - p1.longitude);
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(rad(p1.latitude)) * cos(rad(p2.latitude)) *
            sin(dLong / 2) * sin(dLong / 2);
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a));
        let d = R * c;
        return d; // returns the distance in meter
    }
    
    // function called at the end to dispose of resources
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // function to allow for parameter passing on segue from initial view
    func sendValues(destination: NSString, transitType: Int, serendipityOn: Bool) {
        self.destinationText = destination
        self.transitType = transitType
        self.serendipityOn = serendipityOn
    }
    
}

