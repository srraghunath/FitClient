

import UIKit

extension UIColor {
    // Primary Colors
    static let primaryGreen = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
    static let accentGreen = UIColor(red: 0.682, green: 0.996, blue: 0.078, alpha: 1.0)
    static let primaryGreenSoft = UIColor(red: 214/255, green: 254/255, blue: 137/255, alpha: 1.0)
    static let primaryMildYellow = UIColor(red: 255/255, green: 215/255, blue: 77/255, alpha: 1.0)
    
    // Background Colors
    static let backgroundBlack = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
    static let backgroundDark = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
    static let backgroundGray = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
    static let backgroundLight = UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1.0)
    static let cardBackground = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
    static let tabBarBackground = UIColor(red: 0.129, green: 0.129, blue: 0.129, alpha: 1.0)
    
    // Text Colors
    static let textPrimary = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
    static let textSecondary = UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)
    static let textTertiary = UIColor(red: 0.843, green: 0.800, blue: 0.784, alpha: 1.0)
    
    // Helper for RGB
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
}
