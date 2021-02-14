//
//  PreferenceViewController.swift
//  Translator-iOS
//
//  Created by Zhixun Liu on 2021/2/15.
//

import UIKit
import InAppSettingsKit

class PreferenceViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
    
    func settingsViewControllerDidEnd(_ settingsViewController: IASKAppSettingsViewController) {
        self.dismiss(animated: true, completion: nil)

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self;
    }
    
    
    
}
