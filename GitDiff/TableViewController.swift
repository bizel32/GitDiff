//
//  TableViewController.swift
//  GitDiff
//
//  Created by Jonathan Brower on 6/21/17.
//  Copyright © 2017 Jonathan Brower. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    var prTitleArray = [String]()
    var prDescriptionArray = [String]()
    var prNumberArray = [NSNumber]()

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

    // MARK: - Table view data source
    //Return number of sections to be shown in tableview
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    //Return number of rows to be shown in tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let num = prTitleArray.count
        return num
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prCell", for: indexPath) as! TableViewCell

        cell.titleLabel.text = prTitleArray[indexPath.item]
        cell.numberLabel.text = "#" + prNumberArray[indexPath.item].stringValue
        cell.descriptionLabel.text = prDescriptionArray[indexPath.item]

        return cell
    }
    
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
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    if json is [String: Any] {
                        //json is a dictionary
                        print("JSON is an unexpected dictionary")
                    } else if let jsonData = json as? [Any] {
                        //json is an array
                        print(jsonData.count)
                        for index in 0...jsonData.count-1 {
                            let arrayObject = jsonData[index] as! [String: AnyObject]
                            self.prTitleArray.append(arrayObject["title"] as! String)
                            self.prDescriptionArray.append(arrayObject["body"] as! String)
                            self.prNumberArray.append(arrayObject["number"] as! NSNumber)
                        }
                        self.tableView.reloadData()
                        //print(jsonData)
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
