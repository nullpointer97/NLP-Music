//
//  UITableViewCell.swift
//  VKExt
//
//  Created by programmist_NA on 22.05.2020.
//

import Foundation
import UIKit

extension UITableViewCell {
    func animated<T: UIView>(_ object: T, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .preferredFramesPerSecond60], animations: {
            animations()
            object.layoutIfNeeded()
        }, completion: completion)
    }
}
func getStringByDeclension(number: Int, arrayWords: [String?]) -> String {
    var resultString: String = ""
    let numberString = "\(number.k)"
    let number = number % 100
    if number >= 11 && number <= 19 {
        resultString = arrayWords[2]!
    } else {
        let i: Int = number % 10
        switch i {
        case 1: resultString = arrayWords[0]!
            break
        case 2, 3, 4:
            resultString = arrayWords[1]!
            break
        default:
            resultString = arrayWords[2]!
            break
        }
    }
    return "\(numberString) \(resultString)"
}
extension UICollectionViewCell {

    func prepareForComputingHeight() {
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        setNeedsLayout()
        layoutIfNeeded()
        prepareForReuse()
    }

    func computeHeight(forWidth width: CGFloat) -> CGFloat {
        bounds = {
            var bounds = self.bounds
            bounds.size.width = width
            return bounds
        }()
        setNeedsLayout()
        layoutIfNeeded()
        let targetSize = CGSize(width: width, height: 0)
        let fittingSize = systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: UILayoutPriority.defaultHigh,
            verticalFittingPriority: UILayoutPriority.fittingSizeLevel
        )
        return fittingSize.height
    }

}
