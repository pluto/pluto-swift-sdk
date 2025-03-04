import UIKit

class PlutoButton: UIButton {
    enum Style {
        case primary
        case secondary
    }

    // MARK: - Properties
    private let style: Style

    // MARK: - Initialization
    init(title: String, style: Style = .primary) {
        self.style = style
        super.init(frame: .zero)
        configure(with: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    private func configure(with title: String) {
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        switch style {
        case .primary:
            backgroundColor = .systemBlue
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray, for: .disabled)
        case .secondary:
            backgroundColor = .systemGray6
            setTitleColor(.systemBlue, for: .normal)
            setTitleColor(.systemBlue.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray, for: .disabled)
        }

        layer.cornerRadius = 10
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
