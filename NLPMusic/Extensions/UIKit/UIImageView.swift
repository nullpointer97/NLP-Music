//
//  UIImageView.swift
//  VKExt
//
//  Created by programmist_NA on 20.05.2020.
//

import Foundation
import UIKit
import ImageIO

let kFontResizingProportion: CGFloat = 0.4
let kColorMinComponent: Int = 30
let kColorMaxComponent: Int = 214

public typealias GradientColors = (top: UIColor, bottom: UIColor)

typealias HSVOffset = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)
let kGradientTopOffset: HSVOffset = (hue: -0.025, saturation: 0.05, brightness: 0, alpha: 0)
let kGradientBotomOffset: HSVOffset = (hue: 0.025, saturation: -0.05, brightness: 0, alpha: 0)

class WebImageView: UIImageView {
    
    private var currentUrlString: String?
    
    func set(imageURL: String?) {
        
        currentUrlString = imageURL
        
        guard let imageURL = imageURL, let url = URL(string: imageURL) else {
            self.image = nil
            return }
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)) {
            self.image = UIImage(data: cachedResponse.data)
            //print("from cachе")
            return
        }
        
        //print("from internet")
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            
            DispatchQueue.main.async {
                if let data = data, let response = response {
                    self?.handleLoadedImage(data: data, response: response)
                }
            }
        }
        dataTask.resume()
    }
    
    private func handleLoadedImage(data: Data, response: URLResponse) {
        guard let responseURL = response.url else { return }
        let cachedResponse = CachedURLResponse(response: response, data: data)
        URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: responseURL))
        if responseURL.absoluteString == currentUrlString {
            self.image = UIImage(data: data)
        }
    }
}

extension UIImageView {
    
    public func setImageForName(_ string: String, backgroundColor: UIColor? = nil, circular: Bool, textAttributes: [NSAttributedString.Key: AnyObject]?, gradient: Bool = false) {
        
        setImageForName(string, backgroundColor: backgroundColor, circular: circular, textAttributes: textAttributes, gradient: gradient, gradientColors: nil)
    }
    
    public func setImageForName(_ string: String, gradientColors: GradientColors, circular: Bool, textAttributes: [NSAttributedString.Key: AnyObject]?) {
        
        setImageForName(string, backgroundColor: nil, circular: circular, textAttributes: textAttributes, gradient: true, gradientColors: gradientColors)
    }
    
    private func setImageForName(_ string: String, backgroundColor: UIColor?, circular: Bool, textAttributes: [NSAttributedString.Key: AnyObject]?, gradient: Bool = false, gradientColors: GradientColors?) {
        
        let initials: String = initialsFromString(string: string)
        let color: UIColor = (backgroundColor != nil) ? backgroundColor! : randomColor(for: string)
        let gradientColors = gradientColors ?? topAndBottomColors(for: color)
        let attributes: [NSAttributedString.Key: AnyObject] = (textAttributes != nil) ? textAttributes! : [
            NSAttributedString.Key.font: self.fontForFontName(name: nil),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        self.image = imageSnapshot(text: initials, backgroundColor: color, circular: circular, textAttributes: attributes, gradient: gradient, gradientColors: gradientColors)
    }
    
    private func fontForFontName(name: String?) -> UIFont {
        
        let fontSize = self.bounds.width * kFontResizingProportion
        guard let name = name else { return .systemFont(ofSize: fontSize) }
        guard let customFont = UIFont(name: name, size: fontSize) else { return .systemFont(ofSize: fontSize) }
        return customFont
    }
    
    private func imageSnapshot(text imageText: String, backgroundColor: UIColor, circular: Bool, textAttributes: [NSAttributedString.Key : AnyObject], gradient: Bool, gradientColors: GradientColors) -> UIImage {
        
        let scale: CGFloat = UIScreen.main.scale
        
        var size: CGSize = self.bounds.size
        if (self.contentMode == .scaleToFill ||
            self.contentMode == .scaleAspectFill ||
            self.contentMode == .scaleAspectFit ||
            self.contentMode == .redraw) {
            
            size.width = (size.width * scale) / scale
            size.height = (size.height * scale) / scale
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return UIImage() }
        
        if circular {
            // Clip context to a circle
            let path: CGPath = CGPath(ellipseIn: self.bounds, transform: nil)
            context.addPath(path)
            context.clip()
        }
        
        if gradient {
            // Draw a gradient from the top to the bottom
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [gradientColors.top.cgColor, gradientColors.bottom.cgColor]
            
            if let gradient = CGGradient(colorsSpace: baseSpace, colors: colors as CFArray, locations: nil) {
                let startPoint = CGPoint(x: self.bounds.midX, y: self.bounds.minY)
                let endPoint = CGPoint(x: self.bounds.midX, y: self.bounds.maxY)
                
                context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            }
        } else {
            // Fill background of context
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        // Draw text in the context
        let textSize: CGSize = imageText.size(withAttributes: textAttributes)
        let bounds: CGRect = self.bounds
        
        imageText.draw(in: CGRect(x: bounds.midX - textSize.width / 2,
                                  y: bounds.midY - textSize.height / 2,
                                  width: textSize.width,
                                  height: textSize.height),
                       withAttributes: textAttributes)
        
        guard let snapshot: UIImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()
        
        return snapshot
    }
}

private func initialsFromString(string: String) -> String {
    var nameComponents = string.uppercased().components(separatedBy: CharacterSet.letters.inverted)
    nameComponents.removeAll(where: {$0.isEmpty})
    
    let firstInitial = nameComponents.first?.first
    let lastInitial  = nameComponents.count > 1 ? nameComponents.last?.first : nil
    return (firstInitial != nil ? "\(firstInitial!)" : "") + (lastInitial != nil ? "\(lastInitial!)" : "")
}

private func randomColorComponent() -> Int {
    let limit = kColorMaxComponent - kColorMinComponent
    return kColorMinComponent + Int(drand48() * Double(limit))
}

private func randomColor(for string: String) -> UIColor {
    srand48(string.hashValue)

    let red = CGFloat(randomColorComponent()) / 255.0
    let green = CGFloat(randomColorComponent()) / 255.0
    let blue = CGFloat(randomColorComponent()) / 255.0
    
    return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
}

private func clampColorComponent(_ value: CGFloat) -> CGFloat {
    return min(max(value, 0), 1)
}

private func correctColorComponents(of color: UIColor, withHSVOffset offset: HSVOffset) -> UIColor {
    
    var hue = CGFloat(0)
    var saturation = CGFloat(0)
    var brightness = CGFloat(0)
    var alpha = CGFloat(0)
    if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
        hue = clampColorComponent(hue + offset.hue)
        saturation = clampColorComponent(saturation + offset.saturation)
        brightness = clampColorComponent(brightness + offset.brightness)
        alpha = clampColorComponent(alpha + offset.alpha)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    return color
}

private func topAndBottomColors(for color: UIColor, withTopHSVOffset topHSVOffset: HSVOffset = kGradientTopOffset, withBottomHSVOffset bottomHSVOffset: HSVOffset = kGradientBotomOffset) -> GradientColors {
    let topColor = correctColorComponents(of: color, withHSVOffset: topHSVOffset)
    let bottomColor = correctColorComponents(of: color, withHSVOffset: bottomHSVOffset)
    return (top: topColor, bottom: bottomColor)
}

extension UIImageView {
    func makeRounded() {
        self.layer.borderWidth = 0.0
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
    
    open func setImage(string: String?, color: UIColor? = nil, circular: Bool = false, stroke: Bool = false, textAttributes: [NSAttributedString.Key: Any]? = nil) {
        let image = imageSnap(text: string != nil ? string?.initials : "", color: color ?? .random, circular: circular, stroke: stroke, textAttributes:textAttributes)
        
        if let newImage = image {
            self.image = newImage
        }
    }
    
    open func imageSnap(text: String?, color: UIColor, circular: Bool, stroke: Bool, textAttributes: [NSAttributedString.Key: Any]?) -> UIImage? {
        
        let scale = Float(UIScreen.main.scale)
        var size = bounds.size
        if contentMode == .scaleToFill || contentMode == .scaleAspectFill || contentMode == .scaleAspectFit || contentMode == .redraw {
            size.width = CGFloat(floorf((Float(size.width) * scale) / scale))
            size.height = CGFloat(floorf((Float(size.height) * scale) / scale))
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, CGFloat(scale))
        let context = UIGraphicsGetCurrentContext()
        if circular {
            let path = CGPath(ellipseIn: bounds, transform: nil)
            context?.addPath(path)
            context?.clip()
        }
        
        // Fill
        
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let attributes = textAttributes ?? [NSAttributedString.Key.foregroundColor: UIColor.white,
                                            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 55.0)]

        
        //stroke color
        if stroke {
            
            //outer circle
            context?.setStrokeColor((attributes[NSAttributedString.Key.foregroundColor] as! UIColor).cgColor)
            context?.setLineWidth(4)
            var rectangle : CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            context?.addEllipse(in: rectangle)
            context?.drawPath(using: .fillStroke)
            
            //inner circle
            context?.setLineWidth(1)
            rectangle = CGRect(x: 4, y: 4, width: size.width - 8, height: size.height - 8)
            context?.addEllipse(in: rectangle)
            context?.drawPath(using: .fillStroke)
        }
        
        // Text
        if let text = text {
            let textSize = text.size(withAttributes: attributes)
            let bounds = self.bounds
            let rect = CGRect(x: bounds.size.width / 2 - textSize.width / 2, y: bounds.size.height / 2 - textSize.height / 2, width: textSize.width, height: textSize.height)
            
            text.draw(in: rect, withAttributes: attributes)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

@objc public protocol GifDelegate {
    @objc optional func gifDidStart(sender: UIImageView)
    @objc optional func gifDidLoop(sender: UIImageView)
    @objc optional func gifDidStop(sender: UIImageView)
    @objc optional func gifURLDidFinish(sender: UIImageView)
    @objc optional func gifURLDidFail(sender: UIImageView, url: URL, error: Error?)
}

public extension UIImageView {
    /// Set an image and a manager to an existing UIImageView. If the image is not an GIF image, set it in normal way and remove self form SwiftyGifManager
    ///
    /// WARNING : this overwrite any previous gif.
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    /// - Parameter loopCount: The number of loops we want for this gif. -1 means infinite.
    func setImage(_ image: UIImage, manager: GifManager = .defaultManager, loopCount: Int = -1) {
        if let _ = image.imageData {
            setGifImage(image, manager: manager, loopCount: loopCount)
        } else {
            manager.deleteImageView(self)
            self.image = image
        }
    }
}

public extension UIImageView {
    
    // MARK: - Inits
    
    /// Convenience initializer. Creates a gif holder (defaulted to infinite loop).
    ///
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    convenience init(gifImage: UIImage, manager: GifManager = .defaultManager, loopCount: Int = -1) {
        self.init()
        setGifImage(gifImage,manager: manager, loopCount: loopCount)
    }
    
    /// Convenience initializer. Creates a gif holder (defaulted to infinite loop).
    ///
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    convenience init(gifURL: URL, manager: GifManager = .defaultManager, loopCount: Int = -1) {
        self.init()
        setGifFromURL(gifURL, manager: manager, loopCount: loopCount)
    }
    
    /// Set a gif image and a manager to an existing UIImageView.
    ///
    /// WARNING : this overwrite any previous gif.
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    /// - Parameter loopCount: The number of loops we want for this gif. -1 means infinite.
    func setGifImage(_ gifImage: UIImage, manager: GifManager = .defaultManager, loopCount: Int = -1) {
        if let imageData = gifImage.imageData, (gifImage.imageCount ?? 0) < 1 {
            image = UIImage(data: imageData)
            return
        }
        
        self.loopCount = loopCount
        self.gifImage = gifImage
        animationManager = manager
        syncFactor = 0
        displayOrderIndex = 0
        cache = NSCache()
        haveCache = false
        
        if let source = gifImage.imageSource, let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            currentImage = UIImage(cgImage: cgImage)
            
            if manager.addImageView(self) {
                startDisplay()
                startAnimatingGif()
            }
        }
    }
}

// MARK: - Download gif
public extension UIImageView {
    
    /// Download gif image and sets it.
    ///
    /// - Parameters:
    ///     - url: The URL pointing to the gif data
    ///     - manager: The manager to handle the gif display
    ///     - loopCount: The number of loops we want for this gif. -1 means infinite.
    ///     - showLoader: Show UIActivityIndicatorView or not
    /// - Returns: An URL session task. Note: You can cancel the downloading task if it needed.
    @discardableResult
    func setGifFromURL(_ url: URL,
                       manager: GifManager = .defaultManager,
                       loopCount: Int = -1,
                       levelOfIntegrity: GifLevelOfIntegrity = .default,
                       session: URLSession = URLSession.shared,
                       showLoader: Bool = true,
                       customLoader: UIView? = nil) -> URLSessionDataTask? {
        
        if let data =  manager.remoteCache[url] {
            self.parseDownloadedGif(url: url,
                    data: data,
                    error: nil,
                    manager: manager,
                    loopCount: loopCount,
                    levelOfIntegrity: levelOfIntegrity)
            return nil
        }
        
        stopAnimatingGif()
        
        let loader: UIView? = showLoader ? createLoader(from: customLoader) : nil
        
        let task = session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                loader?.removeFromSuperview()
                self.parseDownloadedGif(url: url,
                                        data: data,
                                        error: error,
                                        manager: manager,
                                        loopCount: loopCount,
                                        levelOfIntegrity: levelOfIntegrity)
            }
        }
        
        task.resume()
        
        return task
    }
    
    private func createLoader(from view: UIView? = nil) -> UIView {
        let loader = view ?? UIActivityIndicatorView()
        addSubview(loader)
        loader.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraint(NSLayoutConstraint(
            item: loader,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1,
            constant: 0))
        
        addConstraint(NSLayoutConstraint(
            item: loader,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerY,
            multiplier: 1,
            constant: 0))
        
        (loader as? UIActivityIndicatorView)?.startAnimating()
        
        return loader
    }
    
    private func parseDownloadedGif(url: URL,
                                    data: Data?,
                                    error: Error?,
                                    manager: GifManager,
                                    loopCount: Int,
                                    levelOfIntegrity: GifLevelOfIntegrity) {
        guard let data = data else {
            report(url: url, error: error)
            return
        }
        
        do {
            let image = try UIImage(gifData: data, levelOfIntegrity: levelOfIntegrity)
            manager.remoteCache[url] = data
            setGifImage(image, manager: manager, loopCount: loopCount)
            startAnimatingGif()
            delegate?.gifURLDidFinish?(sender: self)
        } catch {
            report(url: url, error: error)
        }
    }
    
    private func report(url: URL, error: Error?) {
        delegate?.gifURLDidFail?(sender: self, url: url, error: error)
    }
}

// MARK: - Logic
public extension UIImageView {
    
    /// Start displaying the gif for this UIImageView.
    private func startDisplay() {
        displaying = true
        updateCache()
    }
    
    /// Stop displaying the gif for this UIImageView.
    private func stopDisplay() {
        displaying = false
        updateCache()
    }
    
    /// Start displaying the gif for this UIImageView.
    func startAnimatingGif() {
        isPlaying = true
    }
    
    /// Stop displaying the gif for this UIImageView.
    func stopAnimatingGif() {
        isPlaying = false
    }
    
    /// Check if this imageView is currently playing a gif
    ///
    /// - Returns wether the gif is currently playing
    func isAnimatingGif() -> Bool{
        return isPlaying
    }
    
    /// Show a specific frame based on a delta from current frame
    ///
    /// - Parameter delta: The delsta from current frame we want
    func showFrameForIndexDelta(_ delta: Int) {
        guard let gifImage = gifImage else { return }
        var nextIndex = displayOrderIndex + delta
        
        while nextIndex >= gifImage.framesCount() {
            nextIndex -= gifImage.framesCount()
        }
        
        while nextIndex < 0 {
            nextIndex += gifImage.framesCount()
        }
        
        showFrameAtIndex(nextIndex)
    }
    
    /// Show a specific frame
    ///
    /// - Parameter index: The index of frame to show
    func showFrameAtIndex(_ index: Int) {
        displayOrderIndex = index
        updateFrame()
    }
    
    /// Update cache for the current imageView.
    func updateCache() {
        guard let animationManager = animationManager else { return }
        
        if animationManager.hasCache(self) && !haveCache {
            prepareCache()
            haveCache = true
        } else if !animationManager.hasCache(self) && haveCache {
            cache?.removeAllObjects()
            haveCache = false
        }
    }
    
    /// Update current image displayed. This method is called by the manager.
    func updateCurrentImage() {
        if displaying {
            updateFrame()
            updateIndex()
            
            if loopCount == 0 || !isDisplayedInScreen(self)  || !isPlaying {
                stopDisplay()
            }
        } else {
            if isDisplayedInScreen(self) && loopCount != 0 && isPlaying {
                startDisplay()
            }
            
            if isDiscarded(self) {
                animationManager?.deleteImageView(self)
            }
        }
    }
    
    /// Force update frame
    private func updateFrame() {
        if haveCache, let image = cache?.object(forKey: displayOrderIndex as AnyObject) as? UIImage {
            currentImage = image
        } else {
            currentImage = frameAtIndex(index: currentFrameIndex())
        }
    }
    
    /// Get current frame index
    func currentFrameIndex() -> Int{
        return displayOrderIndex
    }
    
    /// Get frame at specific index
    func frameAtIndex(index: Int) -> UIImage {
        guard let gifImage = gifImage,
            let imageSource = gifImage.imageSource,
            let displayOrder = gifImage.displayOrder, index < displayOrder.count,
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, displayOrder[index], nil) else {
                return UIImage()
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Check if the imageView has been discarded and is not in the view hierarchy anymore.
    ///
    /// - Returns : A boolean for weather the imageView was discarded
    func isDiscarded(_ imageView: UIView?) -> Bool {
        return imageView?.superview == nil
    }
    
    /// Check if the imageView is displayed.
    ///
    /// - Returns : A boolean for weather the imageView is displayed
    func isDisplayedInScreen(_ imageView: UIView?) -> Bool {
        guard !isHidden, let imageView = imageView else  {
            return false
        }
        
        let screenRect = UIScreen.main.bounds
        let viewRect = imageView.convert(bounds, to:nil)
        let intersectionRect = viewRect.intersection(screenRect)
        
        return window != nil && !intersectionRect.isEmpty && !intersectionRect.isNull
    }
    
    func clear() {
        if let gifImage = gifImage {
            gifImage.clear()
        }
        
        gifImage = nil
        currentImage = nil
        cache?.removeAllObjects()
        animationManager = nil
        image = nil
    }
    
    /// Update loop count and sync factor.
    private func updateIndex() {
        guard let gif = self.gifImage,
            let displayRefreshFactor = gif.displayRefreshFactor,
            displayRefreshFactor > 0 else {
                return
        }
        
        syncFactor = (syncFactor + 1) % displayRefreshFactor
        
        if syncFactor == 0, let imageCount = gif.imageCount, imageCount > 0 {
            displayOrderIndex = (displayOrderIndex+1) % imageCount
            
            if displayOrderIndex == 0 {
                if loopCount == -1 {
                    delegate?.gifDidLoop?(sender: self)
                } else if loopCount > 1 {
                    delegate?.gifDidLoop?(sender: self)
                    loopCount -= 1
                } else {
                    delegate?.gifDidStop?(sender: self)
                    loopCount -= 1
                }
            }
        }
    }
    
    /// Prepare the cache by adding every images of the gif to an NSCache object.
    private func prepareCache() {
        guard let cache = self.cache else { return }
        
        cache.removeAllObjects()
        
        guard let gif = self.gifImage,
            let displayOrder = gif.displayOrder,
            let imageSource = gif.imageSource else { return }
        
        for (i, order) in displayOrder.enumerated() {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, order, nil) else { continue }
            
            cache.setObject(UIImage(cgImage: cgImage), forKey: i as AnyObject)
        }
    }
}

// MARK: - Dynamic properties
private let _gifImageKey = malloc(4)
private let _cacheKey = malloc(4)
private let _currentImageKey = malloc(4)
private let _displayOrderIndexKey = malloc(4)
private let _syncFactorKey = malloc(4)
private let _haveCacheKey = malloc(4)
private let _loopCountKey = malloc(4)
private let _displayingKey = malloc(4)
private let _isPlayingKey = malloc(4)
private let _animationManagerKey = malloc(4)
private let _delegateKey = malloc(4)

public extension UIImageView {
    
    var gifImage: UIImage? {
        get { return possiblyNil(_gifImageKey) }
        set { objc_setAssociatedObject(self, _gifImageKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var currentImage: UIImage? {
        get { return possiblyNil(_currentImageKey) }
        set { objc_setAssociatedObject(self, _currentImageKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var displayOrderIndex: Int {
        get { return value(_displayOrderIndexKey, 0) }
        set { objc_setAssociatedObject(self, _displayOrderIndexKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var syncFactor: Int {
        get { return value(_syncFactorKey, 0) }
        set { objc_setAssociatedObject(self, _syncFactorKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var loopCount: Int {
        get { return value(_loopCountKey, 0) }
        set { objc_setAssociatedObject(self, _loopCountKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var animationManager: GifManager? {
        get { return (objc_getAssociatedObject(self, _animationManagerKey!) as? GifManager) }
        set { objc_setAssociatedObject(self, _animationManagerKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var delegate: GifDelegate? {
        get { return (objc_getAssociatedObject(self, _delegateKey!) as? GifDelegate) }
        set { objc_setAssociatedObject(self, _delegateKey!, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    private var haveCache: Bool {
        get { return value(_haveCacheKey, false) }
        set { objc_setAssociatedObject(self, _haveCacheKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var displaying: Bool {
        get { return value(_displayingKey, false) }
        set { objc_setAssociatedObject(self, _displayingKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var isPlaying: Bool {
        get {
            return value(_isPlayingKey, false)
        }
        set {
            objc_setAssociatedObject(self, _isPlayingKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if newValue {
                delegate?.gifDidStart?(sender: self)
            } else {
                delegate?.gifDidStop?(sender: self)
            }
        }
    }
    
    private var cache: NSCache<AnyObject, AnyObject>? {
        get { return (objc_getAssociatedObject(self, _cacheKey!) as? NSCache) }
        set { objc_setAssociatedObject(self, _cacheKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private func value<T>(_ key:UnsafeMutableRawPointer?, _ defaultValue:T) -> T {
        return (objc_getAssociatedObject(self, key!) as? T) ?? defaultValue
    }
    
    private func possiblyNil<T>(_ key:UnsafeMutableRawPointer?) -> T? {
        let result = objc_getAssociatedObject(self, key!)
        
        if result == nil {
            return nil
        }
        
        return (result as? T)
    }
}
open class GifManager {
    
    // A convenient default manager if we only have one gif to display here and there
    public static var defaultManager = GifManager(memoryLimit: 50)
    
    fileprivate var timer: CADisplayLink?
    fileprivate var displayViews: [UIImageView] = []
    fileprivate var totalGifSize: Int
    fileprivate var memoryLimit: Int
    open var haveCache: Bool
    open var remoteCache : [URL : Data] = [:]
    
    /// Initialize a manager
    ///
    /// - Parameter memoryLimit: The number of Mb max for this manager
    public init(memoryLimit: Int) {
        self.memoryLimit = memoryLimit
        totalGifSize = 0
        haveCache = true
    }
    
    deinit {
        stopTimer()
    }
    
    public func startTimerIfNeeded() {
        guard timer == nil else {
            return
        }
        
        timer = CADisplayLink(target: self, selector: #selector(updateImageView))
        
        #if swift(>=4.2)
        timer?.add(to: .main, forMode: .common)
        #else
        timer?.add(to: .main, forMode: RunLoopMode.commonModes)
        #endif
    }
    
    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Add a new imageView to this manager if it doesn't exist
    /// - Parameter imageView: The UIImageView we're adding to this manager
    open func addImageView(_ imageView: UIImageView) -> Bool {
        if containsImageView(imageView) {
            startTimerIfNeeded()
            return false
        }
        
        updateCacheSize(for: imageView, add: true)
        displayViews.append(imageView)
        startTimerIfNeeded()
        
        return true
    }
    
    /// Delete an imageView from this manager if it exists
    /// - Parameter imageView: The UIImageView we want to delete
    open func deleteImageView(_ imageView: UIImageView) {
        guard let index = displayViews.firstIndex(of: imageView) else {
            return
        }
        
        displayViews.remove(at: index)
        updateCacheSize(for: imageView, add: false)
    }
    
    open func updateCacheSize(for imageView: UIImageView, add: Bool) {
        totalGifSize += (add ? 1 : -1) * (imageView.gifImage?.imageSize ?? 0)
        haveCache = totalGifSize <= memoryLimit
        
        for imageView in displayViews {
            DispatchQueue.global(qos: .userInteractive).sync(execute: imageView.updateCache)
        }
    }
    
    open func clear() {
        displayViews.forEach { $0.clear() }
        displayViews = []
        stopTimer()
    }
    
    /// Check if an imageView is already managed by this manager
    /// - Parameter imageView: The UIImageView we're searching
    /// - Returns : a boolean for wether the imageView was found
    open func containsImageView(_ imageView: UIImageView) -> Bool{
        return displayViews.contains(imageView)
    }
    
    /// Check if this manager has cache for an imageView
    /// - Parameter imageView: The UIImageView we're searching cache for
    /// - Returns : a boolean for wether we have cache for the imageView
    open func hasCache(_ imageView: UIImageView) -> Bool{
        return imageView.displaying && (imageView.loopCount == -1 || imageView.loopCount >= 5) ? haveCache : false
    }
    
    /// Update imageView current image. This method is called by the main loop.
    /// This is what create the animation.
    @objc func updateImageView(){
        guard !displayViews.isEmpty else {
            stopTimer()
            return
        }
        
        for imageView in displayViews {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).sync {
                imageView.image = imageView.currentImage
            }
            
            if imageView.isAnimatingGif() {
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).sync(execute: imageView.updateCurrentImage)
            }
        }
    }
}
