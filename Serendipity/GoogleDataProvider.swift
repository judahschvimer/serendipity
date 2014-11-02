//
//  GoogleDataProvider.swift
//  Feed Me
//
//  Created by Ron Kliffer on 8/30/14.
//  Copyright (c) 2014 Ron Kliffer. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class GoogleDataProvider {
  
  let apiKey = "AIzaSyBbDy_z2nVbAR47mNKSOT3yTqyCsMl9pXI"
  var photoCache = [String:UIImage]()
  var placesTask = NSURLSessionDataTask()
  var addressTask = NSURLSessionDataTask()
  var session: NSURLSession {
    return NSURLSession.sharedSession()
  }
    
    func fetchCoordsForAddress(address: String, completion: ((CLLocationCoordinate2D) -> Void)) -> (){

        var urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(address)&key=\(apiKey)"
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        println(urlString)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        addressTask = session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            println("SESSION")
            var coords = CLLocationCoordinate2D?()
                
            if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? NSDictionary {
                if let results = json["results"] as? NSArray {
                    if let loc = results.firstObject as? [String : AnyObject] {
                        if let geometry = loc["geometry"] as AnyObject? as? [String:AnyObject] {
                            if let location = geometry["location"] as AnyObject? as? [String: AnyObject] {
                                if let lat = location["lat"] as AnyObject? as? Double {
                                    if let lng = location["lng"] as AnyObject? as? Double {
                                        coords = CLLocationCoordinate2DMake(lat, lng)
                                    }
                                }
                            }

                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                if(coords != nil){
                    completion(coords!)
                }
            }
        }
        addressTask.resume()
     
    }
    
  func fetchPlacesNearCoordinate(coordinate: CLLocationCoordinate2D, radius: Double, types:[String], completion: (([GooglePlace]) -> Void)) -> ()
  {
    var urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=\(apiKey)&location=\(coordinate.latitude),\(coordinate.longitude)&radius=\(radius)&rankby=prominence&sensor=true"
    let typesString = types.count > 0 ? join("|", types) : "food"
    urlString += "&types=\(typesString)"
    urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    
    
    if placesTask.taskIdentifier > 0 && placesTask.state == .Running {
      placesTask.cancel()
    }
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    placesTask = session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
      var placesArray = [GooglePlace]()
      if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? NSDictionary {
        if let results = json["results"] as? NSArray {
          for rawPlace:AnyObject in results {
            let place = GooglePlace(dictionary: rawPlace as NSDictionary, acceptedTypes: types)
            placesArray.append(place)
            if let reference = place.photoReference {
              self.fetchPhotoFromReference(reference) { image in
                place.photo = image
              }
            }
          }
        }
      }
      dispatch_async(dispatch_get_main_queue()) {
        completion(placesArray)
      }
    }
    placesTask.resume()
  }
  
  
  func fetchDirectionsFrom(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: ((String?, [AnyObject]?) -> Void)) -> ()
  {
    let urlString = "https://maps.googleapis.com/maps/api/directions/json?key=\(apiKey)&origin=\(from.latitude),\(from.longitude)&destination=\(to.latitude),\(to.longitude)" //&mode=driving
    
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
      var encodedRoute: String?
      var routeSteps: [AnyObject]?
      //println("data:\(data), response:\(response), error:\(error)")
      
      if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? [String:AnyObject] {
        println("----------")
        if let routes = json["routes"] as AnyObject? as? [AnyObject] {
          if let route = routes.first as? [String : AnyObject] {
            if let polyline = route["overview_polyline"] as AnyObject? as? [String : String] {
              if let points = polyline["points"] as AnyObject? as? String {
                encodedRoute = points
              }
            }

            if let legs = route["legs"] as AnyObject? as? [AnyObject] {
                if let leg = legs.first as? [String : AnyObject] {

                    if let steps = leg["steps"] as AnyObject? as? [AnyObject] {
                        routeSteps = steps
                    }
            
                }
            }
          }
        }
      }
      dispatch_async(dispatch_get_main_queue()) {
        completion(encodedRoute, routeSteps)
      }
    }.resume()
  }
  
  
  func fetchPhotoFromReference(reference: String, completion: ((UIImage?) -> Void)) -> ()
  {
    if let photo = photoCache[reference] as UIImage! {
      completion(photo)
    } else {
      let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=200&photoreference=\(reference)&key=\(apiKey)"
      
      UIApplication.sharedApplication().networkActivityIndicatorVisible = true
      session.downloadTaskWithURL(NSURL(string: urlString)!) {url, response, error in
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        let downloadedPhoto = UIImage(data: NSData(contentsOfURL: url)!)
        self.photoCache[reference] = downloadedPhoto
        dispatch_async(dispatch_get_main_queue()) {
          completion(downloadedPhoto)
        }
      }.resume()
    }
  }
}
