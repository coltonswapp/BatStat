import UIKit

class TextFieldCell: UICollectionViewListCell {
    static let identifier = "TextFieldCell"
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .label
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
    var onTextChanged: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }
    
    @objc private func textFieldChanged() {
        onTextChanged?(textField.text ?? "")
    }
    
    func configure(placeholder: String, text: String) {
        textField.placeholder = placeholder
        textField.text = text
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField.text = ""
        textField.placeholder = ""
        onTextChanged = nil
    }
}