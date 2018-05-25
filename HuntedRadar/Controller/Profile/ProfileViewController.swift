//
//  ProfileViewController.swift
//  HuntedRadar
//
//  Created by BoTingDing on 2018/5/24.
//  Copyright © 2018年 BoTingDing. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwipeCellKit
class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {

    var forbidUser = [Forbid]()
    var isExpand = true
    var image: UIImageView!

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var forbidUserTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigation()
        setNavigationRightBurtton()
        setNib()
        setUserNameAndEmail()
        loadForbidUserFromFireBase()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationRightBurtton()
        setUserNameAndEmail()
        loadForbidUserFromFireBase()
        isExpand = true
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let button = UIButton(type: .system)
        button.setTitle("已封鎖用戶名單", for: .normal)
        
        //button image
         let imageName = "sort-up"
            image = UIImageView(image: UIImage(named: imageName))
            button.addSubview(image)
            image.translatesAutoresizingMaskIntoConstraints = false
            let horizontalConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: button, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 2)
            let verticalConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: button, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 60)
            let widthConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 20)
            let heightConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 20)
            button.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
        
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleExpandClose), for: .touchUpInside)
        button.tag = section
        button.layer.borderColor = UIColor.black.cgColor

        button.clipsToBounds = true
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 2
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button

    }

    @objc func handleExpandClose(_ sender: UIButton) {
        let section = sender.tag
        var indexPaths = [IndexPath]()
        for row in 0..<forbidUser.count {
            let indexPath = IndexPath(row: row, section: 0)
            indexPaths.append(indexPath)
        }
        let isExpanded = isExpand
        isExpand = !isExpanded
        if isExpanded {
                        image.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))

            forbidUserTableView.deleteRows(at: indexPaths, with: .fade)
        } else {
                        image.transform = CGAffineTransform(rotationAngle: 2 * CGFloat(Double.pi))

            forbidUserTableView.insertRows(at: indexPaths, with: .fade)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isExpand {
        return forbidUser.count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.forbidUserTableView.dequeueReusableCell(withIdentifier: String(describing: ForbidTableViewCell.self), for: indexPath) as? ForbidTableViewCell else {
            return UITableViewCell()
        }

        cell.delegate = self

        cell.userNameLabel.text = forbidUser[indexPath.row].userName
        
        cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, UIScreen.main.bounds.width)
        //不可被點選
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {

        guard orientation == .right else { return nil }

        let action = recoverAction(at: indexPath)

        return [action]
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func recoverAction(at indexPath: IndexPath) -> SwipeAction {
        //users can delete their message
        let action = SwipeAction(style: .destructive, title: "解除封鎖", handler: { (_, indexpath) in
            guard  Auth.auth().currentUser != nil else {
                self.alertAction(title: "您尚未登入", message: "請先登入再進行此操作")
                return
            }
            FirebaseManager.shared.deleteForbidUser(forbidUser: self.forbidUser[indexpath.row])

            self.forbidUser.remove(at: indexPath.row)
            self.forbidUserTableView.deleteRows(at: [indexPath], with: .fade)
        })
        action.backgroundColor = UIColor.green

        action.image = UIImage(named: "unlock")

        return action
    }

    func setNavigation() {
        navigationItem.rightBarButtonItem?.tintColor = .white
    }
    
    func setNavigationRightBurtton() {
        if Auth.auth().currentUser != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "exit"), style: .done, target: self, action: #selector(logout))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "sign-in"), style: .done, target: self, action: #selector(login))
        }
    }

    func setNib() {
        //xib的名稱
        let nib = UINib(nibName: String(describing: ForbidTableViewCell.self), bundle: nil)
        //註冊
        forbidUserTableView.register(nib, forCellReuseIdentifier: String(describing: ForbidTableViewCell.self))

        forbidUserTableView.delegate = self

        forbidUserTableView.dataSource = self
        
        forbidUserTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, UIScreen.main.bounds.width)

    }

    @objc func logout() {
        do {
            try Auth.auth().signOut()
            setSignOutSetting()
            let userdefault = UserDefaults.standard
            userdefault.set(nil, forKey: "userName")
            userdefault.set(nil, forKey: "Forbidden")
            setNavigationRightBurtton()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }

    @objc func login() {
    self.performSegue(withIdentifier: "login", sender: self)
    }
    
    func loadForbidUserFromFireBase() {
        FirebaseManager.shared.loadForbidUsers(completion: { forbidUser in

            self.forbidUser = forbidUser
            self.forbidUserTableView.reloadData()

        })
    }

    func alertAction(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { _ in
            self.performSegue(withIdentifier: "login", sender: self)

        })
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setUserNameAndEmail() {
        guard let user = Auth.auth().currentUser else {
           setSignOutSetting()
            return
        }
        forbidUserTableView.isHidden = false
        FirebaseManager.shared.getUserName(completion: {name in
            self.userNameLabel.text = name
            self.emailLabel.text = user.email
        })
    }
    
    func setSignOutSetting() {
        userNameLabel.text = "請先登入再進行操作"
        emailLabel.text = ""
        forbidUserTableView.isHidden = true
    }
}
