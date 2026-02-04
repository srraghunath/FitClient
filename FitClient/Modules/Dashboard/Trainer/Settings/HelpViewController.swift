

import UIKit

class HelpViewController: UIViewController {

    // MARK: - IBOutlets (Trainer)
    @IBOutlet weak var contactEmailLabel: UILabel!
    @IBOutlet weak var contactPhoneLabel: UILabel!
    @IBOutlet weak var faq1Label: UILabel!
    @IBOutlet weak var faq2Label: UILabel!
    @IBOutlet weak var faq3Label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadTrainerSettings()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .primaryGreen
    }

    private func loadTrainerSettings() {
        DataService.shared.loadTrainerSettings { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .success(let config) = result {
                    self.apply(help: config.help)
                }
            }
        }
    }

    private func apply(help: TrainerSettingsConfig.Help) {
        contactEmailLabel?.text = "Email: \(help.contactEmail)"
        contactPhoneLabel?.text = "Phone: \(help.contactPhone)"
        if help.faqs.indices.contains(0) { faq1Label?.text = help.faqs[0].q }
        if help.faqs.indices.contains(1) { faq2Label?.text = help.faqs[1].q }
        if help.faqs.indices.contains(2) { faq3Label?.text = help.faqs[2].q }
    }
}
