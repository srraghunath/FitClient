//
//  TrainerSessionsViewController.swift
//  FitClient
//
//  Created by admin8 on 04/11/25.
//

import UIKit

class TrainerSessionsViewController: UIViewController {
    
    @IBOutlet weak var sessionsTableView: UITableView!
    
    private var allSessions: [Session] = []
    private var todaySessions: [Session] = []
    private var upcomingSessions: [Session] = []
    private var selectedDate = Date()
    private var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupTableView()
        loadSessionsData()
        updateDateLabel()
    }
    
    private func setupNavigationBar() {
        // Create date label as title view
        dateLabel = UILabel()
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = .textPrimary
        dateLabel.textAlignment = .center
        navigationItem.titleView = dateLabel
        
        // Create calendar button
        let calendarButton = UIBarButtonItem(
            image: UIImage(systemName: "calendar.badge.clock"),
            style: .plain,
            target: self,
            action: #selector(calendarButtonTapped)
        )
        calendarButton.tintColor = .textPrimary
        navigationItem.rightBarButtonItem = calendarButton
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
        DataService.shared.loadSessions { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let sessionsData):
                // Store all sessions
                self.allSessions = sessionsData.todaySessions + sessionsData.upcomingSessions
                
                // Filter for selected date
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
    
    private func updateDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy"
        dateLabel.text = dateFormatter.string(from: selectedDate)
    }
    
    @objc private func calendarButtonTapped() {
        showDatePicker()
    }
    
    private func showDatePicker() {
        let alert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = selectedDate
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        alert.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            datePicker.widthAnchor.constraint(equalToConstant: 270),
            datePicker.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        let selectAction = UIAlertAction(title: "Select", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.selectedDate = datePicker.date
            self.updateDateLabel()
            self.filterSessionsForDate(self.selectedDate)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(selectAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
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
        label.text = section == 0 ? "Today" : "Upcoming"
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

