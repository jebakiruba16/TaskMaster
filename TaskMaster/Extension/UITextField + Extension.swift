

import Foundation
import UIKit
@IBDesignable
class CustomTextField: UITextField {

    @IBInspectable var customPlaceholder: String? {
        get {
            return self.placeholder
        }
        set {
            self.placeholder = newValue
            updatePlaceholderAppearance()
        }
    }
    
    @IBInspectable var placeholderColor: UIColor = .lightGray {
        didSet {
            updatePlaceholderAppearance()
        }
    }
    
    @IBInspectable var placeholderFont: UIFont = .systemFont(ofSize: 14) {
        didSet {
            updatePlaceholderAppearance()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updatePlaceholderAppearance()
    }

    private func updatePlaceholderAppearance() {
        if let placeholderText = placeholder {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: placeholderColor,
                .font: placeholderFont
            ]
            self.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        }
    }
}
