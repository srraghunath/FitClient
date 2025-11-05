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
            .foregroundColor: UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addClientTapped)
        )
        addButton.tintColor = UIColor(red: 0.682, green: 0.996, blue: 0.078, alpha: 1.0)
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupUI() {
        view.backgroundColor = .black
    }
    
    private func setupTableView() {
        clientsTableView.delegate = self
        clientsTableView.dataSource = self
        clientsTableView.backgroundColor = .black
        clientsTableView.separatorStyle = .none
        clientsTableView.showsVerticalScrollIndicator = false
        
        let nib = UINib(nibName: "ClientTableViewCell", bundle: nil)
        clientsTableView.register(nib, forCellReuseIdentifier: "ClientTableViewCell")
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = .black
        searchBar.backgroundColor = .black
        searchBar.backgroundImage = UIImage()
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor(red: 0.188, green: 0.192, blue: 0.192, alpha: 1.0)
            textField.textColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search",
                attributes: [.foregroundColor: UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 0.6)]
            )
            textField.leftView?.tintColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        }
    }
    
    private func loadClientsData() {
        guard let url = Bundle.main.url(forResource: "clientsData", withExtension: "json") else {
            print("Error: clientsData.json not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let clientsData = try decoder.decode(ClientsData.self, from: data)
            allClients = clientsData.clients
            filteredClients = allClients
            clientsTableView.reloadData()
        } catch {
            print("Error loading clients data: \(error)")
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
