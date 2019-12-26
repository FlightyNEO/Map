//
//  SmartTargetMenu.swift
//  Map
//
//  Created by Arkadiy Grigoryanc on 22.12.2019.
//

import UIKit

typealias Action = (SmartTargetMenu) -> Void
typealias RadiusDidChange = (_ menu: SmartTargetMenu, _ value: Float) -> Void

final class SmartTargetMenu: UIView
{

	// MARK: ...Private properties
	private var radius: Float {
		didSet {
			radiusLabel.text = "\(Int(radiusSlider.value))"
		}
	}
	private let radiusRange: (Float, Float)
	private let maxLenghtOfTitle = 30
	private var title: String?
	private let saveAction: Action
	private let cancelAction: Action
	private let radiusDidChange: RadiusDidChange

	private let blurredView: UIVisualEffectView = {
		let blurEffect = UIBlurEffect(style: .light)
		let view = UIVisualEffectView(effect: blurEffect)
		return view
	}()

	private let vibrancyView: UIVisualEffectView = {
		let blurEffect = UIBlurEffect(style: .prominent)
		let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
		let view = UIVisualEffectView(effect: vibrancyEffect)
		return view
	}()

	private lazy var titleTextField: UITextField = {
		let textField = UITextField()
		textField.placeholder = "type title..."
		textField.text = title
		textField.textAlignment = .center
		textField.delegate = self
		textField.returnKeyType = .done
		textField.autocorrectionType = .no
		return textField
	}()

	private lazy var addressLabel: UILabel = {
		let label = UILabel()
		label.text = address
		label.numberOfLines = 0
		label.textAlignment = .center
		return label
	}()

	private lazy var radiusSlider: UISlider = {
		let slider = UISlider()
		slider.minimumValueImage = #imageLiteral(resourceName: "radius-of-circle")
		slider.minimumValue = radiusRange.0
		slider.maximumValue = radiusRange.1
		slider.value = radius
		slider.addTarget(self, action: #selector(actionChangeRadius(_:)), for: .valueChanged)
		return slider
	}()

	private var radiusLabel: UILabel = {
		let label = UILabel()
		label.textAlignment = .right
		return label
	}()

	private let saveButton: UIButton = {
		let button = UIButton()
		button.setTitleColor(.systemBlue, for: .normal)
		button.setTitle("Save", for: .normal)
		button.addTarget(self, action: #selector(actionSave), for: .touchUpInside)
		return button
	}()

	private let cancelButton: UIButton = {
		let button = UIButton()
		button.setTitleColor(.systemRed, for: .normal)
		button.setTitle("Cancel", for: .normal)
		button.addTarget(self, action: #selector(actionCancel), for: .touchUpInside)
		return button
	}()

	private let activityIndicator: UIActivityIndicatorView = {
		let style: UIActivityIndicatorView.Style
		if #available(iOS 13.0, *) {
			style = .medium
		}
		else {
			style = .gray
		}
		let indicator = UIActivityIndicatorView(style: style)
		return indicator
	}()

	// MARK: ...Properties
	var address: String? {
		didSet {
			checkAddress()
			addressLabel.text = address
		}
	}

	// MARK: ...Initialization
	/// Основной инициализатор
	/// - Parameters:
	///   - title: textField с заголовком
	///   - radiusValue: Значение установленное на слайдере
	///   - radiusRange: Диапазон значений слайдера
	///   - address: label c адресом
	///   - saveAction: Блок кода выполняемый при нажатии на кнопку "Save"
	///   - cancelAction: Блок кода выполняемый при нажатии на кнопку "Cancel"
	///   - radiusChange: Блок кода выполняемый при изменении значения слайдера
	init(title: String? = nil,
		 radiusValue: Float = 0,
		 radiusRange: (Float, Float),
		 address: String? = nil,
		 saveAction: @escaping Action,
		 cancelAction: @escaping Action,
		 radiusChange: @escaping RadiusDidChange) {
		self.radius = max(radiusValue, radiusRange.0)
		self.radiusRange = radiusRange
		self.title = title
		self.address = address
		self.saveAction = saveAction
		self.cancelAction = cancelAction
		self.radiusDidChange = radiusChange

		super.init(frame: .zero)

		setup()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: ...Private methods
	private func setup() {

		// Set corner radius
		layer.cornerRadius = 10
		self.clipsToBounds = true

		// Set layout margins
		layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

		// Add subviews
		addSubview(blurredView)
		addSubview(radiusSlider)
		addSubview(radiusLabel)
		addSubview(saveButton)
		addSubview(cancelButton)
		addSubview(activityIndicator)

		// Set blurred effect view
		vibrancyView.contentView.addSubview(titleTextField)
		vibrancyView.contentView.addSubview(addressLabel)
		blurredView.contentView.addSubview(vibrancyView)

		// Check title
		checkAddress()

		radiusLabel.text = "\(Int(radius))"

		// Set constrains
		setConstraints()
	}

	private func checkAddress() {
		address == nil ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
	}

	private func setConstraints() {
		titleTextField.translatesAutoresizingMaskIntoConstraints = false
		addressLabel.translatesAutoresizingMaskIntoConstraints = false
		radiusSlider.translatesAutoresizingMaskIntoConstraints = false
		radiusLabel.translatesAutoresizingMaskIntoConstraints = false
		saveButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		blurredView.translatesAutoresizingMaskIntoConstraints = false
		vibrancyView.translatesAutoresizingMaskIntoConstraints = false

		// Set constraint for titleTextField
		titleTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: layoutMargins.left).isActive = true
		titleTextField.topAnchor.constraint(equalTo: topAnchor, constant: layoutMargins.top).isActive = true
		titleTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -layoutMargins.right).isActive = true

		// Set constraint for addressLabel
		addressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: layoutMargins.left).isActive = true
		addressLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: layoutMargins.top).isActive = true
		addressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -layoutMargins.right).isActive = true
		addressLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16).isActive = true

		// Set constraint for activityIndicator
		activityIndicator.centerXAnchor.constraint(equalTo: addressLabel.centerXAnchor).isActive = true
		activityIndicator.centerYAnchor.constraint(equalTo: addressLabel.centerYAnchor).isActive = true

		// Set constraint for radiusSlider
		radiusSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: layoutMargins.left).isActive = true
		radiusSlider.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 16).isActive = true
		radiusSlider.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 2 / 3).isActive = true

		// Set constraint for radiusLabel
		radiusLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 16).isActive = true
		radiusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -layoutMargins.right).isActive = true
		radiusLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / 3).isActive = true

		// Set constraint for saveButton
		saveButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: layoutMargins.left).isActive = true
		saveButton.topAnchor.constraint(equalTo: radiusSlider.bottomAnchor, constant: 16).isActive = true
		saveButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -layoutMargins.right).isActive = true

		// Set constraint for cancelButton
		cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -layoutMargins.right).isActive = true
		cancelButton.topAnchor.constraint(equalTo: radiusSlider.bottomAnchor, constant: 16).isActive = true

		// Set constraint for blurredView
		blurredView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
		blurredView.topAnchor.constraint(equalTo: topAnchor).isActive = true
		blurredView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
		blurredView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

		// Set constraint for vibrancyView
		vibrancyView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
		vibrancyView.topAnchor.constraint(equalTo: topAnchor).isActive = true
		vibrancyView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
		vibrancyView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
	}

	private func hide() {
		UIProgressView.animate(withDuration: 0.3,
							   animations: { [weak self] in
								self?.alpha = 0
			},
							   completion: { [weak self] _ in
								self?.isHidden = true
		})
	}

	// MARK: ...Methods
	/// Сделать menu прозрачным
	/// - Parameters:
	///   - take: сделать прозрачным или нет
	///   - value: степень прозрачности от 0 до 1. Значение по умолчанию - 0.5
	func translucent(_ take: Bool, value: CGFloat = 0.5) {
		UIProgressView.animate(withDuration: 0.3) { [weak self] in
			self?.alpha = take ? value : 1
		}
	}
}

// MARK: - Actions
@objc extension SmartTargetMenu
{
	private func actionSave() {
		saveAction(self)
		hide()
	}

	private func actionCancel() {
		cancelAction(self)
		hide()
	}

	private func actionChangeRadius(_ sender: UISlider) {
		radius = sender.value
		radiusDidChange(self, radius)
	}
}

// MARK: - Text field delegate
extension SmartTargetMenu: UITextFieldDelegate
{
	func textField(_ textField: UITextField,
						  shouldChangeCharactersIn range: NSRange,
						  replacementString string: String) -> Bool {
		guard
			let text = textField.text,
			let range = Range<String.Index>(range, in: text) else {
				return false
		}
		let newString = textField.text?.replacingCharacters(in: range, with: string)
		return newString?.count ?? 0 <= maxLenghtOfTitle
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
