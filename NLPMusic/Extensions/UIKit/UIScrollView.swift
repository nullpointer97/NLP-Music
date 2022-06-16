//
//  UIScrollView.swift
//  VKExt
//
//  Created by programmist_NA on 20.05.2020.
//

import Foundation
import UIKit
import CoreStore

enum ScrollDirection {
    case up
    case down
    case left
    case right
}

struct BatchUpdates {
    let deleted: [Int]
    let inserted: [Int]
    let moved: [(Int, Int)]
    let reloaded: [Int]

    init(deleted: [Int], inserted: [Int], moved: [(Int, Int)], reloaded: [Int] = []) {
        self.deleted = deleted
        self.inserted = inserted
        self.moved = moved
        self.reloaded = reloaded
    }

    static func switchArrays(oldCount: Int, newCount: Int) -> BatchUpdates {
        return BatchUpdates(deleted: Array(0..<oldCount), inserted: Array(0..<newCount), moved: [])
    }
}

extension UIView {
    var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
}

extension UITableView {
    func addStatusBarInset() {
        contentInset.top = statusBarHeight
    }
    
    func setBottomInset(to value: CGFloat, isReverse: Bool = false) {
        let edgeInset = UIEdgeInsets(top: isReverse ? value : 0, left: 0, bottom: isReverse ? 0 : value, right: 0)
        let point = CGPoint(x: 0, y: value)

        self.contentInset = edgeInset
        self.scrollIndicatorInsets = edgeInset
        self.contentOffset = point
    }
    
    var tableViewHeight: CGFloat {
        self.layoutIfNeeded()
        return self.contentSize.height
    }
    
    func getStringByDeclension(number: Int, arrayWords: [String?]) -> String {
        var resultString: String = ""
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
        return resultString
    }
    
    func reloadData(with batchUpdates: BatchUpdates, from section: Int) {
        beginUpdates()

        insertRows(at: batchUpdates.inserted
            .map { IndexPath(row: $0, section: section) }, with: .fade)
        deleteRows(at: batchUpdates.deleted
            .map { IndexPath(row: $0, section: section) }, with: .fade)
        reloadRows(at: batchUpdates.reloaded
            .map { IndexPath(row: $0, section: section) }, with: .fade)
        
        for movedRows in batchUpdates.moved {
            moveRow(at: IndexPath(row: movedRows.0, section: section),
                    to: IndexPath(row: movedRows.1, section: section))
        }

        endUpdates()
    }
    
    func reloadData(with batchUpdates: BatchUpdates) {
        beginUpdates()

        insertRows(at: batchUpdates.inserted
            .map { IndexPath(row: $0, section: 0) }, with: .fade)
        deleteRows(at: batchUpdates.deleted
            .map { IndexPath(row: $0, section: 0) }, with: .fade)
        reloadRows(at: batchUpdates.reloaded
            .map { IndexPath(row: $0, section: 0) }, with: .fade)
        
        for movedRows in batchUpdates.moved {
            moveRow(at: IndexPath(row: movedRows.0, section: 0),
                    to: IndexPath(row: movedRows.1, section: 0))
        }

        endUpdates()
    }
}
extension IndexPath {
    static func fromRow(_ row: Int) -> IndexPath {
        return IndexPath(row: row, section: 0)
    }
    
    static func fromItem(_ item: Int) -> IndexPath {
        return IndexPath(item: item, section: 0)
    }
}

extension UITableView {
    func applyChanges(with deletions: [Int], with insertions: [Int], with updates: [Int], at section: Int) {
        beginUpdates()
        deleteRows(at: deletions.map { IndexPath(row: $0, section: section) }, with: .fade)
        insertRows(at: insertions.map { IndexPath(row: $0, section: section) }, with: .fade)
        reloadRows(at: updates.map { IndexPath(row: $0, section: section) }, with: .none)
        endUpdates()
    }
    
    func isLastVisibleCell(at indexPath: IndexPath) -> Bool {
        guard let lastIndexPath = indexPathsForVisibleRows?.last else {
            return false
        }
        return lastIndexPath == indexPath
    }
}
extension UICollectionView {
    func applyChanges(deletions: [Int], insertions: [Int], updates: [Int], isSectionUpdate: Bool) {
        if isSectionUpdate {
            performBatchUpdates({
                _ = deletions.map { deleteSections(IndexSet(integer: $0)) }
                _ = insertions.map { insertSections(IndexSet(integer: $0)) }
                _ = updates.map { reloadSections(IndexSet(integer: $0)) }
            })
        } else {
            performBatchUpdates({
                deleteItems(at: deletions.map { IndexPath(item: $0, section: 0) })
                insertItems(at: insertions.map { IndexPath(item: $0, section: 0) })
                reloadItems(at: updates.map { IndexPath(item: $0, section: 0) })
            })
        }
    }
}
extension UITableViewCell {
    static var identifier: String {
        return String(describing: self)
    }
}
extension UITableView {
    /**
     * Returns all cells in a table
     * ## Examples:
     * tableView.cells // array of cells in a tableview
     */
    public var cells: [UITableViewCell] {
      (0..<self.numberOfSections).indices.map { (sectionIndex: Int) -> [UITableViewCell] in
          (0..<self.numberOfRows(inSection: sectionIndex)).indices.compactMap { (rowIndex: Int) -> UITableViewCell? in
              self.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex))
          }
      }.flatMap { $0 }
    }
    
    func dequeue<T: UITableViewCell>(for indexPath: IndexPath) -> T? {
        return dequeueReusableCell(withIdentifier: T.identifier, for: indexPath) as? T
    }
}
extension UICollectionView {
    func setBottomInset(to value: CGFloat, isReverse: Bool = false) {
        let edgeInset = UIEdgeInsets(top: isReverse ? value : 0, left: 0, bottom: isReverse ? 0 : value, right: 0)
        let point = CGPoint(x: 0, y: value)

        self.contentInset = edgeInset
        self.scrollIndicatorInsets = edgeInset
        guard !isReverse else { return }
        self.contentOffset = point
    }
    
    func setBottomOffset(to value: CGFloat) {
        let point = CGPoint(x: 0, y: value)
        self.contentOffset = point
    }
    
    var collectionViewHeight: CGFloat {
        self.layoutIfNeeded()
        return self.contentSize.height
    }
    
    func getStringByDeclension(number: Int, arrayWords: [String?]) -> String {
        var resultString: String = ""
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
        return resultString
    }
}
extension UIScrollView {
    var reversedContentOffset: CGPoint {
        get { return reversedContentOffset(for: contentOffset) }
        set { contentOffset = reversedContentOffset(for: newValue) }
    }

    func setReversedContentOffset(_ reversedContentOffset: CGPoint, animated: Bool) {
        setContentOffset(self.reversedContentOffset(for: reversedContentOffset), animated: animated)
    }

    private func reversedContentOffset(for contentOffset: CGPoint) -> CGPoint {
        return CGPoint(
            x: contentSize.width - contentOffset.x - min(visibleSize.width, contentSize.width),
            y: contentSize.height - contentOffset.y - min(visibleSize.height, contentSize.height)
        )
    }

    private var visibleSize: CGSize {
        return CGSize(
            width: frame.width - contentInset.left - contentInset.right,
            height: frame.height - contentInset.top - contentInset.bottom
        )
    }

    var scrollDirection: ScrollDirection {
        let translation = panGestureRecognizer.translation(in: superview)
        if translation.y > 0 {
            return .down
        } else if translation.y < 0 {
            return .up
        } else if translation.x > 0 {
            return .right
        } else {
            return .left
        }
    }
}
