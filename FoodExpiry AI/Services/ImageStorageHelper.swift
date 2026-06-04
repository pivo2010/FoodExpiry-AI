import UIKit

enum ImageStorageHelper {
    static func data(from image: UIImage, compressionQuality: CGFloat = 0.75) -> Data? {
        image.normalizedForStorage().jpegData(compressionQuality: compressionQuality)
    }

    static func image(from data: Data?) -> UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }
}

private extension UIImage {
    func normalizedForStorage(maxDimension: CGFloat = 1400) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }

        let scale = maxDimension / largestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
