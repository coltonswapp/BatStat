//
//  ViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 4/29/25.
//

import UIKit

class ViewController: UIViewController {
//    let interactiveDiamondView = InteractiveDiamondView()
    
    let button: UIButton = {
        let button = UIButton(configuration: .tinted())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Show Sheet", for: .normal)
        button.addTarget(self, action: #selector(showSheetTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(button)
        
        view.backgroundColor = .systemBackground
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        title = "BatStat"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addNewGameTapped)
        )
    }
    
    @objc func addNewGameTapped() {
        let gameDetailVC = GameDetailViewController()
        let navController = UINavigationController(rootViewController: gameDetailVC)

        present(navController, animated: true)
    }
    
    @objc func showSheetTapped() {
//        let view = InteractiveDiamondViewController(nibName: nil, bundle: nil)
//        let nav = UINavigationController(rootViewController: view)
//        
//        if let sheet = nav.sheetPresentationController {
//            sheet.detents = [.medium()]
//            sheet.prefersGrabberVisible = true
//        }
//        present(nav, animated: true, completion: nil)
    }
}
