//
//  ViewController.swift
//  taskapp
//
//  Created by Takahiro Suzuki on 2016/12/07.
//  Copyright © 2016年 Takahiro Suzuki. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categorySearchBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
    // 日付の近い順\順でソート : 降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byProperty: "date", ascending: false)
    
    /*
     //データ
     let dataList = ["月刊コロコロコミック（小学館）",
     "コロコロイチバン！（小学館）",
     "最強ジャンプ（集英社）",
     "Vジャンプ（集英社）",
     "週刊少年サンデー（小学館）",
     "週刊少年マガジン（講談社）",
     "週刊少年ジャンプ（集英社）",
     "週刊少年チャンピオン（秋田書店）",
     "月刊少年マガジン（講談社）",
     "月刊少年チャンピオン（秋田書店）",
     "月刊少年ガンガン（スクウェア）",
     "月刊少年エース（KADOKAWA）",
     "月刊少年シリウス（講談社）",
     "週刊ヤングジャンプ（集英社）",
     "ビッグコミックスピリッツ（小学館）",
     "週刊ヤングマガジン（講談社）"]
     */
    
    
    //検索結果配列
    var searchResult = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        categorySearchBar.delegate = self //検索バーのデリゲート方は正解？？？
        //何も入力されていなくてもReturnキーを押せるようにする。
        categorySearchBar.enablesReturnKeyAutomatically = false
        //検索結果配列にデータをコピーする。
        //        searchResult = dataList
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count  // ←追加する
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        
        // Cellに値を設定する.
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        //cell.textLabel?.text = task.category
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date as Date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する  //
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/-------------------")
                    print(request)
                    print("--------------------")
                }
            }
            
        }
    }
    
    //検索ボタン押下時の呼び出しメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        categorySearchBar.endEditing(true)
        
        //検索結果配列を空にする。
        //        searchResult.removeAll()
        
        if(categorySearchBar.text == "") {
            //検索文字列が空の場合はすべてを表示する。
            //            searchResult = dataList
        } else {
            //検索文字列を含むデータを検索結果配列に追加する。
            //            for data in dataList {
            //                if data.containsString(categorySearchBar.text!) {
            //                    searchResult.append(data)
            //                }
            //            }
        }
        //テーブルを再読み込みする。
        //        categorySearchBar.reloadData()
        
        let predicate = NSPredicate(format: "category CONTAINS %@ || title CONTAINS %@", searchBar.text! , searchBar.text!) // 検索アルゴリズムの指定
        taskArray = realm.objects(Task.self).filter(predicate)
        
        tableView.reloadData()
    }
    
    // segue で画面遷移するに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            task.date = NSDate()
            
            if taskArray.count != 0 {
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear (_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    
    
}

