

import Foundation
import UIKit

extension UITextView {
    
    private struct AssociatedKeys {
        static var placeholderKey = "placeholderKey"
    }
    
    @IBInspectable var placeholder: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.placeholderKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.placeholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if let placeholder = newValue {
                let placeholderLabel = UILabel()
                placeholderLabel.text = placeholder
                placeholderLabel.font = UIFont.italicSystemFont(ofSize: self.font?.pointSize ?? 17)
                placeholderLabel.textColor = UIColor.black
                placeholderLabel.numberOfLines = 0
                placeholderLabel.frame.origin = CGPoint(x: 5, y: 8)
                
                self.addSubview(placeholderLabel)
                self.setValue(placeholderLabel, forKey: "_placeholderLabel")
            }
        }
    }
    
    func setPlaceholderVisibility() {
        if self.text.isEmpty {
            self.viewWithTag(999)?.isHidden = false
        } else {
            self.viewWithTag(999)?.isHidden = true
        }
    }
}
