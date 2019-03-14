//
//  Extension.swift
//  MPCChat
//
//  Created by apple on 13/03/19.
//  Copyright © 2019 kayosys. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    func popViewController(viewController: UIViewController?, animated: Bool, completion: @escaping(Bool) -> ()) {
        
        if viewController != nil {
            self.navigationController?.popViewController(animated: animated)
            completion(true)
        }
        
        completion(false)
    }
    
}
