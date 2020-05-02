//
//  ViewController.swift
//  Arabic Speech Recognition
//
//  Created by Omar Droubi on 4/26/20.
//  Copyright © 2020 Omar Droubi. All rights reserved.
//

import UIKit

class ArabicSR: UIViewController {

    @IBOutlet weak var imageIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageIcon.layer.cornerRadius = imageIcon.frame.height / 2.0
        self.imageIcon.layer.masksToBounds = true
    }
}

