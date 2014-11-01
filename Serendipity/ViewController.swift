//
//  ViewController.swift
//  Serendipity
//
//  Created by Rahul Dhodapkar on 10/31/14.
//  Copyright (c) 2014 Rahul Dhodapkar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var destinationField: UITextField!
    @IBOutlet weak var methodField: UISegmentedControl!
    @IBOutlet weak var serendipityOn: UISwitch!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func moveToMapEvent(sender: AnyObject) {
        self.performSegueWithIdentifier("mapTransition", sender: self)
        println("started stuff")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        println("preparing for segue")
        println("field : \(destinationField.text)")
        if let next = segue.destinationViewController as? MapViewController {
            next.sendValue(destinationField.text)
        } else {
            println("could not complete typecasting")
        }
        // pass data to next view
        
    }

}

