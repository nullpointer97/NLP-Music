//
//  AttachmentTapGestureRecognizer.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.12.2020.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Recognizes a tap on an attachment, on a UITextView.
/// The UITextView normally only informs its delegate of a tap on an attachment if the text view is not editable, or a long tap is used.
/// If you want an editable text view, where you can short cap an attachment, you have a problem.
/// This gesture recognizer can be added to the text view, and will add requirments in order to recognize before any built-in recognizers.
class AttachmentTapGestureRecognizer: UIGestureRecognizer {

    /// Character index of the attachment just tapped
    private(set) var attachmentCharacterIndex: Int?

    /// The attachment just tapped
    private(set) var attachment: NSTextAttachment?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        attachmentCharacterIndex = nil
        attachment = nil

        let textView = view as! UITextView
        if touches.count == 1, let touch = touches.first, touch.tapCount == 1 {
            let point = touch.location(in: textView)
            let glyphIndex: Int? = textView.layoutManager.glyphIndex(for: point, in: textView.textContainer, fractionOfDistanceThroughGlyph: nil)
            let index: Int? = textView.layoutManager.characterIndexForGlyph(at: glyphIndex ?? 0)
            if let characterIndex = index, characterIndex < textView.textStorage.length {
                if NSTextAttachment.character == (textView.textStorage.string as NSString).character(at: characterIndex) {
                    attachmentCharacterIndex = characterIndex
                    attachment = textView.textStorage.attribute(.attachment, at: characterIndex, effectiveRange: nil) as? NSTextAttachment
                    state = .recognized
                } else {
                    state = .failed
                }
            }
        } else {
            state = .failed
        }
    }
}

extension UITextView {

    /// Add an attachment recognizer to a UITTextView
    func add(_ attachmentRecognizer: AttachmentTapGestureRecognizer) {
        for other in gestureRecognizers ?? [] {
            other.require(toFail: attachmentRecognizer)
        }
        addGestureRecognizer(attachmentRecognizer)
    }

}
