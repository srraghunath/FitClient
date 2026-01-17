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
    @IBOutlet private weak var totalActiveDaysLabel: UILabel!
    @IBOutlet private weak var consecutiveActiveDaysLabel: UILabel!
    @IBOutlet private weak var recentActivitiesTableView: UITableView!
    @IBOutlet private weak var tableHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    var client: Client?
    private var clientProfile: ClientProfile?
    private var currentChildViewController: UIViewController?
    private let activityTableMaxHeight: CGFloat = 360
    
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
        setupProfileUI()
        setupSegmentedControl()
    }
    
    private func setupProfileUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        
        guard let client = client else { return }
        nameLabel.text = client.name
        specialtyLabel.text = client.goal ?? "Fitness Enthusiast"
        goalsLabel.text = "Goals: \(client.level)"
        
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
        recentActivitiesTableView.register(UINib(nibName: "ActivityTableViewCell", bundle: nil), forCellReuseIdentifier: "ActivityCell")
        recentActivitiesTableView.delegate = self
        recentActivitiesTableView.dataSource = self
        recentActivitiesTableView.backgroundColor = .black
        recentActivitiesTableView.separatorStyle = .none
        recentActivitiesTableView.rowHeight = UITableView.automaticDimension
        recentActivitiesTableView.estimatedRowHeight = 88
        recentActivitiesTableView.isScrollEnabled = false
        recentActivitiesTableView.showsVerticalScrollIndicator = false
    }
    
    private func loadClientProfile() {
        guard let clientId = client?.id else {
            showAlert(title: "Error", message: "Client information not available")
            return
        }
        
        print("Loading profile for client ID: \(clientId)")  // Debug log
        
        DataService.shared.loadClientProfile(forClientId: clientId.uuidString) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self?.clientProfile = profile
                case .failure:
                    // Graceful fallback for Supabase-backed clients without local JSON profile
                    let placeholder = ClientProfile(
                        totalActiveDays: 0,
                        consecutiveActiveDays: 0,
                        recentActivities: []
                    )
                    self?.clientProfile = placeholder
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
            self.recentActivitiesTableView.layoutIfNeeded()
            let shouldScroll = true
            self.recentActivitiesTableView.isScrollEnabled = shouldScroll
            self.recentActivitiesTableView.alwaysBounceVertical = shouldScroll
        }
    }
    
    private func updateProfileUI() {
        guard let profile = clientProfile else { return }
        totalActiveDaysLabel.text = "\(profile.totalActiveDays) Days"
        consecutiveActiveDaysLabel.text = "\(profile.consecutiveActiveDays) Days"
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
        return clientProfile?.recentActivities.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath) as? ActivityTableViewCell,
              let activity = clientProfile?.recentActivities[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.configure(with: activity)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
