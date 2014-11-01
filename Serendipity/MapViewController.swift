//
//  ViewController.swift
//  Serendipity
//
//  Created by Rahul Dhodapkar on 10/31/14.
//  Copyright (c) 2014 Rahul Dhodapkar. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {
    let DRIVE_TYPE:Int = 0
    let WALK_TYPE:Int = 1
    
    @IBOutlet weak var destinationLabel: UILabel!
    
    var destinationText:NSString!
    var transitType:Int!
    var serendipityOn:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up all functionality after loading in a view.
        println("managed to successfully load view")
        self.destinationLabel.text = "Destination: \(destinationText)"
        // Do any additional setup after loading the view, typically from a nib.
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

