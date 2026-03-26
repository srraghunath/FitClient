//
//  TrainerClientProfileViewController.swift
//  FitClient
//
//  Created by admin6 on 10/11/25.
//

import UIKit

class TrainerClientProfileViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var specialtyLabel: UILabel!
    @IBOutlet private weak var goalsLabel: UILabel!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var totalActiveDaysLabel: UILabel!
    @IBOutlet private weak var consecutiveActiveDaysLabel: UILabel!
    @IBOutlet private weak var recentActivitiesTableView: UITableView!
    @IBOutlet private weak var tableHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    var client: Client?
    private var clientProfile: ClientProfile?
    private var currentChildViewController: UIViewController?
    private var recentCompletedItems: [DayTrackerItem] = []
    private let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
        loadClientProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        scrollView?.alwaysBounceVertical = true
        scrollView?.showsVerticalScrollIndicator = true
        contentView?.translatesAutoresizingMaskIntoConstraints = false
        setupProfileUI()
        setupSegmentedControl()
    }
    
    private func setupProfileUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        
        guard let client = client else { return }
        nameLabel.text = client.name
        specialtyLabel.text = client.gender ?? "Client"
        goalsLabel.text = "Profile: \(client.profileSummary)"
        
        // Center align activity summary labels
        totalActiveDaysLabel.textAlignment = .center
        consecutiveActiveDaysLabel.textAlignment = .center
        
        if let imageURL = URL(string: client.profileImage) {
            // Load image asynchronously (you may want to use SDWebImage or similar)
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.profileImageView.image = image
                    }
                }
            }.resume()
        }
    }
    
    private func setupSegmentedControl() {
        // Set background color to match progress card color
        segmentedControl.backgroundColor = UIColor(hex: "#303131")
        
        // Set text color for normal state (unselected)
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        
        // Set text color for selected state
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black
        ]
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
    }
    
    private func setupNavigationBar() {
        setupStandardNavigationBar(title: "Profile")
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupTableView() {
        recentActivitiesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "CompletedTrackerCell")
        recentActivitiesTableView.delegate = self
        recentActivitiesTableView.dataSource = self
        recentActivitiesTableView.backgroundColor = .black
        recentActivitiesTableView.separatorStyle = .none
        recentActivitiesTableView.rowHeight = 72
        recentActivitiesTableView.estimatedRowHeight = 72
        recentActivitiesTableView.isScrollEnabled = false
        recentActivitiesTableView.alwaysBounceVertical = false
        recentActivitiesTableView.showsVerticalScrollIndicator = false
    }
    
    private func loadClientProfile() {
        guard let clientId = client?.id else {
            showAlert(title: "Error", message: "Client information not available")
            return
        }
        
        print("[TrainerProfile] Loading activity profile for client ID: \(clientId)")

        DayActivityService.shared.fetchAllActivities(for: clientId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let activities):
                    let profile = self?.buildProfile(from: activities)
                    self?.clientProfile = profile
                    self?.recentCompletedItems = self?.buildCompletedItemsForToday(from: activities) ?? []
                case .failure(let error):
                    print("[TrainerProfile] Failed to fetch activities: \(error)")
                    let placeholder = ClientProfile(
                        totalActiveDays: 0,
                        consecutiveActiveDays: 0,
                        recentActivities: []
                    )
                    self?.clientProfile = placeholder
                    self?.recentCompletedItems = [
                        DayTrackerItem(icon: "–", title: "None", subtitle: "No activity completed", isCompleted: false)
                    ]
                }
                self?.updateProfileUI()
                self?.recentActivitiesTableView.reloadData()
                self?.updateTableHeight()
            }
        }
    }
    
    private func updateTableHeight() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let constraint = self.tableHeightConstraint {
                let rows = CGFloat(max(self.recentCompletedItems.count, 1))
                let targetHeight = rows * 80
                constraint.constant = targetHeight
            }
            self.recentActivitiesTableView.layoutIfNeeded()
            self.scrollView?.layoutIfNeeded()
        }
    }
    
    private func updateProfileUI() {
        guard let profile = clientProfile else { return }
        totalActiveDaysLabel.text = "\(profile.totalActiveDays) Days"
        consecutiveActiveDaysLabel.text = "\(profile.consecutiveActiveDays) Days"
    }

    private func buildProfile(from activities: [DayActivityDTO]) -> ClientProfile {
        let activeDates = extractActiveDates(from: activities)
        let totalActiveDays = activeDates.count
        let longestStreak = computeLongestStreak(from: activeDates)
        return ClientProfile(
            totalActiveDays: totalActiveDays,
            consecutiveActiveDays: longestStreak,
            recentActivities: []
        )
    }

    private func extractActiveDates(from activities: [DayActivityDTO]) -> [Date] {
        let calendar = Calendar.current
        var uniqueDates: Set<Date> = []

        for activity in activities {
            guard activity.workoutDone || activity.cardioDone || activity.waterDone || activity.dietDone || activity.sleepDone else {
                continue
            }

            if let date = isoFormatter.date(from: activity.activityDate) {
                let start = calendar.startOfDay(for: date)
                uniqueDates.insert(start)
            }
        }

        return uniqueDates.sorted()
    }

    private func computeLongestStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar.current
        var longest = 1
        var current = 1

        for idx in 1..<dates.count {
            if let previousDay = calendar.date(byAdding: .day, value: 1, to: dates[idx - 1]), calendar.isDate(previousDay, inSameDayAs: dates[idx]) {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
        }

        return longest
    }

    private func buildCompletedItemsForToday(from activities: [DayActivityDTO]) -> [DayTrackerItem] {
        let todayString = isoFormatter.string(from: Date())
        guard let record = activities.last(where: { $0.activityDate == todayString }) else {
            return [DayTrackerItem(icon: "–", title: "None", subtitle: "No activity completed", isCompleted: false)]
        }

        var items: [DayTrackerItem] = []

        if record.workoutDone {
            items.append(DayTrackerItem(icon: "🏋️", title: "Workout", subtitle: "Completed today", isCompleted: true))
        }
        if record.cardioDone {
            items.append(DayTrackerItem(icon: "❤️", title: "Cardio", subtitle: "Completed today", isCompleted: true))
        }
        if record.waterDone {
            items.append(DayTrackerItem(icon: "💧", title: "Water Intake", subtitle: "Completed today", isCompleted: true))
        }
        if record.dietDone {
            items.append(DayTrackerItem(icon: "🍽", title: "Diet Plan", subtitle: "Completed today", isCompleted: true))
        }
        if record.sleepDone {
            items.append(DayTrackerItem(icon: "🌙", title: "Sleep Cycle", subtitle: "Completed today", isCompleted: true))
        }

        let completed = Array(items.prefix(5))
        if completed.isEmpty {
            return [DayTrackerItem(icon: "–", title: "None", subtitle: "No activity completed", isCompleted: false)]
        }
        return completed
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        // Handle segment changes here (Overview, Schedule, Progress)
        switch sender.selectedSegmentIndex {
        case 0:
            // Overview - show regular activity table view
            removeCurrentChildViewController()
            recentActivitiesTableView.isHidden = false
        case 1:
            // Schedule - load schedule view controller
            recentActivitiesTableView.isHidden = true
            loadScheduleViewController()
        case 2:
            // Progress - load progress view controller
            recentActivitiesTableView.isHidden = true
            loadProgressViewController()
        default:
            break
        }
    }
    
    private func loadScheduleViewController() {
        // Remove existing child if present
        removeCurrentChildViewController()
        
        // Load schedule view controller from XIB
        let scheduleVC = TrainerClientProfileScheduleViewController(nibName: "TrainerClientProfileScheduleViewController", bundle: nil)
        guard let clientId = client?.id else { return }
        scheduleVC.clientId = clientId.uuidString
        
        // Add as child view controller
        addChild(scheduleVC)
        
        // Attach to parent view with full-edge constraints to maintain full height layout
        guard let parentView = recentActivitiesTableView.superview else { return }
        scheduleVC.view.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(scheduleVC.view)
        NSLayoutConstraint.activate([
            scheduleVC.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            scheduleVC.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            scheduleVC.view.topAnchor.constraint(equalTo: parentView.topAnchor),
            scheduleVC.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        
        scheduleVC.didMove(toParent: self)
        self.currentChildViewController = scheduleVC
    }
    
    private func loadProgressViewController() {
        // Remove existing child if present
        removeCurrentChildViewController()
        
        // Load progress view controller from XIB
        let progressVC = TrainerClientProgressViewControlller(nibName: "TrainerClientProgressViewControlller", bundle: nil)
        progressVC.clientId = client?.id.uuidString
        
        // Add as child view controller
        addChild(progressVC)
        
        guard let parentView = recentActivitiesTableView.superview else { return }
        progressVC.view.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(progressVC.view)
        NSLayoutConstraint.activate([
            progressVC.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            progressVC.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            progressVC.view.topAnchor.constraint(equalTo: parentView.topAnchor),
            progressVC.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        
        progressVC.didMove(toParent: self)
        self.currentChildViewController = progressVC
    }
    
    private func removeCurrentChildViewController() {
        guard let childVC = currentChildViewController else { return }
        
        childVC.willMove(toParent: nil)
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
        self.currentChildViewController = nil
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TrainerClientProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentCompletedItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedTrackerCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        // Remove existing subviews to avoid stacking when reused
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1.0)
        containerView.layer.cornerRadius = 24
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(containerView)

        let item = recentCompletedItems[indexPath.row]

        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = .systemFont(ofSize: 24)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconLabel)

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = item.subtitle
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),

            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16)
        ])

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
}
