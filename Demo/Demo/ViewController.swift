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
    var metricDict = [String: CGFloat]()
    var viewDict = [String: UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        // Setup View
        datePicker = ZHDatePicker()
        viewDict["datePicker"] = datePicker
        datePicker.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(datePicker)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[datePicker]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewDict))
        metricDict["fixedHeight"] = ZHDatePicker.pickerFixedHeight
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-100-[datePicker(fixedHeight)]", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: metricDict, views: viewDict))
    }
}

