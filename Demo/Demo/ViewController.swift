//
//  ViewController.swift
//  Demo
//
//  Created by Honghao Zhang on 2/20/15.
//  Copyright (c) 2015 Honghao Zhang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var datePicker: ZHDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        // Setup View
        datePicker = ZHDatePicker()
        let views = ["datePicker": datePicker]
		let metrics = ["fixedHeight": ZHDatePicker.kPickerFixedHeight]
		
        datePicker.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(datePicker)
		
		var constraints = [NSLayoutConstraint]()
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[datePicker]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views) as! [NSLayoutConstraint]
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-100-[datePicker(fixedHeight)]", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: metrics, views: views) as! [NSLayoutConstraint]
		NSLayoutConstraint.activateConstraints(constraints)
    }
}

