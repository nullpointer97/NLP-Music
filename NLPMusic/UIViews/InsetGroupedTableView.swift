//
//  InsetGroupedTableView.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 29.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

var kTOInsetGroupedTableViewFrameKey: String = "frame"
var kTOInsetGroupedTableViewSelectedKey: String = "selected"
var kTOInsetGroupedTableViewCornerRadius: CGFloat = 10

open class NLPGroupedTableView: UITableView {
    var observedViews: NSMutableSet = []
    var realSeparatorStyle: Int = 0
    
    init() {
        let frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        
        if #unavailable(iOS 13.0) {
            super.init(frame: frame, style: .grouped)
            commonInit()
        } else {
            super.init(frame: frame, style: .insetGrouped)
        }
    }
    
    public override init(frame: CGRect, style: UITableView.Style) {
        if #unavailable(iOS 13.0) {
            super.init(frame: frame, style: .grouped)
            commonInit()
        } else {
            super.init(frame: frame, style: .insetGrouped)
        }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        if style.rawValue < UITableView.Style.grouped.rawValue {
            let reason: String = "InsetGroupedTableView: Make sure the table view style is set to \"Inset Grouped\" in Interface Builder"
            NSException(name: .internalInconsistencyException, reason: reason, userInfo: nil).raise()
        }
        
        if #unavailable(iOS 13.0) {
            commonInit()
        }
    }
    
    deinit {
        removeAllObservers()
    }
    
    open override var separatorStyle: UITableViewCell.SeparatorStyle {
        get {
            if realSeparatorStyle > -1 {
                return UITableViewCell.SeparatorStyle(rawValue: realSeparatorStyle) ?? .none
            }
            return super.separatorStyle
        }
        set(separatorStyle) {
            if separatorStyle == .none {
                // make sure there will be _UITableViewCellSeparatorView in cell's subViews
                separatorColor = UIColor.clear
                realSeparatorStyle = UITableViewCell.SeparatorStyle.none.rawValue
                return
            }
            realSeparatorStyle = -1
            super.separatorStyle = separatorStyle
        }
    }
    
    private func commonInit() {
        insetsContentViewsToSafeArea = false
    }
    
    open override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        if #unavailable(iOS 13.0) {
            if !subview.isKind(of: UITableViewHeaderFooterView.self) && !subview.isKind(of: UITableViewCell.self) {
                return
            }
        }
        
        addObserverIfNeeded(subview)
    }
    
    private func addObserverIfNeeded(_ subview: UIView) {
        if #unavailable(iOS 13.0) {
            if observedViews.contains(subview) {
                return
            }
            
            subview.addObserver(self, forKeyPath: kTOInsetGroupedTableViewFrameKey, options: .new, context: nil)
            
            if subview.isKind(of: UITableViewCell.self) {
                subview.addObserver(self, forKeyPath: kTOInsetGroupedTableViewSelectedKey, options: .new, context: nil)
            }
        }
    }
    
    private func removeAllObservers() {
        if #unavailable(iOS 13.0) {
            for view in observedViews {
                if let view = view as? UIView {
                    view.removeObserver(self, forKeyPath: kTOInsetGroupedTableViewFrameKey, context: nil)
                    
                    if view.isKind(of: UITableViewCell.self) {
                        view.removeObserver(self, forKeyPath: kTOInsetGroupedTableViewSelectedKey, context: nil)
                    }
                }
            }
        }
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let view = object as? UIView else { return }
        
        if keyPath == kTOInsetGroupedTableViewFrameKey {
            performInsetLayoutForView(view: view)
        } else if keyPath == kTOInsetGroupedTableViewSelectedKey {
            applyRoundedCornersToTableViewCell(cell: view as! UITableViewCell)
        }
    }
    
    private func performInsetLayoutForView(view: UIView) {
        var frame: CGRect = view.frame
        let margins: UIEdgeInsets = layoutMargins
        let safeAreaInsets: UIEdgeInsets = safeAreaInsets

        var leftInset: CGFloat = margins.left
        if leftInset - safeAreaInsets.left < 0.0 - CGFloat(Float.ulpOfOne) {
            leftInset += safeAreaInsets.left
        }
        
        var rightInset: CGFloat = margins.right
        if rightInset - safeAreaInsets.right < 0.0 - CGFloat(Float.ulpOfOne) {
            rightInset += safeAreaInsets.right
        }
        
        frame.origin.x = leftInset
        frame.size.width = frame.width - (leftInset + rightInset)

        view.layer.frame = frame
    }
    
    private func applyRoundedCornersToTableViewCell(cell: UITableViewCell) {
        cell.layer.masksToBounds = true
        
        var topRounded: Bool = false
        var bottomRounded: Bool = false

        let separatorHeight: CGFloat = 1.0

        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        for subview in cell.subviews {
            let frame: CGRect = subview.frame
            
            if frame.size.height > separatorHeight { continue }
            
            if frame.origin.x > CGFloat(Float.ulpOfOne) {
                subview.isHidden = false
                continue
            }
            
            if frame.origin.y < CGFloat(Float.ulpOfOne) {
                topRounded = true
            } else {
                bottomRounded = true
            }

            subview.isHidden = true
        }
        
        let needsRounding:Bool = (topRounded || bottomRounded)
        
        cell.layer.cornerRadius = needsRounding ? kTOInsetGroupedTableViewCornerRadius : 0.0
         
        var cornerRoundingFlags: CACornerMask = []
        if topRounded {
            cornerRoundingFlags = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        if bottomRounded {
            cornerRoundingFlags = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        cell.layer.maskedCorners = cornerRoundingFlags
    }
}
