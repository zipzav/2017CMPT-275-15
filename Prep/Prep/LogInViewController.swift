//
//  LogInViewController.swift
//  Prep
//
//  Created by Bill on 2017/11/10.
//  Copyright © 2017年 Zavier Patrick David Aguila. All rights reserved.
//

import UIKit
import FirebaseAuth

class LogInViewController: UIViewController {


    @IBOutlet weak var SignInSelection: UISegmentedControl!
    
    @IBOutlet weak var SignInLabel: UILabel!
    
    @IBOutlet weak var EmailTextField: UITextField!
    
    @IBOutlet weak var PasswordTextField: UITextField!
    
    @IBOutlet weak var SignInButton: UIButton!
    
    var isSignIn:Bool = true
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func SignInSelectorChanged(_ sender: UISegmentedControl) {
        
        isSignIn = !isSignIn
        //Check the bool and set the button and labels
        if isSignIn {
            SignInLabel.text = "Sign In"
            SignInButton.setTitle("Sign In", for: .normal)
        }
        else {
            SignInLabel.text = "Register"
            SignInButton.setTitle("Register", for: .normal)
        }
    }
    
    @IBAction func SignInButtonTapped(_ sender: UIButton) {
        
        //Checking email and password
    if let email = EmailTextField.text, let password = PasswordTextField.text {
            //Check if it's signin or register
            if isSignIn {
                //Signin the user with Firebase
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    //Check that user is not null
                    if let u = user{
                        //User is found. Take to home screen
                        self.performSegue(withIdentifier: "GoToHomePage", sender: self)
                    }
                    else {
                        //Error
                        
                    }
                })
                // ...
            }
            else{
                //Register the user with Firebase
                Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                    if let u = user {
                        self.performSegue(withIdentifier: "GoToHomePage", sender: self)
                    }
                    else{
                        
                    }
                })
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func touchesBegan(_ touches: Set<UITouch>, with: UIEvent?){
        EmailTextField.resignFirstResponder()
        PasswordTextField.resignFirstResponder()
    }
}
