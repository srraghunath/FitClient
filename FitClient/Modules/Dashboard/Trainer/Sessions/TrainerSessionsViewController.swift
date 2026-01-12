

import UIKit

class TrainerSessionsViewController: UIViewController {
    
    @IBOutlet weak var sessionsTableView: UITableView!
    
    private var datePicker: UIDatePicker!
    private var dateLabel: UILabel!
    private var calendarButton: UIButton!
    private let calendarOutlineImage = UIImage(systemName: "calendar")
    private weak var datePickerSheetController: UIViewController?
    private var selectedDate: Date = Date()
    private var allSessions: [Session] = []
    private var todaySessions: [Session] = []
    private var upcomingSessions: [Session] = []
    private var rangeSessions: [TrainerSessionDTO] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupTableView()
        loadSessionsData(for: selectedDate)
    }
    
    private func setupNavigationBar() {
        // Initialize date picker
        datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.tintColor = .primaryGreen
        datePicker.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        datePicker.overrideUserInterfaceStyle = .dark
        
        // Create date label for navigation title
        let dateLabel = UILabel()
        dateLabel.textAlignment = .center
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // #F5F5F5
        
        // Format date as "Wed,29 Oct 2025" (no space after comma like Figma)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy"
        dateLabel.text = dateFormatter.string(from: selectedDate)
        
        // Set label as title view
        navigationItem.titleView = dateLabel
        
        // Store date label reference for updates
        self.dateLabel = dateLabel
        
        // Create calendar button as right bar button item
        let calendarButton = UIButton(type: .system)
    calendarButton.setImage(calendarOutlineImage, for: .normal)
        calendarButton.tintColor = .white
        calendarButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        calendarButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        calendarButton.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
        self.calendarButton = calendarButton
        
        let calendarBarButton = UIBarButtonItem(customView: calendarButton)
        navigationItem.rightBarButtonItem = calendarBarButton
    }
    
    @objc private func calendarButtonTapped() {
        guard datePickerSheetController?.presentingViewController == nil else { return }
        calendarButton?.tintColor = .primaryGreen
        showDatePickerModal()
    }
    
    private func showDatePickerModal() {
        // Create a custom view controller for the date picker
        let containerVC = UIViewController()
        containerVC.modalPresentationStyle = .pageSheet
        datePickerSheetController = containerVC
        
        if let sheet = containerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        // Setup the view
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerVC.view.addSubview(containerView)
        
        // Configure date picker
        datePicker.date = selectedDate
    datePicker.tintColor = .primaryGreen
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.backgroundColor = .clear
        containerView.addSubview(datePicker)
        
        // Create Select button
        let selectButton = UIButton(type: .system)
        selectButton.setTitle("Select Date", for: .normal)
        selectButton.backgroundColor = .primaryGreen
        selectButton.setTitleColor(.black, for: .normal)
        selectButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        selectButton.layer.cornerRadius = 28
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.addTarget(self, action: #selector(selectDateTapped), for: .touchUpInside)
        containerView.addSubview(selectButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor),
            
            datePicker.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            datePicker.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            selectButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            selectButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            selectButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            selectButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        present(containerVC, animated: true) { [weak self, weak containerVC] in
            guard let self = self else { return }
            containerVC?.presentationController?.delegate = self
        }
    }
    
    @objc private func selectDateTapped() {
        view.window?.endEditing(true)
        dateChanged()
        dismiss(animated: true) { [weak self] in
            self?.resetCalendarButtonAppearance()
        }
    }
    
    private func updateDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE,dd MMM yyyy" // No space after comma like Figma
        dateLabel.text = dateFormatter.string(from: selectedDate)
    }
    
    @objc private func dateChanged() {
        selectedDate = datePicker.date
        updateDateLabel()
        loadSessionsData(for: selectedDate)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black
    }
    
    fileprivate func resetCalendarButtonAppearance() {
        calendarButton?.tintColor = .white
        datePickerSheetController = nil
    }
    
    private func setupTableView() {
        sessionsTableView.delegate = self
        sessionsTableView.dataSource = self
        sessionsTableView.backgroundColor = .clear
        sessionsTableView.applyAppStyle()
        
        // Register custom cell
        let nib = UINib(nibName: "SessionTableViewCell", bundle: nil)
        sessionsTableView.register(nib, forCellReuseIdentifier: "SessionTableViewCell")
    }
    
    // MARK: BACKEND OPERATIONS

    private func loadSessionsData(for date: Date) {
        SessionService.shared.fetchSessions(startingFrom: date) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let rows):
                    self?.rangeSessions = rows
                    self?.mapSessions(for: date)
                case .failure(let error):
                    print("[TrainerSessions] Failed to fetch sessions: \(error)")
                    self?.todaySessions = []
                    self?.upcomingSessions = []
                    self?.sessionsTableView.reloadData()
                }
            }
        }
    }

    private func mapSessions(for date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDateString = dateFormatter.string(from: date)
        let calendar = Calendar.current

        func displayTime(from raw: String?) -> String? {
            guard let raw = raw else { return nil }
            let input = DateFormatter()
            input.dateFormat = "HH:mm:ss"
            if let parsed = input.date(from: raw) {
                let output = DateFormatter()
                output.dateFormat = "h:mm a"
                return output.string(from: parsed)
            }
            return raw
        }

        allSessions = rangeSessions.compactMap { row in
            Session(
                id: row.sessionId.uuidString,
                clientId: row.clientId.uuidString,
                clientName: row.clientName,
                clientProfileImage: row.clientProfileImageUrl ?? "",
                startTime: displayTime(from: row.startTime),
                endTime: displayTime(from: row.endTime),
                date: row.sessionDate,
                dayOfWeek: row.dayOfWeek,
                isToday: {
                    guard let sessionDate = dateFormatter.date(from: row.sessionDate) else { return false }
                    return calendar.isDateInToday(sessionDate)
                }()
            )
        }

        todaySessions = allSessions.filter { $0.date == selectedDateString }

        // Only show the next day's sessions in the Upcoming section (tomorrow), per expected UX
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) {
            let tomorrowString = dateFormatter.string(from: tomorrow)
            upcomingSessions = allSessions.filter { $0.date == tomorrowString }
        } else {
            upcomingSessions = []
        }

        sessionsTableView.reloadData()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension TrainerSessionsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        resetCalendarButtonAppearance()
    }
}

// MARK: - UITableViewDataSource
extension TrainerSessionsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return todaySessions.count
        } else {
            return upcomingSessions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SessionTableViewCell", for: indexPath) as? SessionTableViewCell else {
            return UITableViewCell()
        }
        
        let session = indexPath.section == 0 ? todaySessions[indexPath.row] : upcomingSessions[indexPath.row]
        cell.configure(with: session)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TrainerSessionsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .black
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Get day names for headers
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(selectedDate)
        
        if section == 0 {
            // First section shows selected date
            if isToday {
                label.text = "Today"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE" // Full day name (e.g., "Monday")
                label.text = dateFormatter.string(from: selectedDate)
            }
        } else {
            // Second section shows next day
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                if calendar.isDateInTomorrow(nextDay) {
                    label.text = "Tomorrow"
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE" // Full day name (e.g., "Tuesday")
                    label.text = dateFormatter.string(from: nextDay)
                }
            } else {
                label.text = "Upcoming"
            }
        }
        
        label.font = UIFont(name: "SFPro-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .textPrimary
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let session = indexPath.section == 0 ? todaySessions[indexPath.row] : upcomingSessions[indexPath.row]
        
        // Create and configure TrainerClientProfileViewController
        let profileVC = TrainerClientProfileViewController()
        profileVC.client = session.client
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

