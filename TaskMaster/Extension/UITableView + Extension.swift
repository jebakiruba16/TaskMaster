//
//  UITableView + Extension.swift
//  TaskMaster
//
//  Created by Lexicon Systems on 07/03/25.
//

import Foundation
import UIKit

extension UITableView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = UIColor(red: 82/255, green: 124/255, blue: 202/255, alpha: 1)
        messageLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 20)!
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }
    
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .none
    }
}
