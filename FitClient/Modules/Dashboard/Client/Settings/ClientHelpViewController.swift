
import UIKit

class ClientHelpViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!

    @IBOutlet weak var faq1Label: UILabel!
    @IBOutlet weak var faq2Label: UILabel!
    @IBOutlet weak var faq3Label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadClientSettings()
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
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
    }

    private func loadClientSettings() {
        DataService.shared.loadClientSettings { [weak self] result in
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

    private func apply(help: ClientSettingsConfig.Help) {
        emailLabel.text = "Email: \(help.contactEmail)"
        phoneLabel.text = "Phone: \(help.contactPhone)"

        if help.faqs.indices.contains(0) { faq1Label.text = help.faqs[0].q }
        if help.faqs.indices.contains(1) { faq2Label.text = help.faqs[1].q }
        if help.faqs.indices.contains(2) { faq3Label.text = help.faqs[2].q }
    }
}
