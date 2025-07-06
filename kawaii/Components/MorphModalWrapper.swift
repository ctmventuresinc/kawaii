//
//  MorphModalWrapper.swift
//  kawaii
//
//  Created by ai on 7/06/25.
//

import SwiftUI
import UIKit
import MorphModalKit

// MARK: - SwiftUI Wrapper for MorphModalKit
struct MorphModalWrapper: UIViewControllerRepresentable {
    let onModalPresent: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let hostVC = UIViewController()
        return hostVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed for this simple wrapper
    }
}

// MARK: - Extension for Modal Presentation
extension UIViewController {
    var modalVC: ModalViewController? {
        sequence(first: parent) { $0?.parent }.first { $0 is ModalViewController } as? ModalViewController
    }
}

// MARK: - MenuModal Implementation
class MenuModal: UIViewController, ModalView {
    
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure title
        titleLabel.text = "Menu Options"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add buttons
        let buttons = [
            createButton(title: "Push Another Card", action: #selector(pushAnotherCard)),
            createButton(title: "Push Third Card", action: #selector(pushThirdCard)),
            createButton(title: "Close Menu", action: #selector(closeMenu))
        ]
        
        stackView.addArrangedSubview(titleLabel)
        buttons.forEach { stackView.addArrangedSubview($0) }
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return button
    }
    
    @objc private func pushAnotherCard() {
        modalVC?.push(SecondModal())
    }
    
    @objc private func pushThirdCard() {
        modalVC?.push(ThirdModal())
    }
    
    @objc private func closeMenu() {
        modalVC?.hide()
    }
    
    // MARK: - ModalView Protocol
    func preferredHeight(for width: CGFloat) -> CGFloat {
        return 320
    }
    
    var canDismiss: Bool { true }
    var dismissalHandlingScrollView: UIScrollView? { nil }
}

// MARK: - Second Modal
class SecondModal: UIViewController, ModalView {
    
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel.text = "Second Card"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "This is the second card in the stack.\nYou can see the first card behind it."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        
        let backButton = UIButton(type: .system)
        backButton.setTitle("Go Back", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        backButton.backgroundColor = .systemGray5
        backButton.setTitleColor(.label, for: .normal)
        backButton.layer.cornerRadius = 12
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(backButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    @objc private func goBack() {
        modalVC?.pop()
    }
    
    // MARK: - ModalView Protocol
    func preferredHeight(for width: CGFloat) -> CGFloat {
        return 280
    }
    
    var canDismiss: Bool { true }
    var dismissalHandlingScrollView: UIScrollView? { nil }
}

// MARK: - Third Modal
class ThirdModal: UIViewController, ModalView {
    
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel.text = "Third Card"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "This is the third card!\nNow you can see all three cards stacked."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        
        let buttons = [
            createButton(title: "Go Back", color: .systemGray5, textColor: .label, action: #selector(goBack)),
            createButton(title: "Close All", color: .systemRed, textColor: .white, action: #selector(closeAll))
        ]
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        buttons.forEach { stackView.addArrangedSubview($0) }
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func createButton(title: String, color: UIColor, textColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = color
        button.setTitleColor(textColor, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return button
    }
    
    @objc private func goBack() {
        modalVC?.pop()
    }
    
    @objc private func closeAll() {
        modalVC?.hide()
    }
    
    // MARK: - ModalView Protocol
    func preferredHeight(for width: CGFloat) -> CGFloat {
        return 320
    }
    
    var canDismiss: Bool { true }
    var dismissalHandlingScrollView: UIScrollView? { nil }
}
