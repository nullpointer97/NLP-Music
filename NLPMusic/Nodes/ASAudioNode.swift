//
//  ASAudioNode.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 09.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import UIKit
import Lottie

protocol ASItemDelegate: AnyObject {
    func didTap(_ node: ASAudioNode)
}

protocol ASAudioItemActionDelegate: AnyObject {
    func didSaveAudio(_ item: AudioItem)
}

protocol ASMenuDelegate: AnyObject {
    func didOpenMenu(_ node: ASAudioNode)
}

class ASAudioNode: ASCellNode {
    var artworkImageNode = ASNetworkImageNode()
    var playingAnimationNode = ASAnimationNode(animation: "playing", scale: 1)
    
    let titleNode = ASTextNode()
    let artistLabelNode = ASTextNode()
    
    let downloadNode = ASImageNode()
    let moreNode = ASButtonNode()
    
    weak var menuDelegate: ASMenuDelegate?
    weak var itemDelegate: ASItemDelegate?
    
    var isDownload: Bool
    var isPlaying: Bool
    var isPaused: Bool
    
    var imageUrl: URL?
    
    var audio: ASAudioItem
    
    init(_ audio: ASAudioItem) {
        self.audio = audio
        isDownload = audio.isDownload
        isPlaying = audio.isPlaying
        isPaused = audio.isPaused

        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        
        moreNode.setImage(.init(named: "more-horizontal")?.tint(with: .secondBlack), for: .normal)
        moreNode.setTitle("", with: nil, with: nil, for: .normal)

        downloadNode.image = UIImage(named: "arrow.down.circle.fill")?.tint(with: .secondarySystemFill)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: (isPaused || isPlaying) ? .semibold : .medium),
            .foregroundColor: UIColor.label
        ]
        
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: (isPaused || isPlaying) ? .medium : .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]

        titleNode.attributedText = NSAttributedString(string: audio.title, attributes: attributes)
        artistLabelNode.attributedText = NSAttributedString(string: audio.artist, attributes: secondAttributes)

        if let url = URL(string: audio.artworkUrl) {
            artworkImageNode.url = url
        } else {
            artworkImageNode.image = .init(named: "missing_song_artwork_generic_proxy")
        }
        
        automaticallyManagesSubnodes = true

        moreNode.addTarget(self, action: #selector(onOpenMenu(_:)), forControlEvents: .touchUpInside)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        artworkImageNode.style.preferredSize = .custom(48, 48)
        artworkImageNode.cornerRadius = 4

        downloadNode.style.preferredSize = .custom(18, 18)

        moreNode.style.preferredSize = .custom(32, 32)
        
        titleNode.maximumNumberOfLines = 1
        artistLabelNode.maximumNumberOfLines = 1

        titleNode.style.flexShrink = 1
        artistLabelNode.style.flexShrink = 1
        
        titleNode.style.flexGrow = 1
        artistLabelNode.style.flexGrow = 1
        
        let firstStack = ASStackLayoutSpec.horizontal()

        firstStack.alignItems = .center
        firstStack.justifyContent = .start
        firstStack.style.flexShrink = 1
        firstStack.style.flexGrow = 1
        firstStack.children = [artworkImageNode]
        firstStack.style.preferredSize = .custom(48, 48)
        
        let secondStack = ASStackLayoutSpec(direction: .vertical, spacing: 2, justifyContent: .spaceBetween, alignItems: .start, flexWrap: .noWrap, alignContent: .center, children: [titleNode, artistLabelNode])
        secondStack.style.flexShrink = 1
        secondStack.style.flexGrow = 1
        secondStack.style.preferredSize = CGSize(width: screenWidth - (isDownload ? 166 : 140), height: 38.5)
        
        let thirdStack = ASStackLayoutSpec(direction: .horizontal, spacing: 8, justifyContent: .spaceBetween, alignItems: .center, flexWrap: .noWrap, alignContent: .center, children: isDownload ? [downloadNode, moreNode] : [moreNode])
        thirdStack.style.flexShrink = 1
        thirdStack.style.flexGrow = 1
        thirdStack.style.preferredSize = CGSize(width: 58, height: 32)

        let nodeStack = ASStackLayoutSpec.horizontal()
        
        nodeStack.children = [
            ASInsetLayoutSpec(insets: .init(top: 0, left: 16, bottom: 0, right: 8), child: firstStack),
            ASInsetLayoutSpec(insets: .init(top: 0, left: 8, bottom: 0, right: 0), child: secondStack),
            ASInsetLayoutSpec(insets: .init(top: 0, left: 8, bottom: 0, right: 16), child: thirdStack)
        ]

        nodeStack.alignContent = .center
        nodeStack.alignItems = .center
        nodeStack.justifyContent = .start
        nodeStack.style.alignSelf = .start
        nodeStack.style.flexShrink = 1
        return nodeStack
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        didTapAudio()
    }
    
    @objc func didTapAudio() {
        itemDelegate?.didTap(self)
    }

    @objc func onOpenMenu(_ sender: UIButton) {
        menuDelegate?.didOpenMenu(self)
    }
}

public final class ASAnimationNode: ASDisplayNode {
    private let scale: CGFloat
    public var speed: CGFloat = 1.0 {
        didSet {
            if let animationView = animationView() {
                animationView.animationSpeed = speed
            }
        }
    }

    public var didPlay = false
    public var completion: (() -> Void)?
    private var internalCompletion: (() -> Void)?
    
    public var isPlaying: Bool {
        return self.animationView()?.isAnimationPlaying ?? false
    }
    
    private var currentParams: (String?)?
    
    public init(animation: String? = nil, scale: CGFloat = 1.0) {
        self.scale = scale
        self.currentParams = (animation)
        
        super.init()
        
        self.setViewBlock({
            if let animation = animation {
                let view = AnimationView(animation: Animation.named(animation))
                view.animationSpeed = self.speed
                view.loopMode = .loop
                view.backgroundColor = .black.withAlphaComponent(0.4)
                view.isOpaque = false
                
                return view
            } else {
                return AnimationView()
            }
        })
    }
    
    public func makeCopy(progress: CGFloat? = nil) -> ASAnimationNode? {
        guard let (animation) = self.currentParams else {
            return nil
        }
        let animationNode = ASAnimationNode(animation: animation, scale: 1.0)
        animationNode.animationView()?.play(fromProgress: progress ?? (self.animationView()?.currentProgress ?? 0.0), toProgress: 1.0, completion: { [weak animationNode] _ in
            animationNode?.completion?()
        })
        return animationNode
    }
    
    public func seekToEnd() {
        self.animationView()?.currentProgress = 1.0
    }
    
    public func setAnimation(animation: String?) {
        self.currentParams = (animation)
        if animation != nil {
            self.didPlay = false
        }
    }
    
    public func animationView() -> AnimationView? {
        return self.view as? AnimationView
    }
    
    public func play() {
        if let animationView = self.animationView(), !animationView.isAnimationPlaying && !self.didPlay {
            self.didPlay = true
            animationView.play { [weak self] _ in
                self?.completion?()
            }
        }
    }
    
    public func pause() {
        if let animationView = self.animationView(), !animationView.isAnimationPlaying && self.didPlay {
            self.didPlay = false
            animationView.stop()
        }
    }
    
    public func stop() {
        if let animationView = self.animationView(), !animationView.isAnimationPlaying && self.didPlay {
            self.didPlay = false
            animationView.stop()
        }
    }
    
    public func playOnce() {
        if let animationView = self.animationView(), !animationView.isAnimationPlaying && !self.didPlay {
            self.didPlay = true
            self.internalCompletion = { [weak self] in
                self?.didPlay = false
            }
            animationView.play { [weak self] _ in
                self?.internalCompletion?()
            }
        }
    }
    
    public func loop() {
        if let animationView = self.animationView() {
            animationView.play()
        }
    }
    
    public func reset() {
        if self.didPlay, let animationView = animationView() {
            self.didPlay = false
            animationView.stop()
        }
    }
    
    public func preferredSize() -> CGSize? {
        if let animationView = animationView() {
            return CGSize(width: animationView.bounds.width * self.scale, height: animationView.bounds.height * self.scale)
        } else {
            return nil
        }
    }
}

private let colorKeyRegex = try? NSRegularExpression(pattern: "\"k\":\\[[\\d\\.]+\\,[\\d\\.]+\\,[\\d\\.]+\\,[\\d\\.]+\\]")

public func transformedWithColors(data: Data, colors: [(UIColor, UIColor)]) -> Data {
    if var string = String(data: data, encoding: .utf8) {
        let sourceColors: [UIColor] = colors.map { $0.0 }
        let replacementColors: [UIColor] = colors.map { $0.1 }
        
        func colorToString(_ color: UIColor) -> String {
            var r: CGFloat = 0.0
            var g: CGFloat = 0.0
            var b: CGFloat = 0.0
            if color.getRed(&r, green: &g, blue: &b, alpha: nil) {
                return "\"k\":[\(r),\(g),\(b),1]"
            }
            return ""
        }
        
        func match(_ a: Double, _ b: Double, eps: Double) -> Bool {
            return abs(a - b) < eps
        }
        
        var replacements: [(NSTextCheckingResult, String)] = []
        
        if let colorKeyRegex = colorKeyRegex {
            let results = colorKeyRegex.matches(in: string, range: NSRange(string.startIndex..., in: string))
            for result in results.reversed()  {
                if let range = Range(result.range, in: string) {
                    let substring = String(string[range])
                    let color = substring[substring.index(string.startIndex, offsetBy: "\"k\":[".count) ..< substring.index(before: substring.endIndex)]
                    let components = color.split(separator: ",")
                    if components.count == 4, let r = Double(components[0]), let g = Double(components[1]), let b = Double(components[2]), let a = Double(components[3]) {
                        if match(a, 1.0, eps: 0.01) {
                            for i in 0 ..< sourceColors.count {
                                let color = sourceColors[i]
                                var cr: CGFloat = 0.0
                                var cg: CGFloat = 0.0
                                var cb: CGFloat = 0.0
                                if color.getRed(&cr, green: &cg, blue: &cb, alpha: nil) {
                                    if match(r, Double(cr), eps: 0.01) && match(g, Double(cg), eps: 0.01) && match(b, Double(cb), eps: 0.01) {
                                        replacements.append((result, colorToString(replacementColors[i])))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for (result, text) in replacements {
            if let range = Range(result.range, in: string) {
                string = string.replacingCharacters(in: range, with: text)
            }
        }
        
        return string.data(using: .utf8) ?? data
    } else {
        return data
    }
}

func getAppBundle() -> Bundle {
    var bundle: Bundle! = Bundle.main
    if (bundle.bundleURL.pathExtension == "appex") {
        bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())
    } else if (bundle.bundleURL.pathExtension == "framework") {
        bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())
    } else if (bundle.bundleURL.pathExtension == "Frameworks") {
        bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent())
    }
    return bundle
}

extension UIImage {
    convenience init?(bundleImageName: String) {
        self.init(named: bundleImageName, in: getAppBundle(), compatibleWith: nil)
    }
}
