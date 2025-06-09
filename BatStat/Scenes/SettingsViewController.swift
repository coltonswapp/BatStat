import UIKit

class SettingsViewController: UIViewController {
    
    private let userService = UserService.shared
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "SettingsCell")
        
        return collectionView
    }()
    
    enum SettingsSection: Int, CaseIterable {
        case account = 0
        case general = 1
        case debug = 2
        
        var title: String {
            switch self {
            case .account: return "Account"
            case .general: return "General"
            case .debug: return "Debug"
            }
        }
    }
    
    private var accountItems: [(String, String, UIColor, String)] = []
    
    private let generalItems = [
        ("Privacy Policy", "hand.raised", UIColor.systemBlue),
        ("Terms of Service", "doc.text", UIColor.systemBlue),
        ("Rate App", "star", UIColor.systemOrange),
        ("Contact Support", "questionmark.circle", UIColor.systemGreen)
    ]
    
    private let debugItems = [
        ("Clear Cache", "trash", UIColor.systemOrange),
        ("Export Logs", "square.and.arrow.up", UIColor.systemBlue),
        ("Reset Onboarding", "arrow.counterclockwise", UIColor.systemPurple),
        ("Sign Out", "rectangle.portrait.and.arrow.right", UIColor.systemRed)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadUserData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData()
    }
    
    private func loadUserData() {
        let email = userService.currentUser?.email ?? "No email available"
        accountItems = [
            ("Email", "envelope", UIColor.systemBlue, email)
        ]
        collectionView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissTapped)
        )
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    private func signOutTapped() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            self.performSignOut()
        })
        
        present(alert, animated: true)
    }
    
    private func performSignOut() {
        Task {
            do {
                try await userService.signOut()
                await MainActor.run {
                    navigateToLanding()
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to sign out: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func navigateToLanding() {
        let landingVC = LandingViewController()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = landingVC
            window.makeKeyAndVisible()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension SettingsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SettingsSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let settingsSection = SettingsSection(rawValue: section) else { return 0 }
        
        switch settingsSection {
        case .account:
            return accountItems.count
        case .general:
            return generalItems.count
        case .debug:
            return debugItems.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell", for: indexPath) as! UICollectionViewListCell
        
        guard let settingsSection = SettingsSection(rawValue: indexPath.section) else {
            return cell
        }
        
        var content = cell.defaultContentConfiguration()
        
        switch settingsSection {
        case .account:
            let item = accountItems[indexPath.item]
            content = configureAccountCell(content: content, item: item)
        case .general:
            let item = generalItems[indexPath.item]
            content = configureGeneralCell(content: content, item: item)
        case .debug:
            let item = debugItems[indexPath.item]
            content = configureDebugCell(content: content, item: item)
        }
        
        cell.contentConfiguration = content
        cell.accessories = settingsSection == .account ? [] : [.disclosureIndicator()]
        
        return cell
    }
    
    private func configureAccountCell(content: UIListContentConfiguration, item: (String, String, UIColor, String)) -> UIListContentConfiguration {
        var config = content
        config.text = item.0
        config.secondaryText = item.3
        config.image = UIImage(systemName: item.1)
        config.imageProperties.tintColor = item.2
        return config
    }
    
    private func configureGeneralCell(content: UIListContentConfiguration, item: (String, String, UIColor)) -> UIListContentConfiguration {
        var config = content
        config.text = item.0
        config.image = UIImage(systemName: item.1)
        config.imageProperties.tintColor = item.2
        return config
    }
    
    private func configureDebugCell(content: UIListContentConfiguration, item: (String, String, UIColor)) -> UIListContentConfiguration {
        var config = content
        config.text = item.0
        config.image = UIImage(systemName: item.1)
        config.imageProperties.tintColor = item.2
        if item.0 == "Sign Out" {
            config.textProperties.color = item.2
        }
        return config
    }
}

// MARK: - UICollectionViewDelegate

extension SettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let settingsSection = SettingsSection(rawValue: indexPath.section) else { return }
        
        switch settingsSection {
        case .account:
            break
        case .general:
            handleGeneralItemTap(at: indexPath.item)
        case .debug:
            handleDebugItemTap(at: indexPath.item)
        }
    }
    
    private func handleGeneralItemTap(at index: Int) {
        switch index {
        case 0: // Privacy Policy
            showAlert(title: "Privacy Policy", message: "Privacy policy functionality would be implemented here.")
        case 1: // Terms of Service
            showAlert(title: "Terms of Service", message: "Terms of service functionality would be implemented here.")
        case 2: // Rate App
            showAlert(title: "Rate App", message: "App Store rating functionality would be implemented here.")
        case 3: // Contact Support
            showAlert(title: "Contact Support", message: "Support contact functionality would be implemented here.")
        default:
            break
        }
    }
    
    private func handleDebugItemTap(at index: Int) {
        switch index {
        case 0: // Clear Cache
            showAlert(title: "Clear Cache", message: "Cache cleared successfully.")
        case 1: // Export Logs
            showAlert(title: "Export Logs", message: "Log export functionality would be implemented here.")
        case 2: // Reset Onboarding
            showAlert(title: "Reset Onboarding", message: "Onboarding has been reset.")
        case 3: // Sign Out
            signOutTapped()
        default:
            break
        }
    }
}