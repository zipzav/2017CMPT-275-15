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
    
    @IBOutlet weak var PrepLogo: UIImageView!
    
    
    var isSignIn:Bool = true
    
    
    //SignInSelection.tintColor = UIColor(red: 140.0/255.0, green: 228.0/255.0, blue: 161.0/255.0, alpha: 1.0)

    
    override func viewDidLoad() {
        let currentUser = Auth.auth().currentUser
        if currentUser != nil
        {
            
            self.navigationItem.setHidesBackButton(true, animated: false)
            self.performSegue(withIdentifier: "GoToHomePage", sender: self)
            
            //let userID : String = (Auth.auth().currentUser?.uid)!
            //self.showMessagePrompt("Current user ID is" + userID)
        }
        else
        {
            super.viewDidLoad()
            //Set the segnmented slection to match the color of the theme
            SignInSelection.tintColor = UIColor.PrepGreen
        
            //Set the segnmented slection text (font size) to match the theme
            let font = UIFont.systemFont(ofSize: 18)
            SignInSelection.setTitleTextAttributes([NSAttributedStringKey.font: font], for: .normal)
        
            //Setting the background color of the button
            SignInButton.backgroundColor = UIColor.PrepPurple
        
            //Making the corners of the sign-in button rounded to match the style of the page
            SignInButton.layer.cornerRadius = 5
            SignInButton.layer.borderWidth = 1
            SignInButton.layer.borderColor = UIColor.PrepPurple.cgColor
            var firstload = false
        }
   }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func SignInSelectorChanged(_ sender: UISegmentedControl) {
        isSignIn = !isSignIn
        //Check the bool and set the button and labels
        if isSignIn {
            //SignInLabel.text = "Sign In"
            SignInButton.setTitle("Sign In", for: .normal)
        }
        else {
            //SignInLabel.text = "Register"
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
                        self.showMessagePrompt("Email or password is incorrect.")
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
                        // TODO: Mandy, Please refer to this website for adding spinner and error message. https://github.com/firebase/quickstart-ios/blob/master/authentication/AuthenticationExampleSwift/EmailViewController.swift
                        if (password.count < 6){
                                self.showMessagePrompt("Password has to be at least length 6.")
                        }
                        self.showMessagePrompt("Email or password can't be empty.")
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
