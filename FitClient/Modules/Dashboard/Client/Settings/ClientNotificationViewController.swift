
import UIKit

class ClientNotificationViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var upcomingWorkoutsSwitch: UISwitch!
    @IBOutlet weak var dietRemindersSwitch: UISwitch!
    @IBOutlet weak var messagesSwitch: UISwitch!
    @IBOutlet weak var goalProgressSwitch: UISwitch!
    @IBOutlet weak var emailSwitch: UISwitch!
    @IBOutlet weak var pushSwitch: UISwitch!

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
        title = "Notifications"
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
                    self?.apply(config: config)
                case .failure:
                    break
                }
            }
        }
    }

    private func apply(config: ClientSettingsConfig) {
        upcomingWorkoutsSwitch.isOn = config.notifications.upcomingWorkouts
        dietRemindersSwitch.isOn = config.notifications.dietReminders
        messagesSwitch.isOn = config.notifications.messages
        goalProgressSwitch.isOn = config.notifications.goalProgress
        emailSwitch.isOn = config.notifications.email
        pushSwitch.isOn = config.notifications.push
    }
}
