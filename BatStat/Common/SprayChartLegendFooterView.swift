import UIKit

class SprayChartLegendFooterView: UICollectionReusableView {
    static let identifier = "SprayChartLegendFooterView"
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(stackView)
        
        // Create legend items
        let legendItems: [StatType] = [
            .single,
            .double,
            .triple,
            .homeRun,
            .flyOut
        ]
        
        // Create horizontal stack for legend items
        let legendStackView = UIStackView()
        legendStackView.axis = .horizontal
        legendStackView.spacing = 8
        legendStackView.alignment = .center
        legendStackView.distribution = .fillProportionally
        legendStackView.translatesAutoresizingMaskIntoConstraints = false

        
        for item in legendItems {
            let itemView = createLegendItem(title: item.legendLabel, color: item.color)
            legendStackView.addArrangedSubview(itemView)
        }
        
        stackView.addArrangedSubview(legendStackView)
        
        NSLayoutConstraint.activate([
            legendStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func createLegendItem(title: String, color: UIColor) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let colorView = UIView()
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 6
        colorView.layer.borderWidth = 1
        colorView.layer.borderColor = UIColor.white.cgColor
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(colorView)
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            colorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            colorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 12),
            colorView.heightAnchor.constraint(equalToConstant: 12),
            
            label.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 4),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            containerView.topAnchor.constraint(equalTo: colorView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: colorView.bottomAnchor)
        ])
        
        return containerView
    }
} 
