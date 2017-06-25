 //
//  TableViewController.swift
//  GitDiff
//
//  Created by Jonathan Brower on 6/21/17.
//  Copyright © 2017 Jonathan Brower. All rights reserved.
//

import UIKit

//MARK: - compareTableViewController
class compareTableViewController: UITableViewController{
    
    var titleArray = [String]()
    var descriptionArray = [String]()
    var diffUrlArray = [String]()
    var owner = String()
    var repo = String()
    var compType = Int()
    var lastPage = Int()
    var curPage = Int()
    var head = String()
    var waiting = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        curPage = 1
        if compType == 0 {
            self.navigationItem.title = "Pull Requests"
        } else if compType == 1 {
            self.navigationItem.title = "Commits"
        }
        getLastPage()
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
        if titleArray.count > 0 {
            if (curPage == 1 && lastPage == 1) { //Only 1 page
                return titleArray.count
            } else if (curPage == 1 && curPage < lastPage) { //First page of multiple
                return titleArray.count + 1
            } else if (curPage != 1 && curPage == lastPage) { //Last page of multiple
                return titleArray.count + 1
            } else if (curPage != 1 && curPage < lastPage) { //Middle page of multiple
                return titleArray.count + 2
            }
        }
        return 1
    }

    //Update values in each cell to display pull request information
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cCell", for: indexPath) as! compareTableViewCell

        if titleArray.count == 0 {
            cell.titleLabel.text = ""
            cell.descriptionLabel.text = ""
        } else {
            if (curPage == 1 && lastPage == 1) { //Only 1 page
                cell.titleLabel.text = titleArray[indexPath.item]
                cell.descriptionLabel.text = descriptionArray[indexPath.item]
            } else if (curPage == 1 && curPage < lastPage) { //First page of multiple
                let rows = tableView.numberOfRows(inSection: indexPath.section)
                if indexPath.row == rows - 1 {
                    cell.titleLabel.text = "Next page"
                    cell.descriptionLabel.text = "Go to page \(curPage+1) of \(lastPage)-->"
                } else {
                    cell.titleLabel.text = titleArray[indexPath.item]
                    cell.descriptionLabel.text = descriptionArray[indexPath.item]
                }
            } else if (curPage != 1 && curPage == lastPage) { //Last page of multiple
                if indexPath.row == 0 {
                    cell.titleLabel.text = "Previous page"
                    cell.descriptionLabel.text = "<-- Go to page \(curPage-1) of \(lastPage)"
                } else {
                    cell.titleLabel.text = titleArray[indexPath.item-1]
                    cell.descriptionLabel.text = descriptionArray[indexPath.item-1]
                }
            } else if (curPage != 1 && curPage < lastPage) { //Middle page of multiple
                let rows = tableView.numberOfRows(inSection: indexPath.section)
                if indexPath.row == 0 {
                    cell.titleLabel.text = "Previous page"
                    cell.descriptionLabel.text = "<-- Go to page \(curPage-1) of \(lastPage)"
                } else if indexPath.row == rows - 1 {
                    cell.titleLabel.text = "Next page"
                    cell.descriptionLabel.text = "Go to page \(curPage+1) of \(lastPage) -->"
                } else {
                    cell.titleLabel.text = titleArray[indexPath.item-1]
                    cell.descriptionLabel.text = descriptionArray[indexPath.item-1]
                }
            }
        }

        return cell
    }
    
    //Update values in table to new loaded values
    func refreshTable() {
        DispatchQueue.main.async{
            self.tableView.reloadData()
            self.tableView.contentOffset = CGPoint(x: 0, y: 0 - self.tableView.contentInset.top);
        }
        self.dismissLoading()
    }

    //Handle row selection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! compareTableViewCell
        if cell.titleLabel.text == "Next page" {
            curPage += 1
            getComps(page: curPage)
        } else if cell.titleLabel.text == "Previous page" {
            curPage -= 1
            getComps(page: curPage)
        } else if cell.titleLabel.text == "Not found." {
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            self.performSegue(withIdentifier: "compareToChangedFiles", sender: indexPath)
        }
    }
    
    //Handle segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "compareToChangedFiles") {
            let controller = (segue.destination as! changedFilesTableViewController)
            let row = (sender as! NSIndexPath).item
            if compType == 0 {
                controller.diffUrl = diffUrlArray[row]
            } else if compType == 1 || compType == 2 {
                controller.diffUrl = getDiffUrl(base: diffUrlArray[row])
            }
            controller.fileNamesArray = [String]()
            controller.negLinesDict = Dictionary<Int, Array<String>>()
            controller.posLinesDict = Dictionary<Int, Array<String>>()
            controller.negTextDict = Dictionary<Int, Array<String>>()
            controller.posTextDict = Dictionary<Int, Array<String>>()
            controller.negStr = String()
            controller.posStr = String()
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    func getLastPage() {
        var urlStr = ""
        if compType == 0 {
            urlStr = "https://api.github.com/repos/\(owner)/\(repo)/pulls"
        } else if compType == 1 {
            urlStr = "https://api.github.com/repos/\(owner)/\(repo)/commits"
        } else if compType == 2 {
            urlStr = "https://api.github.com/repos/\(owner)/\(repo)/branches"
        }
        let requestURL: NSURL = NSURL(string: urlStr)!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
            let pHttpResponse = response as! HTTPURLResponse
            let pStatusCode = pHttpResponse.statusCode
            
            if pStatusCode == 200 {
                //Get last page so you can loop and get all pages
                if let link = pHttpResponse.allHeaderFields["Link"] {
                    let lastPattern = "\\?page=(.*)>;(.*)\\?page=(.*)>; rel=\"last\""
                    let lastRegex = try! NSRegularExpression(pattern: lastPattern, options: .caseInsensitive)
                    if let last = lastRegex.firstMatch(in: (link as? String)!, range: NSRange(location: 0, length: ((link as? String)?.characters.count)!)) {
                        self.lastPage = Int((link as! NSString).substring(with: last.rangeAt(3)))!
                    } else {
                        self.lastPage = 1
                    }
                } else {
                    self.lastPage = 1
                }
            }
            self.waiting = false
        }
        waiting = true
        task.resume()
        while waiting {
            //Waiting to finish loading
        }
        getComps(page: self.curPage)

    }
    
    //Get pull request information for MagicalRecord
    func getComps(page: Int) {
        showLoading(viewCon: self)
        if compType == 0 { //Pull Requests
            titleArray = [String]()
            descriptionArray = [String]()
            diffUrlArray = [String]()
            let urlStr = "https://api.github.com/repos/\(owner)/\(repo)/pulls?page=\(page)"
            let requestURL: NSURL = NSURL(string: urlStr)!
            let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
            
                if statusCode == 200 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [])
                        if json is [String: Any] {
                            //json is a dictionary
                            print("JSON is an unexpected dictionary")
                        } else if let jsonData = json as? [Any] {
                            //json is an array
                            for index in 0...jsonData.count-1 {
                                let arrayObject = jsonData[index] as! [String: AnyObject]
                                let prTitle = arrayObject["title"] as! String
                                let prNum = arrayObject["number"] as! Int
                                var prDate = arrayObject["created_at"] as! String
                                //Format date
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                                dateFormatter.timeZone = NSTimeZone(name: "UTC")! as TimeZone
                                let date = dateFormatter.date(from: prDate)
                                dateFormatter.dateFormat = "yyyy"
                                dateFormatter.timeZone = NSTimeZone.local
                                let year = Calendar.current.component(.year, from: date!)
                                let curYear = Calendar.current.component(.year, from: Date())
                                if year < curYear {
                                    dateFormatter.dateFormat = "MMM d, yyyy"
                                } else {
                                    dateFormatter.dateFormat = "MMM d"
                                }
                                prDate = dateFormatter.string(from: date!)
                                let prName = arrayObject["user"]?["login"] as! String
                                
                                let titleStr = prTitle
                                let descStr = "#\(prNum) opened on \(prDate) by \(prName)"
                                self.titleArray.append(titleStr)
                                self.descriptionArray.append(descStr)
                                self.diffUrlArray.append(arrayObject["diff_url"] as! String)
                            }
                            self.refreshTable()
                        } else {
                            print("JSON is invalid")
                        }
                    } catch {
                        print("There is an error with the JSON: \(error)")
                    }
                }
            
                if statusCode == 404 {
                    self.titleArray.append("Not found.")
                    self.descriptionArray.append("Please check the owner and repo are correct.")
                    self.refreshTable()
                }
            }
            task.resume()
        }
        
        if compType == 1 { //Commits
            titleArray = [String]()
            descriptionArray = [String]()
            diffUrlArray = [String]()
            let urlStr = "https://api.github.com/repos/\(owner)/\(repo)/commits?page=\(page)"
            let requestURL: NSURL = NSURL(string: urlStr)!
            let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest as URLRequest) {
                (data, response, error) -> Void in
            
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
            
                if statusCode == 200 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [])
                        if json is [String: Any] {
                            //json is a dictionary
                            print("JSON is an unexpected dictionary")
                        } else if let jsonData = json as? [Any] {
                            //json is an array
                            for index in 0...jsonData.count-1 {
                                let arrayObject = jsonData[index] as! [String: AnyObject]
                                if self.curPage == 1 && index == 0 {
                                    self.head = arrayObject["sha"] as! String
                                }
                                let cTitle = arrayObject["commit"]?["message"] as! String
                                let cCommitter = arrayObject["commit"]?["committer"] as AnyObject
                                var cDate = cCommitter["date"] as! String
                                var cName = ""
                                if let _ = arrayObject["author"] as? NSNull {
                                    cName = cCommitter["name"] as! String
                                } else {
                                    cName = arrayObject["author"]?["login"] as! String
                                }
                                let cBase = arrayObject["sha"] as! String
                            
                                //Format date
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                                dateFormatter.timeZone = NSTimeZone(name: "UTC")! as TimeZone
                                let date = dateFormatter.date(from: cDate)
                                dateFormatter.dateFormat = "yyyy"
                                dateFormatter.timeZone = NSTimeZone.local
                                let year = Calendar.current.component(.year, from: date!)
                                let curYear = Calendar.current.component(.year, from: Date())
                                if year < curYear {
                                    dateFormatter.dateFormat = "MMM d, yyyy"
                                } else {
                                    dateFormatter.dateFormat = "MMM d"
                                }
                                cDate = dateFormatter.string(from: date!)
                            
                                let titleStr = cTitle
                                let descStr = "\(cName) committed on \(cDate)"
                                self.titleArray.append(titleStr)
                                self.descriptionArray.append(descStr)
                                self.diffUrlArray.append(cBase)
                            }
                            self.refreshTable()
                        } else {
                            print("JSON is invalid")
                        }
                    } catch {
                        print("There is an error with the JSON: \(error)")
                    }
                }
            
                if statusCode == 404 {
                    self.titleArray.append("Not found.")
                    self.descriptionArray.append("Please check the owner and repo are correct.")
                    self.refreshTable()
                }
            }
            task.resume()
        }
        
        if compType == 2 { //Branches
            titleArray = [String]()
            descriptionArray = [String]()
            diffUrlArray = [String]()
            let urlStr = "https://api.github.com/repos/\(owner)/\(repo)/branches?page=\(page)"
            let requestURL: NSURL = NSURL(string: urlStr)!
            let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest as URLRequest) {
                (data, response, error) -> Void in
                
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                if statusCode == 200 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: [])
                        if json is [String: Any] {
                            //json is a dictionary
                            print("JSON is an unexpected dictionary")
                        } else if let jsonData = json as? [Any] {
                            //json is an array
                            for index in 0...jsonData.count-1 {
                                let arrayObject = jsonData[index] as! [String: AnyObject]
                                let bTitle = arrayObject["name"] as! String
                                if bTitle == "master" {
                                    self.head = arrayObject["commit"]?["sha"] as! String
                                }
                                let bBase = arrayObject["commit"]?["sha"] as! String
                                
                                let titleStr = bTitle
                                let descStr = "sha = \(bBase)"
                                self.titleArray.append(titleStr)
                                self.descriptionArray.append(descStr)
                                self.diffUrlArray.append(bBase)
                            }
                            self.refreshTable()
                        } else {
                            print("JSON is invalid")
                        }
                    } catch {
                        print("There is an error with the JSON: \(error)")
                    }
                }
                
                if statusCode == 404 {
                    self.titleArray.append("Not found.")
                    self.descriptionArray.append("Please check the owner and repo are correct.")
                    self.refreshTable()
                }
            }
            task.resume()
        }

    }
    
    func getDiffUrl(base: String) -> String {
        var wait = Bool()
        var retVal = String()
        let urlStr = "https://api.github.com/repos/\(owner)/\(repo)/compare/\(base)...\(head)"
        let requestURL: NSURL = NSURL(string: urlStr)!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if statusCode == 200 {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    if let jsonData = json as? [String: Any] {
                        //json is a dictionary
                        retVal = jsonData["diff_url"] as! String
                        wait = false
                    } else if json is [Any] {
                        //json is an array
                        print("JSON is an unexpected array")
                    } else {
                        print("JSON is invalid")
                    }
                } catch {
                    print("There is an error with the JSON: \(error)")
                }
            }
            
            if statusCode == 404 {
                self.titleArray.append("Not found.")
                self.descriptionArray.append("Please check the owner and repo are correct.")
                self.refreshTable()
            }
        }
        wait = true
        task.resume()
        while wait {
            //Waiting for retVal to be set
        }
        return retVal
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
    var negStr = String()
    var posStr = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Changed Files"
        showLoading(viewCon: self)
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
            cell.fileLabel.text = ""
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
        self.dismissLoading()
    }
    
    //Handle row selection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "changedFilesToDifferences", sender: indexPath)
    }
    
    //Handle segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "changedFilesToDifferences") {
            let controller = (segue.destination as! differencesViewController)
            let fileNum = (sender as! NSIndexPath).item
            getFileDiffs(fileNum: fileNum)
            controller.negStr = negStr
            controller.posStr = posStr
            controller.navTitle = fileNamesArray[fileNum]
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
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
                
                if diffFile?.characters.count == 0 {
                    self.fileNamesArray.append("All files are identical!")
                }
                    
                //Use regex to seperate each line
                let outerPattern = "^(.*)$"
                let outerRegex = try! NSRegularExpression(pattern: outerPattern, options: [.caseInsensitive, .anchorsMatchLines])
                //Break out each line into a seperate outer match
                let oMatches = outerRegex.matches(in: diffFile!, options: [], range: NSRange(location: 0, length: (diffFile?.characters.count)!))
                var fileNum = -1
                var negFile = ""
                var posFile = ""

                //Check each line for different possible matching indicators
                for oMatch in oMatches {
                    let range = oMatch.rangeAt(1)
                    let line = (diffFile! as NSString).substring(with: range)
                        
                    //Ignore these lines
                    let ignorePattern1 = "^diff --git (.*)$"
                    let ignorePattern2 = "^new file mode (.*)$"
                    let ignorePattern3 = "^deleted file mode (.*)$"
                    let ignorePattern4 = "^index (.*)..(.*)$"
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
                    let changedFilesPattern1 = "^--- (.*)$"
                    let changedFilesPattern2 = "^\\+\\+\\+ (.*)$"
                    let changedFilesRegex1 = try! NSRegularExpression(pattern: changedFilesPattern1, options: .caseInsensitive)
                    let changedFilesRegex2 = try! NSRegularExpression(pattern: changedFilesPattern2, options: .caseInsensitive)
                    //Line numbers that have changed regex
                    let lineNumberPattern = "^@@ -(.*),(.*) \\+(.*),(.*) @@(.*)$"
                    let lineNumberRegex = try! NSRegularExpression(pattern: lineNumberPattern, options: .caseInsensitive)
                    //Removed line regex
                    let negLinePattern = "^-(.*)"
                    let negLineRegex = try! NSRegularExpression(pattern: negLinePattern, options: .caseInsensitive)
                    //Added line regex
                    let posLinePattern = "^\\+(.*)"
                    let posLineRegex = try! NSRegularExpression(pattern: posLinePattern, options: .caseInsensitive)
                    
                    //Get neg file names that have been changed
                    if let iMatch = changedFilesRegex1.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) {
                        negFile = ((line as NSString).substring(with: iMatch.rangeAt(1)))
                        continue
                    //Get pos file names that have been changed and compare to neg file name
                    } else if let iMatch = changedFilesRegex2.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) {
                        posFile = ((line as NSString).substring(with: iMatch.rangeAt(1)))
                        if negFile == "/dev/null" {
                            posFile.remove(at: posFile.startIndex)
                            self.fileNamesArray.append(posFile)
                        } else {
                            negFile.remove(at: negFile.startIndex)
                            self.fileNamesArray.append(negFile)
                        }
                        fileNum += 1
                        self.negLinesDict[fileNum] = []
                        self.posLinesDict[fileNum] = []
                        self.negTextDict[fileNum] = []
                        self.posTextDict[fileNum] = []
                    //Get line numbers for changed text in files
                    } else if let iMatch = lineNumberRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) {
                        var lineNum = (line as NSString).substring(with: iMatch.rangeAt(1))
                        var count = Int((line as NSString).substring(with: iMatch.rangeAt(2)))!
                        if count == 0 {
                            self.negLinesDict[fileNum]?.append("0")
                        } else {
                            for _ in 1...count {
                                self.negLinesDict[fileNum]?.append(lineNum)
                                lineNum =  String(Int(lineNum)! + 1)
                            }
                        }
                        lineNum = (line as NSString).substring(with: iMatch.rangeAt(3))
                        count = Int((line as NSString).substring(with: iMatch.rangeAt(4)))!
                        if count == 0 {
                            self.posLinesDict[fileNum]?.append("0")
                        } else {
                            for _ in 1...count {
                                self.posLinesDict[fileNum]?.append(lineNum)
                                lineNum =  String(Int(lineNum)! + 1)
                            }
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
                self.refreshTable()
            }
        }
        
        task.resume()
    }
    
    func getFileDiffs(fileNum: Int) {
        negStr = ""
        posStr = ""
        for n1 in 0...self.negLinesDict.count-1 {
            if self.negLinesDict[n1]!.count == 0 || self.negLinesDict[n1]?[0] == "0" {
                if n1 == fileNum {
                        self.negStr += "0     This file was added to the pull request.\n"
                }
            } else {
                for n2 in 0...self.negLinesDict[n1]!.count-1 {
                    if n1 == fileNum {
                        
                        self.negStr += self.negLinesDict[n1]![n2] + "     " + self.negTextDict[n1]![n2]
                        if n2 < self.negLinesDict[n1]!.count-1 {
                            self.negStr += "\n"
                            if (Int(self.negLinesDict[n1]![n2+1])! - Int(self.negLinesDict[n1]![n2])!) > 1 {
                                self.negStr += "...\n"
                            }
                        }
                    }
                }
            }
        }
        for n1 in 0...self.posLinesDict.count-1 {
            if self.posLinesDict[n1]!.count == 0 || self.posLinesDict[n1]?[0] == "0" {
                if n1 == fileNum {
                    self.posStr += "0     This file was removed from the pull request\n"
                }
            } else {
                for n2 in 0...self.posLinesDict[n1]!.count-1 {
                    if n1 == fileNum {
                        self.posStr += self.posLinesDict[n1]![n2] + "     " + self.posTextDict[n1]![n2]
                        if n2 < self.posLinesDict[n1]!.count-1 {
                            self.posStr += "\n"
                            if (Int(self.posLinesDict[n1]![n2+1])! - Int(self.posLinesDict[n1]![n2])!) > 1 {
                                self.posStr += "...\n"
                            }
                        }
                    }
                }
            }
        }
    }
}

