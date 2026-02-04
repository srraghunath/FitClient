

import UIKit

class NotificationViewController: UIViewController {

    // MARK: - IBOutlets (Trainer)
    @IBOutlet weak var sessionUpcomingSwitch: UISwitch!
    @IBOutlet weak var sessionChangesSwitch: UISwitch!
    @IBOutlet weak var clientNewSwitch: UISwitch!
    @IBOutlet weak var clientMessagesSwitch: UISwitch!
    @IBOutlet weak var emailSwitch: UISwitch!
    @IBOutlet weak var pushSwitch: UISwitch!

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
                    self.apply(config: config)
                }
            }
        }
    }

    private func apply(config: TrainerSettingsConfig) {
        sessionUpcomingSwitch?.isOn = config.notifications.upcomingSessions
        sessionChangesSwitch?.isOn = config.notifications.sessionChanges
        clientNewSwitch?.isOn = config.notifications.newClientRequests
        clientMessagesSwitch?.isOn = config.notifications.clientMessages
        emailSwitch?.isOn = config.notifications.email
        pushSwitch?.isOn = config.notifications.push
    }
}
