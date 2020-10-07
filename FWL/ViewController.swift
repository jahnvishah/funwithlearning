//
//  ViewController.swift
//  FWL
//
//  Created by Jahnvi on 07/10/20.
//  Copyright © 2020 Jahnvi. All rights reserved.
//

import UIKit
import SQLite3

class AnagramViewController: UITableViewController {

    var allWords = [String]()
    var usedWords = [String]()
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(startGame))
            
            if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt"){
                if let startWords = try? String(contentsOf: startWordsURL){
                    allWords = startWords.components(separatedBy: "\n")
                }
            }
            if allWords.isEmpty {
                allWords = ["clementine"]
            }
        
            
            let defaults = UserDefaults()
            let jsonDecoder = JSONDecoder()
            if let savedWords = defaults.object(forKey: "used") as? Data {
                do {
                    usedWords = try jsonDecoder.decode([String].self, from: savedWords)
                } catch {
                       print("Failed to load words")
                }
            } else {
                startGame()
            }
            if let mainWord = defaults.object(forKey: "word") as? Data {
                do {
                    title = try jsonDecoder.decode(String.self, from: mainWord)
                } catch {
                       print("Failed to load words")
                }
            } else {
                startGame()
            }
        }
        
        @objc func startGame(){
            title = allWords.randomElement()
            save()
            usedWords.removeAll(keepingCapacity: true)
            tableView.reloadData()
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return usedWords.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
            cell.textLabel?.text = usedWords[indexPath.row]
            return cell
        }
        
        @objc func promptForAnswer(){
            let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
            ac.addTextField()
            
            let submitAction = UIAlertAction(title: "Submit", style: .default){
                [weak self,weak ac] _ in
                guard let answer = ac?.textFields?[0].text else{return}
                self?.submit(answer)
            }
            
            ac.addAction(submitAction)
            present(ac, animated: true)
        }
        
        func submit(_ answer: String) {
            let lowerAnswer = answer.lowercased()
            
            if isShort(word: lowerAnswer) {
                if isPossible(word: lowerAnswer) {
                    if isOriginal(word: lowerAnswer) {
                        if isReal(word: lowerAnswer) {
                            usedWords.insert(answer, at: usedWords.count)
                            save()
                            let indexPath = IndexPath(row: usedWords.count-1, section: 0)
                            tableView.insertRows(at: [indexPath], with: .automatic)
                            return
                        } else{
                            showErrorMessage(errorTitle: "Word not recognised", errorMessage: "You can't just make them up, you know!")
                        }
                    } else {
                            showErrorMessage(errorTitle: "Word used already", errorMessage: "Be more original!")
                        }
                } else {
                    guard let title = title?.lowercased() else { return }
                    showErrorMessage(errorTitle: "Word not possible", errorMessage: "You can't spell that word from \(title)")
                }
            } else {
                showErrorMessage(errorTitle: "Word is too short", errorMessage: "The word needs to be atleast 4 lettered")
            }
            
            
        }
        
        func isPossible(word: String) -> Bool {
            guard var tempWord = title?.lowercased() else { return false }
            for letter in word {
                if let position = tempWord.firstIndex(of: letter){
                    tempWord.remove(at: position)
                } else {
                    return false
                }
            }
            return true
        }
        
        func isOriginal(word: String) -> Bool {
            return !(usedWords.contains(word) || word == title)
        }
        
        func isReal(word: String) -> Bool {
            let checker = UITextChecker()
            let range = NSRange(location: 0, length: word.utf16.count)
            let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
            return misspelledRange.location == NSNotFound
        }
        
        func isShort(word: String) -> Bool {
            if word.count <= 3 {
                return false
            } else {
                return true
            }
        }
        
        func showErrorMessage(errorTitle: String,errorMessage: String){
            let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        func save() {
            let jsonEncoder = JSONEncoder()
            let defaults = UserDefaults.standard
            if let savedData = try? jsonEncoder.encode(usedWords) {
                defaults.set(savedData, forKey: "used")
            } else {
                print("Failed to save words.")
            }
            if let savedData = try? jsonEncoder.encode(title) {
                defaults.set(savedData, forKey: "word")
            } else {
                print("Failed to save words.")
            }
        }
    }

class FlagsViewController: UIViewController {
    
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    @IBOutlet var button3: UIButton!
    
    var countries=[String]()
        var score=0
        var correctAnswer = 0
        var timesAsked = 0
        var highScore = 0
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            countries += ["estonia","france","germany","ireland","italy","monaco","nigeria","poland","russia","spain","uk","us"]
                
            button1.layer.borderWidth = 1
            button2.layer.borderWidth = 1
            button3.layer.borderWidth = 1
            
            button1.layer.borderColor = UIColor.lightGray.cgColor
            button2.layer.borderColor = UIColor.lightGray.cgColor
            button3.layer.borderColor = UIColor.lightGray.cgColor
            
     
            let defaults = UserDefaults()
            if let savedHS = defaults.object(forKey: "hs") as? Data{
                do{
                    let decoder = JSONDecoder()
                    highScore = try decoder.decode(Int.self, from: savedHS)
                } catch{
                    print("bleh")
                }
            }
            
            
            askQuestion()
        }

        
        
        func askQuestion(action: UIAlertAction!=nil) {
            
            if (timesAsked==5){
                let title = "Game Over"
                var message = "You have played the game 10 times!"
                
                if (score>highScore){
                    highScore=score
                    save()
                    message+="\nYou have set a new high score at \(highScore) !"
                }
                else{
                    message+="\n\(highScore) is the score to beat !"
                }
            
            
            let gameOver = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
                
            
            let newGame = UIAlertAction(title: "New Game", style: .default, handler: {
                (action: UIAlertAction) in
                self.score=0
                self.timesAsked=0
                self.askQuestion()
                
            })
            gameOver.addAction(newGame)
            
            let share = UIAlertAction(title: "Share Score", style: .default, handler: shareScore)
            gameOver.addAction(share)
                
                
            let quit = UIAlertAction(title: "Quit", style: .destructive, handler: {
                (action: UIAlertAction) in
                exit(0)
            })
            gameOver.addAction(quit)
                
                
            present(gameOver,animated: true)
            }
            
            countries.shuffle()
            correctAnswer=Int.random(in: 0...2)
            timesAsked+=1
            
            button1.setImage(UIImage(named: countries[0]), for: .normal)
            button2.setImage(UIImage(named: countries[1]), for: .normal)
            button3.setImage(UIImage(named: countries[2]), for: .normal)
            
            title = countries[correctAnswer].uppercased()+"    Current Score: \(score)"
        }
        
        
        func shareScore(action: UIAlertAction){
            let ac = UIActivityViewController(activityItems: ["My score in GUESS THE FLAG is \(score).\nWhat's your's?"], applicationActivities: nil)
            present(ac,animated: true)
            score=0
            timesAsked=0
            askQuestion()
        }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        var title: String
        var message: String
        
        if sender.tag == correctAnswer{
            title="Correct"
            score+=1
            message = "Your score is \(score) "
        } else{
            title="Wrong"
            score-=1
            message = "That was the flag of \(countries[sender.tag].uppercased())\nYour score is \(score) "
        }
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "Continue", style: .default, handler: askQuestion))
        
        present(ac,animated: true)
    }
    
        func save(){
            
            let jsonEncoder = JSONEncoder()
            if let savedHighScore = try? jsonEncoder.encode(highScore) {
                let defaults = UserDefaults.standard
                defaults.set(savedHighScore, forKey: "hs")
            }
            
        }
        
    }

class UsersViewController: UIViewController {
    
    var db: OpaquePointer?
    
    @IBOutlet weak var tableViewHeroes: UITableView!
    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var textFieldPowerRanking: UITextField!
    
    @IBAction func buttonSave(_ sender: UIButton) {
        //getting values from textfields
               let name = textFieldName.text?.trimmingCharacters(in: .whitespacesAndNewlines)
               let powerRanking = textFieldPowerRanking.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
               //validating that values are not empty
               if(name?.isEmpty)!{
                   textFieldName.layer.borderColor = UIColor.red.cgColor
                   return
               }
        
               if(powerRanking?.isEmpty)!{
                   textFieldName.layer.borderColor = UIColor.red.cgColor
                   return
               }
        
               //creating a statement
               var stmt: OpaquePointer?
        
               //the insert query
               let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (?,?)"
        
               //preparing the query
               if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
                   let errmsg = String(cString: sqlite3_errmsg(db)!)
                   print("error preparing insert: \(errmsg)")
                   return
               }
        
               //binding the parameters
               if sqlite3_bind_text(stmt, 1, name, -1, nil) != SQLITE_OK{
                   let errmsg = String(cString: sqlite3_errmsg(db)!)
                   print("failure binding name: \(errmsg)")
                   return
               }
        
               if sqlite3_bind_int(stmt, 2, (powerRanking! as NSString).intValue) != SQLITE_OK{
                   let errmsg = String(cString: sqlite3_errmsg(db)!)
                   print("failure binding name: \(errmsg)")
                   return
               }
        
               //executing the query to insert values
               if sqlite3_step(stmt) != SQLITE_DONE {
                   let errmsg = String(cString: sqlite3_errmsg(db)!)
                   print("failure inserting hero: \(errmsg)")
                   return
               }
        
               //emptying the textfields
               textFieldName.text=""
               textFieldPowerRanking.text=""
        
        
               //displaying a success message
                let ac = UIAlertController(title: "Registered", message: "User saved successfully", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
    }
    
    override func viewDidLoad() {
    super.viewDidLoad()
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Heroes.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Heroes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, powerrank INTEGER)", nil, nil, nil) != SQLITE_OK {
                   let errmsg = String(cString: sqlite3_errmsg(db)!)
                   print("error creating table: \(errmsg)")
               }
    }
}
