//
//  Slider+EditableAddressView.swift
//  Map
//
//  Created by Anton on 17.01.2020.
//

import UIKit
protocol ISliderAndEditableAddressView
{
	func hide()
	func show()
	func setAddress(text: String?)
}

final class SliderAndEditableAddressView: UIView
{
	private let radiusSlider = UISlider()
	private var sliderValueLabelWidth: NSLayoutConstraint?
	private var sliderValueLabelWidthEqualZero: NSLayoutConstraint?
	private let sliderValueLabel: UILabel = {
		let label = UILabel()
		label.text = "3212 m" //заглушка
		label.minimumScaleFactor = 0.01
		label.adjustsFontSizeToFitWidth = true
		label.contentMode = .center
		label.textAlignment = .left
		return label
	}()
	private let editableAddressLabel = UILabel()
	private var addressLabelHeightAnchorEqualZero: NSLayoutConstraint?
	private var addressLabelHeightAnchor: NSLayoutConstraint?
	private var addressLabelBottomAnchor: NSLayoutConstraint?
	private var sliderWidthAnchor: NSLayoutConstraint?
	private var sliderTrailingAnchor: NSLayoutConstraint?

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupUI()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		if #available(iOS 13.0, *) {
			self.backgroundColor = .systemGray
		}
		else {
			self.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		}
		self.addSubview(sliderValueLabel)
		self.addSubview(radiusSlider)
		self.addSubview(editableAddressLabel)
		self.radiusSlider.translatesAutoresizingMaskIntoConstraints = false
		self.editableAddressLabel.translatesAutoresizingMaskIntoConstraints = false
		self.sliderValueLabel.translatesAutoresizingMaskIntoConstraints = false
		self.sliderValueLabelWidthEqualZero = self.sliderValueLabel.widthAnchor.constraint(equalToConstant: 0)
		self.sliderValueLabelWidth = self.sliderValueLabel.widthAnchor.constraint(equalToConstant: 60)
		self.sliderValueLabelWidthEqualZero?.isActive = true
		NSLayoutConstraint.activate([
			//label for slider
			self.sliderValueLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
			self.sliderValueLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
			//slider
			self.radiusSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor,
													   constant: 16),
			self.radiusSlider.topAnchor.constraint(equalTo: self.topAnchor,
												   constant: 16),
			//editableAddressLabel
			self.editableAddressLabel.topAnchor.constraint(equalTo: self.radiusSlider.bottomAnchor,
														   constant: 8),
			self.editableAddressLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor,
															   constant: 16),
			self.editableAddressLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor,
																constant: -16),
		])
		self.addressLabelHeightAnchorEqualZero = self.editableAddressLabel.heightAnchor.constraint(equalToConstant: 0)
		self.addressLabelHeightAnchor =
			self.editableAddressLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
		self.addressLabelHeightAnchorEqualZero?.isActive = true
		self.sliderWidthAnchor = self.radiusSlider.widthAnchor.constraint(equalToConstant: 0)
		self.sliderWidthAnchor?.isActive = true
		self.sliderTrailingAnchor =
			self.radiusSlider.trailingAnchor.constraint(equalTo: self.sliderValueLabel.leadingAnchor,
		constant: -8)
		self.addressLabelBottomAnchor =
			self.editableAddressLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
		self.radiusSlider.alpha = 0
		self.editableAddressLabel.numberOfLines = 0
		self.editableAddressLabel.textAlignment = .center
	}
}

extension SliderAndEditableAddressView: ISliderAndEditableAddressView
{
	func hide() {
		self.addressLabelHeightAnchor?.isActive = false
		self.addressLabelHeightAnchorEqualZero?.isActive = true
		self.sliderTrailingAnchor?.isActive = false
		self.addressLabelBottomAnchor?.isActive = false
		self.sliderWidthAnchor?.isActive = true
		self.sliderValueLabelWidth?.isActive = false
		self.sliderValueLabelWidthEqualZero?.isActive = true
		self.radiusSlider.alpha = 0
	}

	func show() {
		self.addressLabelHeightAnchorEqualZero?.isActive = false
		self.addressLabelBottomAnchor?.isActive = true
		self.addressLabelHeightAnchor?.isActive = true
		self.sliderWidthAnchor?.isActive = false
		self.sliderValueLabelWidthEqualZero?.isActive = false
		self.sliderValueLabelWidth?.isActive = true
		self.sliderTrailingAnchor?.isActive = true
		self.radiusSlider.alpha = 1
	}

	func setAddress(text: String?) {
		guard let text = text else { return }
		self.editableAddressLabel.setTextAnimation(string: text)
	}

	func getAddress() -> String {
		guard let text = self.editableAddressLabel.text else { return "" }
		return text
	}
}
