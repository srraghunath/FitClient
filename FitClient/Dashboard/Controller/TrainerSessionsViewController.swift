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
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .primaryGreen
        datePicker.overrideUserInterfaceStyle = .dark
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        navigationItem.titleView = datePicker
    }
    
    @objc private func dateChanged() {
        filterSessionsForDate(datePicker.date)
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
                self.filterSessionsForDate(self.datePicker.date)
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

