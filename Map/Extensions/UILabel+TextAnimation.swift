//
//  UILabel+TextAnimation.swift
//  Map
//
//  Created by Anton on 17.01.2020.
//

import UIKit

extension UILabel
{
	func setTextAnimation(_ text: String?) {
		if text == nil { self.text = text }
		var newText = ""
		UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
			text?.forEach {
				newText += "\($0)"
				self.text = newText
			}
		})
	}
}
