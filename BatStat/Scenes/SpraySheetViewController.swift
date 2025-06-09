import UIKit

class SpraySheetViewController: UIViewController {
    
    private lazy var diamondVisualizationView: DiamondVisualizationView = {
        let view = DiamondVisualizationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var legendFooterView: SprayChartLegendFooterView = {
        let view = SprayChartLegendFooterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var player: Player?
    private var currentGame: Game?
    private var playerAtBats: [Stat] = []
    private var selectedAtBatIndex: Int? // Track which at-bat is selected for highlighting
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    func configure(with player: Player, game: Game, atBats: [Stat]) {
        self.player = player
        self.currentGame = game
        self.playerAtBats = atBats
        
        updateDiamondVisualization()
    }
    
    func updateSelectedAtBat(_ atBatNumber: Int?) {
        selectedAtBatIndex = atBatNumber
        updateDiamondVisualization()
    }
    
    private func updateDiamondVisualization() {
        // Show hits with real data from this game
        let hitsWithLocation = playerAtBats.filter { $0.hitLocation != nil }
        diamondVisualizationView.plotHits(hitsWithLocation, selectedAtBatNumber: selectedAtBatIndex)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(diamondVisualizationView)
        view.addSubview(legendFooterView)
        
        NSLayoutConstraint.activate([
            // Diamond visualization view
            diamondVisualizationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            diamondVisualizationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            diamondVisualizationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            diamondVisualizationView.heightAnchor.constraint(equalTo: diamondVisualizationView.widthAnchor),
            
            // Legend footer view
            legendFooterView.topAnchor.constraint(equalTo: diamondVisualizationView.bottomAnchor, constant: 16),
            legendFooterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            legendFooterView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            legendFooterView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupNavigationBar() {
        guard let player = player else { return }
        title = "\(player.name) - Spray Chart"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Add close button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
} 