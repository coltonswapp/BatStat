import UIKit

class RecordAtBatViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(AtBatOptionCell.self, forCellWithReuseIdentifier: AtBatOptionCell.identifier)
        collectionView.register(InteractiveDiamondCell.self, forCellWithReuseIdentifier: InteractiveDiamondCell.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        return collectionView
    }()
    
    private let atBatOptions: [AtBatOption] = {
        return AtBatOption.AtBatOptionType.allCases.map { AtBatOption(option: $0) }
    }()
    
    private var selectedOptionIndex: Int?
    private var selectedRBICount: Int?
    private var hitLocation: CGPoint?
    private var ballHeight: CGFloat = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
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
        title = "Record At-Bat"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        // Initially disable save until user makes selections
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createAtBatOptionsSection(environment: environment)
            case 1:
                return self.createInteractiveDiamondSection(environment: environment)
            default:
                return self.createAtBatOptionsSection(environment: environment)
            }
        })
    }
    
    private func createAtBatOptionsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createInteractiveDiamondSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func updateSaveButtonState() {
        guard let selectedIndex = selectedOptionIndex else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        
        let selectedOption = atBatOptions[selectedIndex]
        let hasRBICountIfNeeded = !selectedOption.showRBIButton || selectedRBICount != nil
        
        navigationItem.rightBarButtonItem?.isEnabled = hasRBICountIfNeeded
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let selectedIndex = selectedOptionIndex else { return }
        
        let selectedOption = atBatOptions[selectedIndex]
        
        // TODO: Save the at-bat result
        print("Saving at-bat:")
        print("- Option: \(selectedOption.title)")
        if let rbiCount = selectedRBICount {
            print("- RBI Count: \(rbiCount)")
        }
        if let hitLocation = hitLocation {
            print("- Hit Location: \(hitLocation)")
            print("- Ball Height: \(ballHeight)")
        }
        
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension RecordAtBatViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return atBatOptions.count
        case 1:
            return 1 // Interactive diamond section
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOptionCell.identifier, for: indexPath) as! AtBatOptionCell
            let option = atBatOptions[indexPath.item]
            let isSelected = selectedOptionIndex == indexPath.item
            cell.configure(with: option, isSelected: isSelected)
            
            // Handle RBI selection
            cell.onRBISelection = { [weak self] rbiCount in
                self?.selectedRBICount = rbiCount
                self?.updateSaveButtonState()
            }
            
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InteractiveDiamondCell.identifier, for: indexPath) as! InteractiveDiamondCell
            cell.configure()
            
            // Handle hit recording
            cell.onHitRecorded = { [weak self] location, height in
                self?.hitLocation = location
                self?.ballHeight = height
            }
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
            
            switch indexPath.section {
            case 0:
                header.configure(title: "BALL IN PLAY")
            case 1:
                header.configure(title: "LOG HIT")
            default:
                header.configure(title: "")
            }
            
            return header
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension RecordAtBatViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            let selectedOption = atBatOptions[indexPath.item]
            
            // Don't allow selecting the RBI cell directly - only the button
            if selectedOption.type == .rbi {
                return
            }
            
            // Select at-bat option
            selectedOptionIndex = indexPath.item
            
            // Reset RBI count if not RBI option
            if !selectedOption.showRBIButton {
                selectedRBICount = nil
            }
            
            updateSaveButtonState()
            
            // Update checkmarks without animation
            UIView.performWithoutAnimation {
                collectionView.reloadSections(IndexSet([0]))
            }
            
            print("Selected: \(selectedOption.title)")
            
        case 1:
            // Interactive diamond tapped - no action needed, handled by the cell
            break
            
        default:
            break
        }
    }
}
