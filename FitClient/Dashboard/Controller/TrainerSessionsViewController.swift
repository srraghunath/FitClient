//
//  TrainerSessionsViewController.swift
//  FitClient
//
//  Created by admin8 on 04/11/25.
//

import UIKit

class TrainerSessionsViewController: UIViewController {
    
    @IBOutlet weak var sessionsTableView: UITableView!
    
    private var datePicker: UIDatePicker!
    private var dateLabel: UILabel!
    private var calendarButton: UIButton!
    private var selectedDate: Date = Date()
    private var allSessions: [Session] = []
    private var todaySessions: [Session] = []
    private var upcomingSessions: [Session] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupTableView()
        loadSessionsData()
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
        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = .white
        calendarButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        calendarButton.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
        
        let calendarBarButton = UIBarButtonItem(customView: calendarButton)
        navigationItem.rightBarButtonItem = calendarBarButton
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
        dateChanged()
        dismiss(animated: true)
    }
    
    private func updateDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE,dd MMM yyyy" // No space after comma like Figma
        dateLabel.text = dateFormatter.string(from: selectedDate)
    }
    
    @objc private func dateChanged() {
        selectedDate = datePicker.date
        updateDateLabel()
        filterSessionsForDate(selectedDate)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black
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
    
    private func loadSessionsData() {
        DataService.shared.loadSessions { result in
            switch result {
            case .success(let sessionsData):
                self.allSessions = sessionsData.todaySessions + sessionsData.upcomingSessions
                self.filterSessionsForDate(self.selectedDate)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func filterSessionsForDate(_ date: Date) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDateString = dateFormatter.string(from: date)
        
        // Check if selected date is today
        let isToday = calendar.isDateInToday(date)
        
        // Filter sessions for selected date
        let sessionsForDate = allSessions.filter { session in
            return session.date == selectedDateString
        }
        
        if isToday {
            // If today, show in "Today" section
            todaySessions = sessionsForDate
            
            // Upcoming shows future dates
            upcomingSessions = allSessions.filter { session in
                if let sessionDate = dateFormatter.date(from: session.date) {
                    return sessionDate > date
                }
                return false
            }
        } else {
            // If not today, show selected date sessions in "Today" section
            todaySessions = sessionsForDate
            
            // Upcoming shows sessions after selected date
            upcomingSessions = allSessions.filter { session in
                if let sessionDate = dateFormatter.date(from: session.date) {
                    return sessionDate > date
                }
                return false
            }
        }
        
        sessionsTableView.reloadData()
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
        let session = indexPath.section == 0 ? todaySessions[indexPath.row] : upcomingSessions[indexPath.row]
        print("Selected session: \(session.clientName) at \(session.startTime)")
        // TODO: Navigate to session details
    }
}

