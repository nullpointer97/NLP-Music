//
//  StyckyHeaderView.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 29.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

final class StickyHeaderView: UIView {
    public let imageView: ShadowImageView = {
        let imageView = ShadowImageView()
        imageView.imageView.contentMode = .scaleAspectFill
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    public let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.textColor = .getAccentColor(fromType: .common)
        return label
    }()
    
    public let subtitleSecondLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()
    
    private var imageViewHeight = NSLayoutConstraint()
    private var imageViewSize = [NSLayoutConstraint(), NSLayoutConstraint()]
    private var imageViewBottom = NSLayoutConstraint()
    private let containerView = UIView()
    private var containerViewHeight = NSLayoutConstraint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
        setViewConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func createViews() {
        containerView.add(to: self)
        imageView.add(to: containerView)
        titleLabel.add(to: containerView)
        subtitleLabel.add(to: containerView)
        subtitleSecondLabel.add(to: containerView)
        
        isSkeletonable = true
        imageView.imageView.isSkeletonable = true
        titleLabel.isSkeletonable = true
        subtitleLabel.isSkeletonable = true
        subtitleSecondLabel.isSkeletonable = true
        
        imageView.imageView.showAnimatedGradientSkeleton()
        imageView.imageView.startSkeletonAnimation()
        titleLabel.showAnimatedGradientSkeleton()
        titleLabel.startSkeletonAnimation()
        subtitleLabel.showAnimatedGradientSkeleton()
        subtitleLabel.startSkeletonAnimation()
        subtitleSecondLabel.showAnimatedGradientSkeleton()
        subtitleSecondLabel.startSkeletonAnimation()
    }
    
    private func setViewConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: containerView.widthAnchor),
            centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerViewHeight = containerView.heightAnchor.constraint(equalTo: heightAnchor)
        containerViewHeight.isActive = true
        
        imageView.autoPinEdge(.top, to: .top, of: containerView, withOffset: 24)
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        imageViewSize = imageView.autoSetDimensions(to: .identity(frame.width / 2))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 16)
        titleLabel.autoPinEdge(.leading, to: .leading, of: containerView, withOffset: 16)
        titleLabel.autoPinEdge(.trailing, to: .trailing, of: containerView, withOffset: -16)
        titleLabel.autoSetDimension(.height, toSize: 24)
        
        subtitleLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 4)
        subtitleLabel.autoPinEdge(.leading, to: .leading, of: containerView, withOffset: 16)
        subtitleLabel.autoPinEdge(.trailing, to: .trailing, of: containerView, withOffset: -16)
        subtitleLabel.autoSetDimension(.height, toSize: 20)
        
        subtitleSecondLabel.autoPinEdge(.top, to: .bottom, of: subtitleLabel, withOffset: 4)
        subtitleSecondLabel.autoPinEdge(.leading, to: .leading, of: containerView, withOffset: 16)
        subtitleSecondLabel.autoPinEdge(.trailing, to: .trailing, of: containerView, withOffset: -16)
        subtitleSecondLabel.autoSetDimension(.height, toSize: 16)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        containerViewHeight.constant = scrollView.contentInset.top
        let offsetY = -(scrollView.contentOffset.y + scrollView.contentInset.top)
        containerView.clipsToBounds = offsetY <= 0
        imageViewBottom.constant = offsetY >= 0 ? 0 : -offsetY / 2
        imageViewHeight.constant = max(offsetY + scrollView.contentInset.top, scrollView.contentInset.top)
    }
    
    public static func getHeight(isArtistAvailable: Bool = true, isYearAvailable: Bool = true) -> CGFloat {
        var additionalOffset: CGFloat = 76

        if isArtistAvailable {
            additionalOffset += 24
        }
        
        if isYearAvailable {
            additionalOffset += 20
        }
        
        return (UIScreen.main.bounds.width / 2) + additionalOffset
    }
}

@IBDesignable
public class ShadowImageView: UIView {

    public var imageView = UIImageView()
    private var blurredImageView = UIImageView()


    /// Gaussian Blur radius, larger will make the back ground shadow lighter (warning: do not set it too large, 2 or 3 for most cases)
    @IBInspectable
    public var blurRadius: CGFloat = 6 {
        didSet {
            layoutShadow()
        }
    }

    /// The image view contains target image
    @IBInspectable
    public var image: UIImage? {
        set {
            DispatchQueue.main.async {
                self.imageView.image = newValue
                self.layoutShadow()
            }
        }
        get {
            return self.imageView.image
        }
    }

    /// Image's corner radius
    @IBInspectable
    public var imageCornerRaidus: CGFloat = 12 {
        didSet {
            imageView.layer.cornerRadius = imageCornerRaidus
            imageView.layer.masksToBounds = true
        }
    }

    /// shadow radius offset in percentage, if you want shadow radius larger, set a postive number for this, if you want it be smaller, then set a negative number
    @IBInspectable
    public var shadowRadiusOffSetPercentage: CGFloat = 40 {
        didSet {
            layoutShadow()
        }
    }

    /// Shadow offset value on x axis, postive -> right, negative -> left
    @IBInspectable
    public var shadowOffSetByX: CGFloat = 0 {
        didSet {
            layoutShadow()
        }
    }


    /// Shadow offset value on y axis, postive -> right, negative -> left
    @IBInspectable
    public var shadowOffSetByY: CGFloat = -UIScreen.main.bounds.width / 2 {
        didSet {
            layoutShadow()
        }
    }
    
    
    /// Shadow alpha value
    @IBInspectable
    public var shadowAlpha: CGFloat = 0.4 {
        didSet {
            blurredImageView.alpha = shadowAlpha
        }
    }
    
    override public var contentMode: UIView.ContentMode {
        didSet{
            layoutShadow()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutShadow()
    }

    /// Generate the background color and set it to a image view.
    private func generateBlurBackground() {
        guard let image = image else{
            return
        }
        let realImageSize = getRealImageSize(image)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let weakself = self else {
                return
            }
            // Create a containerView to hold the image should apply gaussian blur.
            let containerLayer = CALayer()
            containerLayer.frame = CGRect(origin: .zero, size: realImageSize.scaled(by: 1.4))
            containerLayer.backgroundColor = UIColor.clear.cgColor
            let blurImageLayer = CALayer()
            blurImageLayer.frame = CGRect(origin: CGPoint.init(x: realImageSize.width * 0.2, y: realImageSize.height * 0.2), size: realImageSize)
            blurImageLayer.contents = image.cgImage
            blurImageLayer.cornerRadius = weakself.imageCornerRaidus
            blurImageLayer.masksToBounds = true
            containerLayer.addSublayer(blurImageLayer)
            
            var containerImage = UIImage()
            // Get the UIImage from a UIView.
            if containerLayer.frame.size != CGSize.zero {
                containerImage = UIImage(layer: containerLayer)
            }else {
                containerImage = UIImage()
            }

            guard let resizedContainerImage = containerImage.resized(withPercentage: 0.2),
                let ciimage = CIImage(image: resizedContainerImage),
                let blurredImage = weakself.applyBlur(ciimage: ciimage) else {
                    return
            }

            DispatchQueue.main.async {
                self?.blurredImageView.image = blurredImage
            }
        }
    }

    /// Apply Gaussian Blur to a ciimage, and return a UIImage
    ///
    /// - Parameter ciimage: the imput CIImage
    /// - Returns: output UIImage
    private func applyBlur(ciimage: CIImage) -> UIImage? {

        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            filter.setValue(blurRadius, forKeyPath: kCIInputRadiusKey)
            
            // Due to a iOS 8 bug, we need to bridging CIContext from OC to avoid crashing
            let context = CIContext.bridging(options: nil)
            if let output = filter.outputImage, let cgimage = context.createCGImage(output, from: ciimage.extent) {
                return UIImage(cgImage: cgimage)
            }
        }
        return nil
    }

    /// Due to scaleAspectFit, need to calculate the real size of the image and set the corner radius
    ///
    /// - Parameter from: input image
    /// - Returns: the real size of the image
    func getRealImageSize(_ from: UIImage) -> CGSize {
        if contentMode == .scaleAspectFit {
            let scale = min(bounds.size.width / from.size.width, bounds.size.height / from.size.height)
            return from.size.scaled(by: scale)
        } else {
            return from.size
        }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        backgroundColor = .clear
        if newSuperview != nil {
            layoutImageView()
        }
    }

    private func layoutShadow() {
        
        DispatchQueue.main.async {
            self.generateBlurBackground()
            self.imageView.frame = CGRect(origin: .zero, size: self.frame.size)
            self.imageView.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
            
            let newSize = self.frame.size.scaled(by: 1.4 * (1 + self.shadowRadiusOffSetPercentage/100))
            
            self.blurredImageView.frame = CGRect(origin: .zero, size: newSize)
            self.blurredImageView.center = CGPoint(x: self.bounds.width/2 + self.shadowOffSetByX, y: self.bounds.height/2 + self.shadowOffSetByY)
            self.blurredImageView.contentMode = self.contentMode
            self.blurredImageView.alpha = self.shadowAlpha
        }
    }

    private func layoutImageView() {
        imageView.image = image
        imageView.frame = bounds

        imageView.layer.cornerRadius = imageCornerRaidus
        imageView.layer.masksToBounds = true
        imageView.contentMode = contentMode
        addSubview(imageView)
        addSubview(blurredImageView)
        sendSubviewToBack(blurredImageView)
    }

}

private extension CGSize {
    
    /// Generates a new size that is this size scaled by a cerntain percentage
    ///
    /// - Parameter percentage: the percentage to scale to
    /// - Returns: a new CGSize instance by scaling self by the given percentage
    func scaled(by percentage: CGFloat) -> CGSize {
        return CGSize(width: width * percentage, height: height * percentage)
    }
    
}

private extension UIImage {

    /// Resize the image to a centain percentage
    ///
    /// - Parameter percentage: Percentage value
    /// - Returns: UIImage(Optional)
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = size.scaled(by: percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Method to create a UIImage from CALayer
    ///
    /// - Parameter layer: input Layer
    convenience init(layer: CALayer) {
        UIGraphicsBeginImageContext(layer.frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cgImage = image?.cgImage {
            self.init(cgImage: cgImage)
        } else {
            self.init()
        }
    }
}

extension CIContext {
    class func bridging(options: [CIContextOption : Any]?) -> CIContext {
        return CIContext(options: options)
    }
}
