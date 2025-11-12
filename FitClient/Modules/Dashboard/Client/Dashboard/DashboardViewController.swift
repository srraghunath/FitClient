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
    
    private var navBarDateLabel: UILabel!
    private var calendarButton: UIButton!
    
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
        // Handle calendar button tap - show date picker or calendar view
        print("Calendar button tapped")
    }
    
    private func updateNavigationDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE , dd MMM yyyy"
        navBarDateLabel.text = dateFormatter.string(from: Date())
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
        scheduledWorkoutsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ScheduledWorkoutCell")
    }
    
    func loadData() {
        // Set stat values
        totalActiveDaysValueLabel.text = "12 Days"
        consecutiveDaysValueLabel.text = "7 Days"
        
        // Load day tracker items from Figma
        dayTrackerItems = [
            DayTrackerItem(icon: "🏋️", title: "Workout", subtitle: "Full body", isCompleted: true),
            DayTrackerItem(icon: "❤️", title: "Cardio", subtitle: "Running, 30 minutes", isCompleted: false),
            DayTrackerItem(icon: "💧", title: "Water Intake", subtitle: "8 litres", isCompleted: false),
            DayTrackerItem(icon: "🍽", title: "Diet Plan", subtitle: "Balanced", isCompleted: true),
            DayTrackerItem(icon: "🌙", title: "Sleep Cycle", subtitle: "8 hours", isCompleted: true)
        ]
        
        // Load scheduled workouts
        DataService.shared.loadClientDashboard { [weak self] result in
            switch result {
            case .success(let dashboard):
                self?.scheduledWorkouts = dashboard.todayWorkouts
                DispatchQueue.main.async {
                    self?.updateUI()
                }
            case .failure(let error):
                print("Error loading dashboard: \(error)")
            }
        }
    }
    
    func updateUI() {
        dayTrackerTableView.reloadData()
        scheduledWorkoutsTableView.reloadData()
        
        // Update table heights
        dayTrackerTableHeight.constant = CGFloat(dayTrackerItems.count) * 80
        scheduledWorkoutsTableHeight.constant = CGFloat(scheduledWorkouts.count) * 80
        
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
            cell.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
            cell.selectionStyle = .none
            cell.layer.cornerRadius = 12
            cell.clipsToBounds = true
            
            let item = dayTrackerItems[indexPath.row]
            
            // Remove all subviews first
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Icon label
            let iconLabel = UILabel()
            iconLabel.text = item.icon
            iconLabel.font = .systemFont(ofSize: 24)
            iconLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(iconLabel)
            
            // Title label
            let titleLabel = UILabel()
            titleLabel.text = item.title
            titleLabel.textColor = .white
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(titleLabel)
            
            // Subtitle label
            let subtitleLabel = UILabel()
            subtitleLabel.text = item.subtitle
            subtitleLabel.textColor = .textSecondary
            subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(subtitleLabel)
            
            // Checkbox
            let checkbox = UIView()
            checkbox.backgroundColor = item.isCompleted ? .primaryGreen : .clear
            checkbox.layer.cornerRadius = 8
            checkbox.layer.borderWidth = 2
            checkbox.layer.borderColor = item.isCompleted ? UIColor.primaryGreen.cgColor : UIColor.textSecondary.cgColor
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(checkbox)
            
            if item.isCompleted {
                let checkmark = UILabel()
                checkmark.text = "✓"
                checkmark.textColor = .black
                checkmark.font = .systemFont(ofSize: 16, weight: .bold)
                checkmark.textAlignment = .center
                checkmark.translatesAutoresizingMaskIntoConstraints = false
                checkbox.addSubview(checkmark)
                
                NSLayoutConstraint.activate([
                    checkmark.centerXAnchor.constraint(equalTo: checkbox.centerXAnchor),
                    checkmark.centerYAnchor.constraint(equalTo: checkbox.centerYAnchor)
                ])
            }
            
            NSLayoutConstraint.activate([
                iconLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                iconLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                
                titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 16),
                titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 20),
                
                subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                
                checkbox.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                checkbox.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                checkbox.widthAnchor.constraint(equalToConstant: 32),
                checkbox.heightAnchor.constraint(equalToConstant: 32)
            ])
            
            return cell
            
        } else {
            // Scheduled Workouts - create custom cells
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ScheduledWorkoutCell")
            cell.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
            cell.selectionStyle = .none
            cell.layer.cornerRadius = 12
            cell.clipsToBounds = true
            
            let todayWorkout = scheduledWorkouts[indexPath.row]
            
            cell.textLabel?.text = todayWorkout.name
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            
            cell.detailTextLabel?.text = todayWorkout.reps
            cell.detailTextLabel?.textColor = .textSecondary
            cell.detailTextLabel?.font = .systemFont(ofSize: 14, weight: .regular)
            
            // TODO: Add image from imageUrl if needed
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == dayTrackerTableView {
            dayTrackerItems[indexPath.row].isCompleted.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}
