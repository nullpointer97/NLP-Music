//
//  Collection+Extension.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 30.10.2020.
//

import Foundation

extension ArraySlice {
    func toArray() -> [Element] {
        return Array(self)
    }
}
extension Sequence where Element: AdditiveArithmetic {
    /// Returns the total sum of all elements in the sequence
    func sum() -> Element { reduce(.zero, +) }
}
extension Collection where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    func average() -> Element { isEmpty ? .zero : sum() / Element(count) }
    /// Returns the average of all elements in the array as Floating Point type
    func average<T: FloatingPoint>() -> T { isEmpty ? .zero : T(sum()) / T(count) }
}
extension Collection where Element: BinaryFloatingPoint {
    /// Returns the average of all elements in the array
    func average() -> Element { isEmpty ? .zero : Element(sum()) / Element(count) }
}

extension Sequence where Element: Hashable {
    func duplicates() -> [Element] {
        var set = Set<Element>()
        return filter { !set.insert($0).inserted }
    }
    
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension Array {
    func element(toIndex index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

extension UINib {
    static func listCell(_ cell: ListViewCell) -> UINib? {
        return UINib(nibName: cell.rawValue, bundle: nil)
    }
}

extension String {
    static func listCell(_ cell: ListViewCell) -> String {
        return cell.rawValue
    }
}
