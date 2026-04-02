

import UIKit

class HelpViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var developerStackView: UIStackView!
    @IBOutlet weak var faqStackView: UIStackView!
    @IBOutlet weak var submitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadTrainerSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .primaryGreen
        title = "Help & Support"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
    }

    private func setupUI() {
        submitButton.addTarget(self, action: #selector(submitRequestTapped), for: .touchUpInside)
    }

    private func loadTrainerSettings() {
        DataService.shared.loadTrainerSettings { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let config):
                    self?.apply(help: config.help)
                case .failure:
                    break
                }
            }
        }
    }

    private func apply(help: TrainerSettingsConfig.Help) {
        // Clear existing dynamic views (if any, except title)
        developerStackView.arrangedSubviews.forEach { if $0.tag == 100 { $0.removeFromSuperview() } }
        faqStackView.arrangedSubviews.forEach { if $0.tag == 100 { $0.removeFromSuperview() } }

        // Populate Developers
        for dev in help.developers {
            let devView = createInfoRow(title: dev.name, subtitle: dev.email, icon: "envelope.fill")
            devView.tag = 100
            developerStackView.addArrangedSubview(devView)
        }

        // Populate FAQs
        for faq in help.faqs {
            let faqView = createFAQView(question: faq.q, answer: faq.a)
            faqView.tag = 100
            faqStackView.addArrangedSubview(faqView)
        }
    }

    private func createInfoRow(title: String, subtitle: String, icon: String) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = .primaryGreen
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .textSecondary

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        container.addArrangedSubview(iconImageView)
        container.addArrangedSubview(textStack)

        return container
    }

    private func createFAQView(question: String, answer: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        container.isLayoutMarginsRelativeArrangement = true
        container.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 12

        let qLabel = UILabel()
        qLabel.text = question
        qLabel.font = .systemFont(ofSize: 15, weight: .medium)
        qLabel.textColor = .white
        qLabel.numberOfLines = 0

        let aLabel = UILabel()
        aLabel.text = answer
        aLabel.font = .systemFont(ofSize: 14)
        aLabel.textColor = .textSecondary
        aLabel.numberOfLines = 0

        container.addArrangedSubview(qLabel)
        container.addArrangedSubview(aLabel)

        return container
    }

    @objc private func submitRequestTapped() {
        if let url = URL(string: "https://fitbond.netlify.app/#support") {
            UIApplication.shared.open(url)
        }
    }
}
