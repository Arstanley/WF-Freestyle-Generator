//
//  MusicLibraryTableViewController.swift
//  WF
//
//  Created by Bo Ni on 7/1/18.
//  Copyright © 2018 Bo Ni. All rights reserved.
//

import UIKit
import AVFoundation

class MusicLibraryTableViewController: UITableViewController, AVAudioPlayerDelegate{

    let songs: [String] = ["After Master"]
    
    let producer: [String] = ["August Wu/Zoro"]
    
    let identifier = "musicIdentifier"
    
    var audioPlayer: AVAudioPlayer?
    
    var isAudioPlayerPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt
        indexPath: IndexPath) -> UITableViewCell {
        
        let cell: MusicTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: identifier) as! MusicTableViewCell
        cell.producerLabel?.text = producer[indexPath.row]
        cell.musicNameLabel?.text = songs[indexPath.row]
        cell.playButton?.setImage(UIImage(named:"Play Button")?.withRenderingMode(.alwaysOriginal), for: UIControlState.normal)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath) {
        
        let cell: MusicTableViewCell = self.tableView.cellForRow(at: indexPath) as! MusicTableViewCell
        
        let music = NSURL.fileURL(withPath: Bundle.main.path(forResource: songs[indexPath.row], ofType: "mp3")!)
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: music)
        } catch{
            print(error.localizedDescription)
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        if isAudioPlayerPlaying == true{
            stopAudio()
            isAudioPlayerPlaying = false
            cell.playButton?.setImage(UIImage(named: "Play Button"), for: UIControlState.normal)
        }else{
            playAudio()
            isAudioPlayerPlaying = true
            cell.playButton?.setImage(UIImage(named: "Stop Button"), for: UIControlState.normal)
            }
        
    }

    func playAudio(){
        if let player = audioPlayer{
            player.play()
        }
    }
    
    func stopAudio(){
        if let player = audioPlayer{
            player.stop()
        }
    }


}
