import UIKit

extension UITextField {
    func applyStyle(_ placeholder: String) {
        self.placeholder = placeholder
        self.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        self.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        self.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        self.layer.cornerRadius = 12

        self.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)
            ]
        )

        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        self.leftViewMode = .always
    }
}
