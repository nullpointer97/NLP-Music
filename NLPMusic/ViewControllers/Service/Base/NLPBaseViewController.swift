//
//  BaseViewController.swift
//  VKM
//
//  Created by Ярослав Стрельников on 17.03.2021.
//

import Foundation
import UIKit
import SPAlert
import MaterialComponents

protocol BaseControllerProtocol {
    func setupBackground(for views: UIView...)
    func showEventMessage(_ type: PrintType, message: String)
    func showLoading(by loadIdentifier: String)
    func hideLoading(by loadIdentifier: String)
}

protocol VKMBaseItemDelegate: AnyObject {
    func didTap<T>(_ cell: NLPBaseViewCell<T>)
    func perform<T>(from cell: NLPBaseViewCell<T>)
    func logout<T>(from cell: NLPBaseViewCell<T>)
}

protocol NLPCollectionBaseItemDelegate: AnyObject {
    func didTap<T>(_ cell: NLPBaseCollectionViewCell<T>)
    func perform<T>(from cell: NLPBaseCollectionViewCell<T>)
    func logout<T>(from cell: NLPBaseCollectionViewCell<T>)
}

open class NLPBaseViewController: UIViewController, BaseControllerProtocol, VKMBaseItemDelegate {
    var observables: [Observable] = []
    
    var asdk_navigationViewController: NLPMNavigationController? {
        return navigationController as? NLPMNavigationController
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground(for: view)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    func setupNavigationItems(title: String?, leftItems: [UIBarButtonItem] = [], rightItems: [UIBarButtonItem] = []) {
        navigationItem.title = title
        navigationItem.leftBarButtonItems?.append(contentsOf: leftItems)
        navigationItem.rightBarButtonItems = rightItems
    }
    
    func setupUI() {
    }
    
    func openMenu(fromItem item: AudioPlayerItem, actions: [MDCActionSheetAction], title: String? = "Меню трека", message: String? = nil) {
        let actionSheet = MDCActionSheetController(title: title, message: message)
        actionSheet.backgroundColor = .secondarySystemBackground
        actionSheet.titleFont = .systemFont(ofSize: 21, weight: UIFont.Weight(0.3))
        actionSheet.titleTextColor = .label
        actionSheet.actionFont = .systemFont(ofSize: 16, weight: UIFont.Weight(0.25))
        
        for action in actions {
            actionSheet.addAction(action)
        }
        
        present(actionSheet, animated: true)
    }
    
    func openMenu(actions: [MDCActionSheetAction], title: String? = "Меню трека", message: String? = nil) {
        let actionSheet = MDCActionSheetController(title: title, message: message)
        actionSheet.backgroundColor = .secondarySystemBackground
        actionSheet.titleFont = .systemFont(ofSize: 21, weight: UIFont.Weight(0.3))
        actionSheet.titleTextColor = .label
        actionSheet.actionFont = .systemFont(ofSize: 16, weight: UIFont.Weight(0.25))
        
        for action in actions {
            actionSheet.addAction(action)
        }
        
        present(actionSheet, animated: true)
    }
    
    func showEventMessage(_ type: PrintType, message: String = "") {
        switch type {
        case .debug:
            SPAlert.present(title: "", message: message, preset: .done, haptic: .none)
        case .error:
            SPAlert.present(title: "Ошибка", message: message, preset: .error, haptic: .error)
        case .warning:
            SPAlert.present(title: "Внимание", message: message, preset: .custom((.init(named: "alert-triangle") ?? UIImage())), haptic: .warning)
        case .success:
            SPAlert.present(title: "Успешно", message: message, preset: .done, haptic: .success)
        }
    }
    
    func setBlurGradientImage(_ currentImage: UIImage?, _ inputPoint1: CGFloat = 0.6) -> UIImage? {
        let ciContext = CIContext(options: nil)

        if let currentImage = currentImage, let inputImage = CIImage(image: currentImage) {
            let extent = inputImage.extent

            let h = extent.size.height
            
            guard let gradient = CIFilter(name: "CILinearGradient") else { return nil }
            gradient.setValue(CIVector(x: 0, y: 0.2 * h), forKey: "inputPoint0")
            gradient.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 0.6), forKey: "inputColor0")
            gradient.setValue(CIVector(x: 0, y: inputPoint1 * h), forKey: "inputPoint1")
            gradient.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 0), forKey: "inputColor1")
            
            guard let mask = CIFilter(name: "CIMaskedVariableBlur") else { return nil }
            mask.setValue(inputImage.clampedToExtent(), forKey: kCIInputImageKey)

            mask.setValue(12, forKey: kCIInputRadiusKey)
            mask.setValue(gradient.outputImage, forKey: "inputMask")
            
            guard let output = mask.outputImage,
                  let cgImage = ciContext.createCGImage(output, from: extent) else { return nil }
            let image = UIImage(cgImage: cgImage)
            
            return image
        } else {
            return nil
        }
    }
    
    func showLoading(by loadIdentifier: String = "load") { }
    
    func hideLoading(by loadIdentifier: String = "load") { }
    
    func didTap<T>(_ cell: NLPBaseViewCell<T>) {
        view.endEditing(true)
    }
    
    func perform<T>(from cell: NLPBaseViewCell<T>) { }
    
    func logout<T>(from cell: NLPBaseViewCell<T>) { }
    
    func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        return nil
    }
    
    func updatePlayItem(byIndexPath indexPath: IndexPath) {
    }
}

extension UIDevice {
    /// Returns `true` if the device has a notch
    var hasNotch: Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
            let bottom = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.safeAreaInsets.bottom ?? 0
            return bottom > 0
        } else {
            return false
        }
    }
}
