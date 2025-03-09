//
//  UIViewController + Extension.swift
//  TaskMaster
//
//  Created by Lexicon Systems on 07/03/25.
//


import Foundation
import UIKit

extension UIViewController {

    func presentViewController(withIdentifier identifier: String) {
        guard let vc = storyboard?.instantiateViewController(identifier: identifier) else {
            print("ViewController with identifier \(identifier) not found.")
            return
        }
        self.present(vc, animated: true)
    }

    func dismissPresentedViewController() {
        self.dismiss(animated: true, completion: nil)
    }
}
