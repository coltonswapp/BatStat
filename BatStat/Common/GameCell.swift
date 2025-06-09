import UIKit

class GameCell: UICollectionViewCell {
    static let identifier = "GameCell"
    
    private let opponentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.cornerCurve = .continuous
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.quaternaryLabel.cgColor
        
        addSubview(opponentLabel)
        addSubview(dateLabel)
        addSubview(resultLabel)
        
        NSLayoutConstraint.activate([
            opponentLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            opponentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            opponentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: opponentLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            resultLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            resultLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            resultLabel.widthAnchor.constraint(equalToConstant: 44),
            resultLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with game: Game) {
        opponentLabel.text = "vs. \(game.opponent)"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        dateLabel.text = formatter.string(from: game.date)
        
        if let homeScore = game.homeScore, let opponentScore = game.opponentScore {
            let isWin = homeScore > opponentScore
            resultLabel.text = isWin ? "WIN" : "LOSS"
            resultLabel.backgroundColor = isWin ? .systemGreen : .systemRed
            resultLabel.textColor = .white
        } else {
            resultLabel.text = "TBD"
            resultLabel.backgroundColor = .systemGray5
            resultLabel.textColor = .secondaryLabel
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        opponentLabel.text = nil
        dateLabel.text = nil
        resultLabel.text = nil
        resultLabel.backgroundColor = nil
        resultLabel.textColor = nil
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
                self.alpha = self.isHighlighted ? 0.8 : 1.0
            }
        }
    }
}
