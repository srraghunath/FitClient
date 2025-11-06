//
//  TrainerClientsViewController.swift
//  FitClient
//
//  Created by admin8 on 05/11/25.
//

import UIKit

class TrainerClientsViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var clientsTableView: UITableView!
    
    private var allClients: [Client] = []
    private var filteredClients: [Client] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupTableView()
        setupSearchBar()
        loadClientsData()
    }
    
    private func setupNavigationBar() {
        
        title = "Clients"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addClientTapped)
        )
        addButton.tintColor = .primaryGreen
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupUI() {
        view.backgroundColor = .black
    }
    
    private func setupTableView() {
        clientsTableView.delegate = self
        clientsTableView.dataSource = self
        clientsTableView.applyAppStyle()
        
        let nib = UINib(nibName: "ClientTableViewCell", bundle: nil)
        clientsTableView.register(nib, forCellReuseIdentifier: "ClientTableViewCell")
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.applyAppStyle()
    }
    
    private func loadClientsData() {
        DataService.shared.loadClients { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let clients):
                self.allClients = clients
                self.filteredClients = clients
                self.clientsTableView.reloadData()
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private func addClientTapped() {
        print("Add client tapped")
    }
}

extension TrainerClientsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredClients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ClientTableViewCell", for: indexPath) as? ClientTableViewCell else {
            return UITableViewCell()
        }
        
        let client = filteredClients[indexPath.row]
        cell.configure(with: client)
        
        return cell
    }
}

extension TrainerClientsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let client = filteredClients[indexPath.row]
        print("Selected client: \(client.name)")
    }
}

extension TrainerClientsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredClients = allClients
        } else {
            filteredClients = allClients.filter { client in
                client.name.lowercased().contains(searchText.lowercased())
            }
        }
        clientsTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
