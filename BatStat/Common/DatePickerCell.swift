import UIKit

class DatePickerCell: UICollectionViewListCell {
    static let identifier = "DatePickerCell"
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        return picker
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Game Date"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    var onDateChanged: ((Date) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            datePicker.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            datePicker.centerYAnchor.constraint(equalTo: centerYAnchor),
            datePicker.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }
    
    private func setupActions() {
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }
    
    @objc private func dateChanged() {
        onDateChanged?(datePicker.date)
    }
    
    func configure(date: Date) {
        datePicker.date = date
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        datePicker.date = Date()
        onDateChanged = nil
    }
}