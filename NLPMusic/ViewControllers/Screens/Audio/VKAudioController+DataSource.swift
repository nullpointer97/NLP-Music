//
//  VKAudioController+DataSource.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 03.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import CoreStore
import AsyncDisplayKit

final class EditableDataSource<T: DynamicObject>: DiffableDataSource.TableViewAdapter<T> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

final class AudioDataSource<T: DynamicObject>: DiffableDataSource.TableNodeAdapter<T> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension DiffableDataSource {
    open class TableNodeAdapter<O: DynamicObject>: BaseAdapter<O, DefaultTableNodeTarget<ASTableNode>>, ASTableDataSource {
        
        // MARK: Public
        
        /**
         Initializes the `DiffableDataSource.TableViewAdapter`. This instance needs to be held on (retained) for as long as the `UITableView`'s lifecycle.
         ```
         self.dataSource = DiffableDataSource.TableViewAdapter<Person>(
         tableView: self.tableView,
         dataStack: CoreStoreDefaults.dataStack,
         cellProvider: { (tableView, indexPath, person) in
         let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell") as! PersonCell
         cell.setPerson(person)
         return cell
         }
         )
         ```
         - parameter tableView: the `UITableView` to set the `dataSource` of. This instance is not retained by the `DiffableDataSource.TableViewAdapter`.
         - parameter dataStack: the `DataStack` instance that the dataSource will fetch objects from
         - parameter cellProvider: a closure that configures and returns the `UITableViewCell` for the object
         */
        public init(
            tableNode: ASTableNode,
            dataStack: DataStack,
            cellProvider: @escaping (ASTableNode, IndexPath, O) -> ASCellNode?
        ) {
            
            self.cellProvider = cellProvider
            super.init(target: .init(tableNode), dataStack: dataStack)
            
            tableNode.dataSource = self
        }
        
        /**
         The target `UITableView`
         */
        public var tableNode: ASTableNode? {
            
            return self.target.base
        }
        
        
        // MARK: - UITableViewDataSource
        
        @objc
        @MainActor
        public dynamic func numberOfSections(in tableNode: ASTableNode) -> Int {
            return self.numberOfSections()
        }
        
        @objc
        @MainActor
        public dynamic func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
            return self.numberOfItems(inSection: section) ?? 0
        }
        
        @objc
        @MainActor
        open dynamic func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return self.sectionID(for: section)
        }
        
        @objc
        @MainActor
        open dynamic func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            return nil
        }
        
        @objc
        @MainActor
        open dynamic func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
            guard let objectID = self.itemID(for: indexPath) else {
                fatalError("Object at \("'\(String(reflecting: type(of: IndexPath.self)))'") \(indexPath) already removed from list")
            }
            guard let object = self.dataStack.fetchExisting(objectID) as O? else {
                fatalError("Object at \("'\(String(reflecting: type(of: IndexPath.self)))'") \(indexPath) has been deleted")
            }
            guard let node = self.cellProvider(tableNode, indexPath, object) else {
                fatalError("\("'\(String(reflecting: type(of: ASTableDataSource.self)))'") returned a `nil` cell for \("'\(String(reflecting: type(of: IndexPath.self)))'") \(indexPath)")
            }
            return node
        }
        
        @objc
        @MainActor
        open dynamic func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        @objc
        @MainActor
        open dynamic func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            return .delete
        }
        
        @objc
        @MainActor
        open dynamic func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {}
        
        @objc
        @MainActor
        open dynamic func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            return nil
        }
        
        @objc
        @MainActor
        open dynamic func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
            return index
        }
        
        
        // MARK: Private
        
        @nonobjc
        private let cellProvider: (ASTableNode, IndexPath, O) -> ASCellNode?
    }
    
    
    // MARK: - DefaultTableViewTarget
    
    public struct DefaultTableNodeTarget<T: ASTableNode>: Target {
        
        // MARK: Public
        
        public typealias Base = T
        
        public private(set) weak var base: Base?
        
        public init(_ base: Base) {
            
            self.base = base
        }
        
        
        // MARK: DiffableDataSource.Target
        
        public var shouldSuspendBatchUpdates: Bool {
            
            return self.base?.view.window == nil
        }
        
        public func deleteSections(at indices: IndexSet, animated: Bool) {
            
            self.base?.deleteSections(indices, with: .automatic)
        }
        
        public func insertSections(at indices: IndexSet, animated: Bool) {
            
            self.base?.insertSections(indices, with: .automatic)
        }
        
        public func reloadSections(at indices: IndexSet, animated: Bool) {
            
            self.base?.reloadSections(indices, with: .automatic)
        }
        
        public func moveSection(at index: IndexSet.Element, to newIndex: IndexSet.Element, animated: Bool) {
            
            self.base?.moveSection(index, toSection: newIndex)
        }
        
        public func deleteItems(at indexPaths: [IndexPath], animated: Bool) {
            
            self.base?.deleteRows(at: indexPaths, with: .automatic)
        }
        
        public func insertItems(at indexPaths: [IndexPath], animated: Bool) {
            
            self.base?.insertRows(at: indexPaths, with: .automatic)
        }
        
        public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {
            
            self.base?.reloadRows(at: indexPaths, with: .automatic)
        }
        
        public func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath, animated: Bool) {
            
            self.base?.moveRow(at: indexPath, to: newIndexPath)
        }
        
        public func performBatchUpdates(updates: () -> Void, animated: Bool, completion: @escaping () -> Void) {
            
            guard let base = self.base else {
                
                return
            }
            base.performBatchUpdates(updates, completion: { _ in completion() })
        }
        
        public func reloadData() {
            
            self.base?.reloadData()
        }
    }
}
