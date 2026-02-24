import UIKit

extension UIImage {
    /// Create a solid color image
    static func color(_ color: UIColor, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
