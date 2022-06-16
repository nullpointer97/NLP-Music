//
//  FlexColorPickerController.swift
//  FlexColorPicker
//
//  Created by Rastislav Mirek on 27/5/18.
//  
//	MIT License
//  Copyright (c) 2018 Rastislav Mirek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

/// Customizable color picker view controller that can be subclassed or used from interface builder (or both). This class basically just delegates its exposed properties to wrapped `ColorPickerController`. It is convinience to support common practise that uses view controllers to attach outlets to.
///
/// When color controls are set to properties of this view controller via code or interface builder, they become managed by underlaying instance of `ColorPickerController` and thus their value (selected color) is synchronized.
///
/// **See also:**
/// [DefaultColorPickerViewController](https://github.com/RastislavMirek/FlexColorPicker/blob/master/FlexColorPicker/Classes/DefaultColorPickerViewController.swift), [ColorPickerController](https://github.com/RastislavMirek/FlexColorPicker/blob/master/FlexColorPicker/Classes/ColorPickerController.swift)
open class NLPColorPickerViewController: NLPModalViewController, ColorPickerControllerProtocol {
    override public var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(0)
    }
    
    override public var shortFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(0)
    }
    
    public override var panScrollable: UIScrollView? {
        return scrollView
    }
    
    var stdColors: [UIColor] = [
        .color(from: 0x2979ff),
        .color(from: 0x8167c5),
        .color(from: 0xfec656),
        .color(from: 0x1e9f60),
        .color(from: 0xfe784b),
        .color(from: 0x6b7077)
    ]
    
    /// Color picker controller that synchonizes color controls. This is backing controller that this controller delegates interaction logic to. It is also instance of `ColorPickerController` passed to delegate calls.
    public let colorPicker = ColorPickerController()

    /// Color picker delegate that gets called when selected color is updated or confirmed. The delegate is not retained. This is just convinience property and getting or setting it is equivalent to getting or setting `colorPicker.delegate`.
    open var delegate: ColorPickerDelegate? {
        get {
            return colorPicker.delegate
        }
        set {
            colorPicker.colorPickerController = self
            colorPicker.delegate = newValue
        }
    }

    /// Color currently selected by color picker.
    @IBInspectable
    open var selectedColor: UIColor {
        get {
            return colorPicker.selectedColor
        }
        set {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) { [weak self] in
                self?.colorPicker.selectedColor = newValue
                self?.colorSelectButton?.backgroundColor = newValue
            }
        }
    }

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet public var colorPreview: ColorPreviewWithHex? {
        get {
            return colorPicker.colorPreview
        }
        set {
            colorPicker.colorPreview = newValue
        }
    }

    @IBOutlet open var radialHsbPalette: RadialPaletteControl? {
        get {
            return colorPicker.radialHsbPalette
        }
        set {
            colorPicker.radialHsbPalette = newValue
        }
    }

    @IBOutlet open var rectangularHsbPalette: RectangularPaletteControl? {
        get {
            return colorPicker.rectangularHsbPalette
        }
        set {
            colorPicker.rectangularHsbPalette = newValue
        }
    }

    @IBOutlet open var saturationSlider: SaturationSliderControl? {
        get {
            return colorPicker.saturationSlider
        }
        set {
            colorPicker.saturationSlider = newValue
        }
    }

    @IBOutlet open var brightnessSlider: BrightnessSliderControl? {
        get {
            return colorPicker.brightnessSlider
        }
        set {
            colorPicker.brightnessSlider = newValue
        }
    }

    @IBOutlet open var redSlider: RedSliderControl? {
        get {
            return colorPicker.redSlider
        }
        set {
            colorPicker.redSlider = newValue
        }
    }

    @IBOutlet open var greenSlider: GreenSliderControl? {
        get {
            return colorPicker.greenSlider
        }
        set {
            colorPicker.greenSlider = newValue
        }
    }

    @IBOutlet open var blueSlider: BlueSliderControl? {
        get {
            return colorPicker.blueSlider
        }
        set {
            colorPicker.blueSlider = newValue
        }
    }

    @IBOutlet open var customControl1: AbstractColorControl? {
        get {
            return colorPicker.customControl1
        }
        set {
            colorPicker.customControl1 = newValue
        }
    }

    @IBOutlet open var customControl2: AbstractColorControl? {
        get {
            return colorPicker.customControl2
        }
        set {
            colorPicker.customControl2 = newValue
        }
    }

    @IBOutlet open var customControl3: AbstractColorControl? {
        get {
            return colorPicker.customControl3
        }
        set {
            colorPicker.customControl3 = newValue
        }
    }

    @IBOutlet weak var colorSelectButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var purpleButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var grayButton: UIButton!
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground.withAlphaComponent(0.1)
        view.setBlurBackground(style: .regular)
        
        saturationSlider?.hitBoxInsets = UIEdgeInsets(top: defaultHitBoxInset, left: 20, bottom: defaultHitBoxInset, right: 20)
        brightnessSlider?.hitBoxInsets = UIEdgeInsets(top: defaultHitBoxInset, left: 20, bottom: defaultHitBoxInset, right: 20)
        
        colorSelectButton.backgroundColor = .getAccentColor(fromType: .common)
        colorSelectButton.drawBorder(10, width: 0)
        
        let saturation: CGFloat = selectedColor.getSaturation()
        colorSelectButton.setTitleColor(saturation < 0.3 ? .black : .white, for: .normal)
        colorSelectButton.setTitleColor(saturation < 0.3 ? .black : .white, for: .selected)
        colorSelectButton.setTitleColor(saturation < 0.3 ? .black : .white, for: .highlighted)

        colorSelectButton.setTitle("Выбрать цвет", for: .normal)
        colorSelectButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        
        titleLabel.text = "Цвет акцента"
        
        dismissButton.setTitle("", for: .normal)
        dismissButton.backgroundColor = .secondaryPopupFill.withAlphaComponent(0.2)
        dismissButton.drawBorder(15, width: 0)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        blueButton.drawBorder(stackView.bounds.height / 2, width: 1, color: .adaptableBorder)
        purpleButton.drawBorder(stackView.bounds.height / 2, width: 1, color: .adaptableBorder)
        yellowButton.drawBorder(stackView.bounds.height / 2, width: 1, color: .adaptableBorder)
        greenButton.drawBorder(stackView.bounds.height / 2, width: 1, color: .adaptableBorder)
        orangeButton.drawBorder(stackView.bounds.height / 2, width: 1, color: .adaptableBorder)
        grayButton.drawBorder(stackView.bounds.height / 2, width: 1, color: .adaptableBorder)
    }
    
    @IBAction func didSelectColor(_ sender: Any) {
        delegate?.colorPicker(self, confirmedColor: colorPicker.selectedColor, usingControl: radialHsbPalette!)
        dismiss(animated: true)
    }
    
    @IBAction func dismissPopup(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func setDefaultBlue(_ sender: Any) {
        selectedColor = stdColors[0]
    }
    
    @IBAction func setDefaultPurple(_ sender: Any) {
        selectedColor = stdColors[1]
    }
    
    @IBAction func setDefaultYellow(_ sender: Any) {
        selectedColor = stdColors[2]
    }
    
    @IBAction func setDefaultGreen(_ sender: Any) {
        selectedColor = stdColors[3]
    }
    
    @IBAction func setDefaultOrange(_ sender: Any) {
        selectedColor = stdColors[4]
    }
    
    @IBAction func setDefaultGray(_ sender: Any) {
        selectedColor = stdColors[5]
    }
}
