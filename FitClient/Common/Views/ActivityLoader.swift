import UIKit

final class ActivityLoader: UIView {
    private let indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = false
        return indicator
    }()

    private let backdrop: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        return view
    }()

    private override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 14
        container.clipsToBounds = true

        addSubview(container)
        container.addSubview(backdrop)
        container.addSubview(indicator)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 120),
            container.heightAnchor.constraint(equalToConstant: 120),

            backdrop.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: container.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        indicator.startAnimating()
        isUserInteractionEnabled = true
    }

    static func show(over view: UIView) -> ActivityLoader {
        DispatchQueue.main.async {
            view.subviews.compactMap { $0 as? ActivityLoader }.forEach { $0.removeFromSuperview() }
        }

        let loader = ActivityLoader(frame: view.bounds)
        DispatchQueue.main.async {
            view.addSubview(loader)
            loader.frame = view.bounds
        }
        return loader
    }

    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.removeFromSuperview()
        }
    }
}
