//
//  TableViewController.swift
//  GitDiff
//
//  Created by Jonathan Brower on 6/21/17.
//  Copyright © 2017 Jonathan Brower. All rights reserved.
//

import UIKit

//MARK: - pullRequestTableViewController
class pullRequestTableViewController: UITableViewController {
    
    var prTitleArray = [String]()
    var prDescriptionArray = [String]()
    var prNumberArray = [NSNumber]()
    var prDiffUrlArray = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        //To remove overlap of status bar
        tableView.contentInset.top = 20
        getPullRequests()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Return number of sections to be shown in tableview
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    //Return number of rows to be shown in tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if prTitleArray.count > 0 {
            return prTitleArray.count
        }
        return 1
    }

    //Update values in each cell to display pull request information
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prCell", for: indexPath) as! pullRequestTableViewCell

        if prTitleArray.count == 0 {
            cell.titleLabel.text = "Loading..."
            cell.numberLabel.text = ""
            cell.descriptionLabel.text = ""
        } else {
            cell.titleLabel.text = prTitleArray[indexPath.item]
            cell.numberLabel.text = "#" + prNumberArray[indexPath.item].stringValue
            cell.descriptionLabel.text = prDescriptionArray[indexPath.item]
        }

        return cell
    }
    
    //Update values in table to new loaded values
    func refreshTable() {
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }

    //Handle row selection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "pushRequestToChangedFiles", sender: indexPath)
    }
    
    //Handle segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "pushRequestToChangedFiles") {
            let controller = (segue.destination as! changedFilesTableViewController)
            let row = (sender as! NSIndexPath).item
            controller.diffUrl = prDiffUrlArray[row]
        }
    }
    
    //Get pull request information for MagicalRecord
    func getPullRequests() {
        prTitleArray = []
        prNumberArray = []
        prDescriptionArray = []
        let requestURL: NSURL = NSURL(string: "https://api.github.com/repos/magicalpanda/MagicalRecord/pulls")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    if json is [String: Any] {
                        //json is a dictionary
                        print("JSON is an unexpected dictionary")
                    } else if let jsonData = json as? [Any] {
                        //json is an array
                        for index in 0...jsonData.count-1 {
                            let arrayObject = jsonData[index] as! [String: AnyObject]
                            self.prTitleArray.append(arrayObject["title"] as! String)
                            self.prDescriptionArray.append(arrayObject["body"] as! String)
                            self.prNumberArray.append(arrayObject["number"] as! NSNumber)
                            self.prDiffUrlArray.append(arrayObject["diff_url"] as! String)
                        }
                        self.refreshTable()
                    } else {
                        print("JSON is invalid")
                    }
                } catch {
                    print("There is an error with the JSON: \(error)")
                }
            }
        }
        
        task.resume()
    }
}

//MARK: - changedFilesTableViewController
class changedFilesTableViewController: UITableViewController {
    
    var diffUrl = String()
    var fileNamesArray = [String]()
    var negLinesDict = Dictionary<Int, Array<String>>()
    var posLinesDict = Dictionary<Int, Array<String>>()
    var negTextDict = Dictionary<Int, Array<String>>()
    var posTextDict = Dictionary<Int, Array<String>>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //To remove overlap of status bar
        tableView.contentInset.top = 20
        getDiff()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Return number of sections to be shown in tableview
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Return number of rows to be shown in tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fileNamesArray.count > 0 {
            return fileNamesArray.count
        }
        return 1
    }
    
    //Update values in each cell to display pull request information
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fCell", for: indexPath) as! changedFilesTableViewCell
        
        if fileNamesArray.count == 0 {
            cell.fileLabel.text = "Loading..."
        } else {
            cell.fileLabel.text = fileNamesArray[indexPath.item]
        }
        
        return cell
    }
    
    //Update values in table to new loaded values
    func refreshTable() {
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
    
    //Fill arrays of differences
    func getDiff() {
        let requestURL: NSURL = NSURL(string: diffUrl)!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                //Load .diff file into string
                let diffFile = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                    
                //Use regex to seperate each line
                let outerPattern = "^(.*)$"
                let outerRegex = try! NSRegularExpression(pattern: outerPattern, options: [.caseInsensitive, .anchorsMatchLines])
                //Break out each line into a seperate outer match
                let oMatches = outerRegex.matches(in: diffFile!, options: [], range: NSRange(location: 0, length: (diffFile?.characters.count)!))
                var fileNum = -1

                //Check each line for different possible matching indicators
                for oMatch in oMatches {
                    let range = oMatch.rangeAt(1)
                    let line = (diffFile! as NSString).substring(with: range)
                        
                    //Ignore these lines
                    let ignorePattern1 = "^diff --git (.*)$"
                    let ignorePattern2 = "^new file mode (.*)$"
                    let ignorePattern3 = "^index (.*)..(.*)$"
                    let ignorePattern4 = "^\\+\\+\\+(.*)$"
                    var ignoreRegex = try! NSRegularExpression(pattern: ignorePattern1, options: .caseInsensitive)
                    if ignoreRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) != nil {
                        //Jump to next oMatch
                        continue
                    }
                    ignoreRegex = try! NSRegularExpression(pattern: ignorePattern2, options: .caseInsensitive)
                    if ignoreRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) != nil {
                        //Jump to next oMatch
                        continue
                    }
                    ignoreRegex = try! NSRegularExpression(pattern: ignorePattern3, options: .caseInsensitive)
                    if ignoreRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) != nil {
                        //Jump to next oMatch
                        continue
                    }
                    ignoreRegex = try! NSRegularExpression(pattern: ignorePattern4, options: .caseInsensitive)
                    if ignoreRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) != nil {
                        //Jump to next oMatch
                        continue
                    }
                        
                    //File names that have been changed regex
                    let changedFilesPattern = "^--- a(.*)$"
                    let changedFilesRegex = try! NSRegularExpression(pattern: changedFilesPattern, options: .caseInsensitive)
                    //Line numbers that have changed regex
                    let lineNumberPattern = "^@@ -(.*),(.*) \\+(.*),(.*) @@(.*)$"
                    let lineNumberRegex = try! NSRegularExpression(pattern: lineNumberPattern, options: .caseInsensitive)
                    //Removed line regex
                    let negLinePattern = "^-(.*)"
                    let negLineRegex = try! NSRegularExpression(pattern: negLinePattern, options: .caseInsensitive)
                    //Added line regex
                    let posLinePattern = "^\\+(.*)"
                    let posLineRegex = try! NSRegularExpression(pattern: posLinePattern, options: .caseInsensitive)
                    
                    //Get files names that have been changed
                    if let iMatch = changedFilesRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) {
                        self.fileNamesArray.append(((line as NSString).substring(with: iMatch.rangeAt(1))))
                        fileNum += 1
                        self.negLinesDict[fileNum] = []
                        self.posLinesDict[fileNum] = []
                        self.negTextDict[fileNum] = []
                        self.posTextDict[fileNum] = []
                        continue
                    //Get line numbers for changed text in files
                    } else if let iMatch = lineNumberRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) {
                        var lineNum = (line as NSString).substring(with: iMatch.rangeAt(1))
                        var count = Int((line as NSString).substring(with: iMatch.rangeAt(2)))!
                        for _ in 1...count {
                            self.negLinesDict[fileNum]?.append(lineNum)
                            lineNum =  String(Int(lineNum)! + 1)
                        }
                        lineNum = (line as NSString).substring(with: iMatch.rangeAt(3))
                        count = Int((line as NSString).substring(with: iMatch.rangeAt(4)))!
                        for _ in 1...count {
                            self.posLinesDict[fileNum]?.append(lineNum)
                            lineNum =  String(Int(lineNum)! + 1)
                        }
                        continue
                    //If the line has been removed
                    } else if negLineRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) != nil {
                        self.negTextDict[fileNum]?.append(line)
                        continue
                    //If the line has been added
                    } else if posLineRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) != nil {
                        self.posTextDict[fileNum]?.append(line)
                        continue
                    //Any other lines
                    } else {
                        self.negTextDict[fileNum]?.append(line)
                        self.posTextDict[fileNum]?.append(line)
                        continue
                    }
                }
                
                var negStr = String()
                for n1 in 0...self.negLinesDict.count-1 {
                    for n2 in 0...self.negLinesDict[n1]!.count-1 {
                        negStr += self.negLinesDict[n1]![n2] + "     " + self.negTextDict[n1]![n2] + "\n"
                    }
                }
                var posStr = String()
                for n1 in 0...self.posLinesDict.count-1 {
                    for n2 in 0...self.posLinesDict[n1]!.count-1 {
                        posStr += self.posLinesDict[n1]![n2] + "     " + self.posTextDict[n1]![n2] + "\n"
                    }
                }
                
                print("negStr: \n\(negStr)")
                print("posStr: \n\(posStr)")
                self.refreshTable()
            }
        }
        
        task.resume()
    }
}

