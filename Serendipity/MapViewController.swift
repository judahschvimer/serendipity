//
//  ViewController.swift
//  Serendipity
//
//  Created by Rahul Dhodapkar on 10/31/14.
//  Copyright (c) 2014 Rahul Dhodapkar. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {
    @IBOutlet weak var destinationLabel: UILabel!
    var destinationText:NSString!
    
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
    
    func sendValue(value : NSString) {
        destinationText = value
    }
    
}

