//
//  FeedViewController.swift
//  instagram
//
//  Created by Sajidah Wahdy on 3/7/22.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate{

    @IBOutlet weak var tableView: UITableView!
    let commentBar = MessageInputBar() //to instantiate
    var showsCommentBar = false
    var posts = [PFObject]()
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self //firing events
        

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive // pulls keyboard down if you drag it down
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func keyboardWillBeHidden(note: Notification){
        commentBar.inputTextView.text = nil //clear out everytime gets dimissed
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    // to be used with the the MessageInputBar which shows the messages as a bottom bar and gives a typing screen view
    override var inputAccessoryView: UIView?{
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool{
        return showsCommentBar //not show message bar by default
        
    }
    
    
    
    //refresh table view
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //get data, store data
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author", "comments", "comments.author"]) //to get from database
        query.limit = 20
        
        query.findObjectsInBackground{(posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
        
        
    }
    
    //user can add a new comment
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text//to reflect user's typed comment
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()! // recording user

        selectedPost.add(comment, forKey: "comments") //creating an array for comments
        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved")
            } else{
                print("Error saving comment")
            }
            
        }
        
        tableView.reloadData() //refresh itself
        
        //clear and dismiss the input bar
        commentBar.inputTextView.text = nil //clear out everytime gets dimissed
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
        }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //1 for each comment, 1 for each post/row
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? [] //whatever is on left; if nil then set equal to the array default value
        
        return comments.count + 2 // to include comment cell
    }
    //each section will have its own number of rows
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // grab post
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? [] //whatever is on left; if nil then set equal to the array default value
        
        //  post cell is with index 0
        if indexPath.row == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            
            cell.captionLabel.text = post["caption"] as? String
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af_setImage(withURL: url)
            
            return cell
        } else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            let comment = comments[indexPath.row - 1] // for first comment
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"]  as! PFUser
            cell.nameLabel.text = user.username
            
            return cell
        } else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            return cell
        }
        
    }
    
    //everytime taps a picture, will generate a comment row in parse database
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section] // create pf object
        let comments = (post["comments"] as? [PFObject]) ?? []//PFObject(className: "Comments") //will create a comment
        
        //if last cell, then show the comments
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            
            //raise keyboard
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
            
        }
    
    
    
    //what happens when they tap the logout button
    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()//logs out and clears cache
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        
//        let delegate = UIApplication.shared.delegate as! AppDelegate
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windowScene.delegate as? SceneDelegate else { return }
        
        delegate.window?.rootViewController = loginViewController
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

