//
//  DashboardViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

// MARK: - Day Tracker Item
struct DayTrackerItem {
    let icon: String
    let title: String
    let subtitle: String
    var isCompleted: Bool
}

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var activitySummaryLabel: UILabel!
    @IBOutlet weak var totalActiveDaysLabel: UILabel!
    @IBOutlet weak var totalActiveDaysValueLabel: UILabel!
    @IBOutlet weak var consecutiveDaysLabel: UILabel!
    @IBOutlet weak var consecutiveDaysValueLabel: UILabel!
    @IBOutlet weak var dayTrackerTableView: UITableView!
    @IBOutlet weak var scheduledWorkoutsTableView: UITableView!
    @IBOutlet weak var dayTrackerTableHeight: NSLayoutConstraint!
    @IBOutlet weak var scheduledWorkoutsTableHeight: NSLayoutConstraint!
    
    private var datePicker: UIDatePicker!
    private var navBarDateLabel: UILabel!
    private var calendarButton: UIButton!
    private var selectedDate: Date = Date()
    
    private var dayTrackerItems: [DayTrackerItem] = []
    private var scheduledWorkouts: [TodayWorkout] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomNavigationBar()
        setupUI()
        setupTableViews()
        loadData()
    }
    
    private func setupCustomNavigationBar() {
        // Hide the standard navigation bar title
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor(red: 0/255, green: 1/255, blue: 1/255, alpha: 1.0) // #000101
        navigationController?.navigationBar.shadowImage = UIImage()
        
        // Initialize date picker
        datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.tintColor = .primaryGreen
        datePicker.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        datePicker.overrideUserInterfaceStyle = .dark
        
        // Create custom title view with date
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 220, height: 44))
        
        navBarDateLabel = UILabel(frame: titleView.bounds)
        navBarDateLabel.textAlignment = .center
        navBarDateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        navBarDateLabel.textColor = .textPrimary
        
        titleView.addSubview(navBarDateLabel)
        navigationItem.titleView = titleView
        
        // Create calendar button on the right
        calendarButton = UIButton(type: .system)
        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = .textPrimary
        calendarButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        calendarButton.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
        
        let calendarBarButton = UIBarButtonItem(customView: calendarButton)
        navigationItem.rightBarButtonItem = calendarBarButton
        
        // Update date immediately
        updateNavigationDate()
    }
    
    @objc private func calendarButtonTapped() {
        showDatePickerModal()
    }
    
    private func showDatePickerModal() {
        // Create a custom view controller for the date picker
        let containerVC = UIViewController()
        containerVC.modalPresentationStyle = .pageSheet
        
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
        
        present(containerVC, animated: true)
    }
    
    @objc private func selectDateTapped() {
        selectedDate = datePicker.date
        updateNavigationDate()
        loadDataForDate(selectedDate)
        dismiss(animated: true)
    }
    
    private func updateNavigationDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE , dd MMM yyyy"
        navBarDateLabel.text = dateFormatter.string(from: selectedDate)
    }
    
    func setupUI() {
        view.backgroundColor = .black
        contentView.backgroundColor = .black
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = false
        
        // Activity Summary header
        activitySummaryLabel.text = "Activity Summary"
        activitySummaryLabel.textColor = .textPrimary
        activitySummaryLabel.font = .systemFont(ofSize: 16, weight: .bold)
        
        // Stat cards - Total Active Days
        totalActiveDaysLabel.textColor = .textPrimary
        totalActiveDaysLabel.font = .systemFont(ofSize: 16, weight: .medium)
        totalActiveDaysLabel.text = "Total Active Days"
        totalActiveDaysLabel.numberOfLines = 2
        
        totalActiveDaysValueLabel.textColor = .primaryGreen
        totalActiveDaysValueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        
        // Stat cards - Consecutive Active Days
        consecutiveDaysLabel.textColor = .textPrimary
        consecutiveDaysLabel.font = .systemFont(ofSize: 16, weight: .medium)
        consecutiveDaysLabel.text = "Consecutive Active Days"
        consecutiveDaysLabel.numberOfLines = 2
        
        consecutiveDaysValueLabel.textColor = .primaryGreen
        consecutiveDaysValueLabel.font = .systemFont(ofSize: 24, weight: .bold)
    }
    
    func setupTableViews() {
        // Day Tracker Table View
        dayTrackerTableView.delegate = self
        dayTrackerTableView.dataSource = self
        dayTrackerTableView.backgroundColor = .clear
        dayTrackerTableView.separatorStyle = .none
        dayTrackerTableView.isScrollEnabled = false
        dayTrackerTableView.register(UITableViewCell.self, forCellReuseIdentifier: "DayTrackerCell")
        
        // Scheduled Workouts Table View
        scheduledWorkoutsTableView.delegate = self
        scheduledWorkoutsTableView.dataSource = self
        scheduledWorkoutsTableView.backgroundColor = .clear
        scheduledWorkoutsTableView.separatorStyle = .none
        scheduledWorkoutsTableView.isScrollEnabled = false
        
        // Register custom WorkoutCardCell
        let nib = UINib(nibName: "WorkoutCardCell", bundle: nil)
        scheduledWorkoutsTableView.register(nib, forCellReuseIdentifier: "WorkoutCardCell")
    }
    
    func loadData() {
        loadDataForDate(selectedDate)
    }
    
    func loadDataForDate(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let logPath = "/tmp/dashboard_debug.log"
        let log = "📅 [Dashboard] Loading data for date: \(dateString)\n"
        try? log.write(toFile: logPath, atomically: true, encoding: .utf8)
        print(log)
        
        // Set stat values
        totalActiveDaysValueLabel.text = "12 Days"
        consecutiveDaysValueLabel.text = "7 Days"
        
        // Prefill Day Tracker from data service (existing data if any)
        DataService.shared.loadDayActivityForDate(date) { [weak self] result in
            switch result {
            case .success(let activity):
                var logMsg = "✅ [Dashboard] Day activity for \(dateString): workout=\(activity.workout), cardio=\(activity.cardio), water=\(activity.waterIntake), diet=\(activity.diet), sleep=\(activity.sleep)\n"
                if let existingLog = try? String(contentsOfFile: logPath) {
                    try? (existingLog + logMsg).write(toFile: logPath, atomically: true, encoding: .utf8)
                }
                print(logMsg)

                // Map to items; keep the same order/UI and texts
                let items: [DayTrackerItem] = [
                    DayTrackerItem(icon: "🏋️", title: "Workout", subtitle: "Full body", isCompleted: activity.workout),
                    DayTrackerItem(icon: "❤️", title: "Cardio", subtitle: "Running, 30 minutes", isCompleted: activity.cardio),
                    DayTrackerItem(icon: "💧", title: "Water Intake", subtitle: "8 litres", isCompleted: activity.waterIntake),
                    DayTrackerItem(icon: "🍽", title: "Diet Plan", subtitle: "Balanced", isCompleted: activity.diet),
                    DayTrackerItem(icon: "🌙", title: "Sleep Cycle", subtitle: "8 hours", isCompleted: activity.sleep)
                ]

                DispatchQueue.main.async {
                    self?.dayTrackerItems = items
                    self?.updateUI()
                }
            case .failure(let error):
                let errMsg = "❌ [Dashboard] Error loading day activity: \(error)\n"
                if let existingLog = try? String(contentsOfFile: logPath) {
                    try? (existingLog + errMsg).write(toFile: logPath, atomically: true, encoding: .utf8)
                }
                print(errMsg)
            }
        }
        
        // Load scheduled workouts for the selected date
        DataService.shared.loadWorkoutsForDate(date) { [weak self] result in
            switch result {
            case .success(let workouts):
                var logMsg = "✅ [Dashboard] Loaded \(workouts.count) workouts for \(dateString)\n"
                workouts.forEach { workout in
                    logMsg += "   - \(workout.name): \(workout.imageUrl)\n"
                }
                if let existingLog = try? String(contentsOfFile: logPath) {
                    try? (existingLog + logMsg).write(toFile: logPath, atomically: true, encoding: .utf8)
                }
                print(logMsg)
                
                self?.scheduledWorkouts = workouts
                DispatchQueue.main.async {
                    self?.updateUI()
                }
            case .failure(let error):
                let errMsg = "❌ [Dashboard] Error loading workouts: \(error)\n"
                if let existingLog = try? String(contentsOfFile: logPath) {
                    try? (existingLog + errMsg).write(toFile: logPath, atomically: true, encoding: .utf8)
                }
                print(errMsg)
                
                DispatchQueue.main.async {
                    self?.scheduledWorkouts = []
                    self?.updateUI()
                }
            }
        }
    }
    
    func updateUI() {
        dayTrackerTableView.reloadData()
        scheduledWorkoutsTableView.reloadData()
        
        // Update table heights - 72pt + 8pt spacing per cell
        dayTrackerTableHeight.constant = CGFloat(dayTrackerItems.count) * 80
        scheduledWorkoutsTableHeight.constant = CGFloat(scheduledWorkouts.count) * 72
        
        // Log for debugging
        print("📊 [Dashboard] Day tracker items: \(dayTrackerItems.count), height: \(dayTrackerTableHeight.constant)")
        print("📊 [Dashboard] Scheduled workouts: \(scheduledWorkouts.count), height: \(scheduledWorkoutsTableHeight.constant)")
        
        view.layoutIfNeeded()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == dayTrackerTableView {
            return dayTrackerItems.count
        } else {
            return scheduledWorkouts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == dayTrackerTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DayTrackerCell", for: indexPath)
            
            // Create a container view for spacing
            let containerView = UIView()
            containerView.backgroundColor = UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1.0)
            containerView.layer.cornerRadius = 24
            containerView.clipsToBounds = true
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            cell.selectionStyle = .none
            
            // Remove all subviews first
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            cell.contentView.addSubview(containerView)
            
            let item = dayTrackerItems[indexPath.row]
            
            // Icon label
            let iconLabel = UILabel()
            iconLabel.text = item.icon
            iconLabel.font = .systemFont(ofSize: 24)
            iconLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(iconLabel)
            
            // Title label
            let titleLabel = UILabel()
            titleLabel.text = item.title
            titleLabel.textColor = .white
            titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(titleLabel)
            
            // Subtitle label
            let subtitleLabel = UILabel()
            subtitleLabel.text = item.subtitle
            subtitleLabel.textColor = .textSecondary
            subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(subtitleLabel)
            
            // Checkbox
            let checkbox = UIView()
            checkbox.backgroundColor = item.isCompleted ? .primaryGreen : .clear
            checkbox.layer.cornerRadius = 9
            checkbox.layer.borderWidth = 2
            checkbox.layer.borderColor = item.isCompleted ? UIColor.primaryGreen.cgColor : UIColor.textSecondary.cgColor
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(checkbox)
            
            if item.isCompleted {
                let checkmark = UILabel()
                checkmark.text = "✓"
                checkmark.textColor = .black
                checkmark.font = .systemFont(ofSize: 14, weight: .bold)
                checkmark.textAlignment = .center
                checkmark.translatesAutoresizingMaskIntoConstraints = false
                checkbox.addSubview(checkmark)
                
                NSLayoutConstraint.activate([
                    checkmark.centerXAnchor.constraint(equalTo: checkbox.centerXAnchor),
                    checkmark.centerYAnchor.constraint(equalTo: checkbox.centerYAnchor)
                ])
            }
            
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
                
                checkbox.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                checkbox.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                checkbox.widthAnchor.constraint(equalToConstant: 24),
                checkbox.heightAnchor.constraint(equalToConstant: 24)
            ])
            
            return cell
            
        } else {
            // Scheduled Workouts - use WorkoutCardCell
            let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCardCell", for: indexPath) as! WorkoutCardCell
            let todayWorkout = scheduledWorkouts[indexPath.row]
            cell.configure(with: todayWorkout, showCheckbox: false)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == dayTrackerTableView {
            return 72
        } else {
            return 72 // Match Schedule Workout modal height
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == dayTrackerTableView {
            dayTrackerItems[indexPath.row].isCompleted.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}
