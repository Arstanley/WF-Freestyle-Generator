//
//  ViewController.swift
//  WF
//
//  Created by Bo Ni on 6/19/18.
//  Copyright © 2018 Bo Ni. All rights reserved.
//

import UIKit
import AVFoundation
import ReplayKit
import AVKit
import AssetsLibrary

class mainViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, RPPreviewViewControllerDelegate, UITableViewDelegate, AVAudioPlayerDelegate, UITableViewDataSource{
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            addingSubtitlesToVideo(withSubtitles: wordList!, videoUrl: outputFileURL, completion: {(err, url) in })
            
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    }
    

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var timeIntervalSlider: UISlider!
    @IBOutlet weak var RecordingWindowView: UIView!
    @IBOutlet weak var WordLabel: UILabel!
    @IBOutlet weak var secondsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewButton: UIButton!
    @IBOutlet weak var progressTimeLabel: UILabel!
    
    var wordsGenerator = WordsGenerator()
    
    var musicTimer: Timer?
    // Mark: Setting Up RecordingWindowView
    var operating: Bool = false
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var audioOutPut = AVCaptureAudioDataOutput()
    var movieOutPut = AVCaptureMovieFileOutput()
    
    var captureDeviceMic: AVCaptureDevice!
    var captureDeviceCamera: AVCaptureDevice!
    var videoFileURL: URL!
    var audioPlayer: AVAudioPlayer?
    
    var audioRecorder: AVAudioRecorder!
    
    let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
                          
                          AVEncoderBitRateKey: 16,
                          
                          AVNumberOfChannelsKey : 2,
                          
                          AVSampleRateKey: 44100.0] as [String : Any]
    
    let songs: [String] = ["After Master", "Losing you", "Sample Minded", "J.Cole Type Beat", "Crazy Talk"]
    
    let producer: [String] = ["August Wu/Zoro","D.C.C","Harcormatic90s","REVIVAL MUSIC","格林叶"]
    
    let identifier = "cell"
    
    var soundFileURL: URL?
    
    var videoWithAudioURL: URL?
    
    var isAudioPlayerPlaying = false
    
    var istableViewOnScreen = false
    
    var isVideoRecordingOn = true
    
    var isFirstTouch = true
    
    var beatsFileURL: URL?

    var finalAudioURL: URL?
    
    var wordList: [String]?
    
    var music: URL?
    
    var curTheme = "Random"
    
    var curPlayingCell: UITableViewCell?
    
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = RecordingWindowView.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        RecordingWindowView.layer.addSublayer(previewLayer)
    }

    func setUpSession() -> Bool {
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        // Set up Camera
        let availableDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front).devices
        captureDeviceCamera = availableDevice.first
        do {
            let input = try AVCaptureDeviceInput(device: captureDeviceCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        // Set up Mic
        let availableMic = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInMicrophone], mediaType: AVMediaType.audio, position: .unspecified).devices
        captureDeviceMic = availableMic.first
        do {
            let micInput = try AVCaptureDeviceInput(device: captureDeviceMic)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        
        if captureSession.canAddOutput(movieOutPut){
            captureSession.addOutput(movieOutPut)
        }
        return true
    }
    
    //MARK:- Camera Session
    func startSession() {
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue{
        return DispatchQueue.main
    }

    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
    @objc func startCapture() {
        startRecording()
        }
    
    func tempURL() -> URL? {
        
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mov")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var blurViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    
    @objc func startRecording() {
        
        if movieOutPut.isRecording == false {
            
//            let connection = movieOutPut.connection(with: AVMediaType.video)
//            connection?.automaticallyAdjustsVideoMirroring = true
//
//            if (connection?.isVideoOrientationSupported)! {
//                connection?.videoOrientation = currentVideoOrientation()
//            }
//
//            if (connection?.isVideoStabilizationSupported)! {
//                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
//            }
//
//            if (captureDeviceCamera?.isSmoothAutoFocusSupported)! {
//                do {
//                    try captureDeviceCamera.lockForConfiguration()
//                    captureDeviceCamera.isSmoothAutoFocusEnabled = false
//                    captureDeviceCamera.unlockForConfiguration()
//                } catch {
//                    print("Error setting configuration: \(error)")
//                }
//
//            }
            videoFileURL = tempURL()
            movieOutPut.startRecording(to: videoFileURL, recordingDelegate: self)
            
        }
        else {
            movieOutPut.stopRecording()
        }
        
    }
    
    @objc func stopRecording() {
        
        if movieOutPut.isRecording == true {
            movieOutPut.stopRecording()
        }
    }
    // Camera Session Configuration stops here
    
    //Mark: Words Generator Stuff

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showVideo"{
        let vc = segue.destination as! VideoPlayback
            vc.videoURL = sender as! URL}
    }

    var timeInterval: Double? {
        didSet{
            secondsLabel.text = String(Int(timeInterval!)) + "s"
        }
    }
    var timer: Timer?
    
    var curWord: String?{
        didSet{
            if !isFirstTouch{
                wordList?.append(curWord!)
            }else{
                wordList = []
            }
            WordLabel.text = curWord
        }
    }
    
    func sliderConfiguration(){
        timeIntervalSlider.isContinuous = false
        timeInterval = Double(round(timeIntervalSlider.value))
    }
    
    @IBAction func touchSlider(_ sender: UISlider) {
        if timer != nil{
            timer!.invalidate()
        }
        timeInterval = Double(round(sender.value))
        displayWord()
    }

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
        if setUpSession() {
            setupPreview()
            startSession()
        }
    }
    
    //Mark: Set up the TableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        
        cell.textLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 20.0)
        cell.textLabel?.text = songs[indexPath.row]
        
        cell.detailTextLabel?.text = producer[indexPath.row]
        cell.detailTextLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 14.0)
        
        cell.imageView?.image = imageWithImage(image: UIImage(named: "Play Button")!, scaledToSize: CGSize(width: 40, height: 40))
        
        return cell
        }
    
    func tableView(_ tableView: UITableView,willDisplay cell: UITableViewCell,forRowAt indexPath: IndexPath){
        tableView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = self.tableView.cellForRow(at: indexPath)
        if music == nil || music != NSURL.fileURL(withPath: Bundle.main.path(forResource: songs[indexPath.row], ofType: "mp3")!){
        music = NSURL.fileURL(withPath: Bundle.main.path(forResource: songs[indexPath.row], ofType: "mp3")!)
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: music!)
        } catch{
            print(error.localizedDescription)
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()}
        if isAudioPlayerPlaying == true && cell == curPlayingCell{
            pauseAudio()
            isAudioPlayerPlaying = false
            curPlayingCell?.imageView?.image = imageWithImage(image: UIImage(named: "Play Button")!, scaledToSize: CGSize(width: 45, height: 45))
        }else{
            playAudio()
            isAudioPlayerPlaying = true
            cell?.imageView?.image = imageWithImage(image: UIImage(named: "Stop Button")!, scaledToSize: CGSize(width: 45, height: 45))
            curPlayingCell?.imageView?.image = imageWithImage(image: UIImage(named: "Play Button")!, scaledToSize: CGSize(width: 45, height: 45))
            curPlayingCell = cell
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
    
    func pauseAudio(){
        if let player = audioPlayer{
            player.pause()
        }
    }
    
    func imageWithImage(image:UIImage,scaledToSize newSize:CGSize)->UIImage{
        
        UIGraphicsBeginImageContext( newSize )
        image.draw(in: CGRect(x: 0,y: 0,width: newSize.width,height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!.withRenderingMode(.alwaysTemplate)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    func animateTableViewToScreen(){
        self.blurView.isHidden = false
        self.blurViewTopConstraint.constant = 0.0
        self.blurView.layoutIfNeeded()
        UIView.animate(withDuration: 0.5) {
            self.blurView.center.x += self.view.bounds.width
        }
    }
    
    func animateTableViewToOffScreen(){
        setNeedsStatusBarAppearanceUpdate()
        UIView.animate(withDuration: 0.5, animations: {self.blurView.center.x -= self.view.bounds.width}, completion: {finished in self.blurViewTopConstraint.constant = self.autoFit(constant: 437)
            
        })
    }
    var audioPlayer2: AVAudioPlayer?
    
    @IBAction func PlaySoundFileURL(_ sender: Any) {
        do {
            try audioPlayer2 = AVAudioPlayer(contentsOf: soundFileURL!)
        } catch{
            print(error.localizedDescription)
        }
        audioPlayer2?.delegate = self
        audioPlayer2?.prepareToPlay()
        audioPlayer2?.play()
    }
    
    @IBAction func touchBeatsButton(_ sender: Any) {
        if istableViewOnScreen == false{
            animateTableViewToScreen()
            self.tableView.isHidden = false
            self.istableViewOnScreen = true
            }else{
            animateTableViewToOffScreen()
            self.tableView.isHidden = true
            self.istableViewOnScreen = false
        }
        }
    
    @objc func turnOffVideoRecording(){
        captureSession.stopRunning()
        let CameraImageView = UIImageView()
        CameraImageView.image = UIImage(named: "Video Recorder")?.withRenderingMode(.alwaysOriginal)
        CameraImageView.frame = CGRect(x: 137.5, y: 161.5, width: 100, height: 100)
        previewLayer.removeFromSuperlayer()
        RecordingWindowView.addSubview(CameraImageView)
        RecordingWindowView.backgroundColor = self.view.backgroundColor
        isVideoRecordingOn = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Video On", style: .plain, target: self, action: #selector(turnOnVideoRecording))
    }
    
    @objc func turnOnVideoRecording(){
        captureSession.startRunning()
        RecordingWindowView.layer.addSublayer(previewLayer)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Video Off", style: .plain, target: self, action: #selector(turnOffVideoRecording))
        isVideoRecordingOn = true
    }
    
    ///////////////////////
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Video Off", style: .plain, target: self, action: #selector(turnOffVideoRecording))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Choose Theme", style: .plain, target: self, action: #selector(selectTheme))
        sliderConfiguration()
        if setUpSession() {
            setupPreview()
            startSession()
        }

        recordButton.setImage(UIImage(named: "record")?.withRenderingMode(.alwaysOriginal), for: UIControlState.normal)
        tableViewButton.setImage(UIImage(named: "Music Sign")?.withRenderingMode(.alwaysOriginal), for: UIControlState.normal)
        recordButton.layer.zPosition = .greatestFiniteMagnitude
        tableViewButton.layer.zPosition = .greatestFiniteMagnitude
        tableViewButton.imageView?.contentMode = .scaleAspectFill
        recordButton.imageView?.contentMode = .scaleAspectFill
        
        
//        let wordLabelRecognizer = UITapGestureRecognizer(target: self, action: #selector(mainViewController.selectTheme))
        let cameraButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(mainViewController.touchCameraButton))
        WordLabel.font = UIFont.systemFont(ofSize: autoFit(constant: 30))
        recordButton.addGestureRecognizer(cameraButtonRecognizer)
        recordButton.isUserInteractionEnabled = true
        self.tableView.register(MusicTableViewCell.self, forCellReuseIdentifier: identifier)
        displayWord()
        prepareRecorder()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    ///Setting the AlertConller for the theme chooser
    @objc func selectTheme(){
        let alert = UIAlertController(title: "Select a theme", message: "You can select a theme for the words generator", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Hiphop", style: .default, handler: {action in self.curTheme = "Hiphop"}))
        alert.addAction(UIAlertAction(title: "Basketball", style: .default, handler: {action in self.curTheme = "Basketball"}))
        alert.addAction(UIAlertAction(title: "Random", style: .default, handler: {action in self.curTheme = "Random"}))
        alert.addAction(UIAlertAction(title: "English", style: .default, handler: {action in self.curTheme = "English"}))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let ppc = alert.popoverPresentationController
        ppc?.barButtonItem = navigationItem.leftBarButtonItem
        
        alert.modalPresentationStyle = .overCurrentContext
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func touchCameraButton(){
        
        if isVideoRecordingOn{
            if isFirstTouch{
                startTimer()
                startCapture()
                recordAudio()
                wordList?.append(curWord!)
                isFirstTouch = false
            }else{
                endTimer()
                startCapture()
                recordAudio()
                stopAudio()
                isFirstTouch = true
//                record({() in self.mergeVideoAndAudio(videoUrl: self.videoFileURL, audioUrl: self.soundFileURL!, shouldFlipHorizontally: true, completion: {(err, url) in
//                    self.videoWithAudioURL = url
//                    if (err != nil){
//                        print(err?.localizedDescription ?? "Error in merging video and audio")
//                    }else{
//                        self.performSegue(withIdentifier: "showVideo", sender: self.videoWithAudioURL)
//                    }
//                    self.isFirstTouch = true
//                    })})
                
        }
        }
    }
    
    var recordedMinutes = 00
    var recordedSeconds = 00
    
    func startTimer(){
        progressTimeLabel.text = "0:0"
        musicTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(mainViewController.update(_:)), userInfo: nil,repeats: true)
        }
    
    @objc func update(_ timer: Timer){
        if recordedSeconds < 59{
            recordedSeconds = recordedSeconds + 1
        } else {
            recordedSeconds = 00
            recordedMinutes = recordedMinutes + 1
        }
        progressTimeLabel.text = "\(recordedMinutes):\(recordedSeconds)"
    }
    
    func endTimer(){
        musicTimer?.invalidate()
        recordedMinutes = 00
        recordedSeconds = 00
        progressTimeLabel.text = " "
    }
    
//    func record(_ callback: @escaping () -> Void){
//        startCapture()
//        recordAudio()
//        callback()
//    }
    
    @IBAction func testing(_ sender: Any) {
        
        self.mergeVideoAndAudio(videoUrl: self.videoFileURL, audioUrl: self.soundFileURL!, shouldFlipHorizontally: true, completion: {(err, url) in             self.videoWithAudioURL = url
            if (err != nil){
                print(err?.localizedDescription ?? "Error in merging video and audio")
            }
            })
    }
    
    func recordAudio(){
        if audioRecorder.isRecording{
            audioRecorder.stop()
        }else{
            audioRecorder.record()
        }
    }
    
    func prepareRecorder(){
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        let docDir = dirPath[0]
        
        let soundFilePath = (docDir as NSString).appendingPathComponent("sound.caf")
        
        soundFileURL = URL(fileURLWithPath: soundFilePath)
        
        var error: NSError?
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            
        } catch let error1 as NSError {
            
            print(error1.localizedDescription)
            
        }

        do {
            
            audioRecorder = try AVAudioRecorder(url: soundFileURL! as URL, settings: recordSettings as [String : AnyObject])
            
        } catch let error1 as NSError {
            
            error = error1
            
            audioRecorder = nil
            
        }
        
        if let err = error{
            
            print("audioSession error: \(err.localizedDescription)")
            
        }else{
            audioRecorder?.prepareToRecord()
        }
    }
    
    @IBOutlet weak var blurViewToBottmConstraint: NSLayoutConstraint!
    
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.isHidden = true
        self.blurViewTopConstraint.constant = RecordingWindowView.frame.size.height
        self.blurView.isHidden = true
        self.blurView.center.x -= view.bounds.width
//        self.tableViewBottomConstraint.constant = autoFit(constant: 232)
//        self.recordButtonToBottomSpacing.constant = autoFit(constant: 204)
//        self.buttonToBottomSpacing.constant = autoFit(constant: 204)
        self.blurViewToBottmConstraint.constant = UIScreen.main.bounds.height - RecordingWindowView.frame.size.height - tableViewButton.frame.size.height
        RecordingWindowView.frame = blurView.frame
        }
    
    func displayWord(){
        setWord()
        timer = Timer.scheduledTimer(timeInterval: timeInterval!, target: self, selector: #selector(mainViewController.setWord), userInfo: nil, repeats: true)
        }

    @objc func setWord(){
        let word = wordsGenerator.getWord(theme: curTheme)
        curWord = word
    }
    
    ///////////////////
    //Useless For Now//
    ///////////////////
    func mergeAudioAndAudio(vocalAudioURL: URL, beatsAudioURL: URL, completion: @escaping (_ error: Error?, _ url: URL?) -> Void){
        let mixComposition = AVMutableComposition()
        let mutableCompositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let aVocalAudioAsset = AVAsset(url: vocalAudioURL)
        let aBeatsAudioAsset = AVAsset(url: beatsAudioURL)
        
        let aVocalAudioAssetTrack: AVAssetTrack = aVocalAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        let aBeatsAudioAssetTrack: AVAssetTrack = aBeatsAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        do{
            try mutableCompositionAudioTrack!.insertTimeRange(CMTimeRangeMake(kCMTimeZero,
            aVocalAudioAssetTrack.timeRange.duration),
                                                                of: aVocalAudioAssetTrack,
            at: kCMTimeZero)
            
            try mutableCompositionAudioTrack!.insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                               aVocalAudioAssetTrack.timeRange.duration),
                                                               of: aBeatsAudioAssetTrack,
                                                               at: kCMTimeZero)
        }catch{
            print(error.localizedDescription)
        }
        
        // Exporting
        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newAudio.caf")
        
        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/newAudio.caf"){
            do {try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/newAudio.caf")} catch {
                print(error)
            }
        }
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp3
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        assetExport.exportAsynchronously{ () -> Void in
            DispatchQueue.main.async {
                switch assetExport.status {
                case AVAssetExportSessionStatus.completed:
                    ////
                    self.performSegue(withIdentifier: "showVideo", sender: savePathUrl)
                    print("success")
                    completion(nil, savePathUrl)
                case AVAssetExportSessionStatus.failed:
                    print("failed \(assetExport.error?.localizedDescription ?? "error nil")")
                    completion(assetExport.error, nil)
                case AVAssetExportSessionStatus.cancelled:
                    print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
                    completion(assetExport.error, nil)
                default:
                    print("complete")
                    completion(assetExport.error, nil)
                }
                
            }
            
            
        }
        
    }
    
    func addAudioTrack(toComposition composition: AVMutableComposition, withVideoAsset videoAsset: AVURLAsset){
        let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
        let audioTracks = videoAsset.tracks(withMediaType: AVMediaType.audio)
        for audioTrack in audioTracks {
            try! compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: kCMTimeZero)
        }
    }
    
    func addingSubtitlesToVideo(withSubtitles subtitles: Array<String>, videoUrl: URL, completion: @escaping(_ error: Error?, _ url: URL?) -> Void){
        
        let composition = AVMutableComposition()
        let vidAsset = AVURLAsset(url: videoUrl)
        
        let vidTrack = vidAsset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = vidTrack[0]
        let vid_duration = videoTrack.timeRange.duration
        let vid_timerange = CMTimeRangeMake(kCMTimeZero, vidAsset.duration)
        
        let compositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        do{try compositionVideoTrack.insertTimeRange(vid_timerange, of: videoTrack, at: kCMTimeZero)}catch{print(error.localizedDescription)}
        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        
        let size = videoTrack.naturalSize
        
//        let titleLayer = CATextLayer()
//        titleLayer.backgroundColor = UIColor.black.cgColor
//        titleLayer.string = "Dummy"
//        titleLayer.font = UIFont(name: "Helvetica", size: 28)
//        titleLayer.fontSize = 28
//        titleLayer.opacity = 0.5
//        titleLayer.alignmentMode = kCAAlignmentCenter
//        titleLayer.frame = CGRect(x: 0, y: 50, width: size.width, height: size.height / 6)
//        titleLayer.add(getSubtitlesAnimation(withFrames: subtitles, duration: vid_duration.seconds), forKey: "string")
        

        
        let videoLayer = CALayer()
        videoLayer.opacity = 1.0
        videoLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videoLayer)
//        parentlayer.addSublayer(titleLayer)
        
        
        for i in 0..<subtitles.count{
            let titleLayer = CATextLayer()
            titleLayer.backgroundColor = UIColor.black.cgColor
            titleLayer.string = subtitles[i]
            titleLayer.font = UIFont(name: "Helvetica", size: 28)
            titleLayer.fontSize = 35
            titleLayer.opacity = 0
            titleLayer.alignmentMode = kCAAlignmentCenter
            titleLayer.frame = CGRect(x: 0, y: 25, width: size.width, height: size.height / 6)
            
            let animatedTitleLayer = CALayer()
            animatedTitleLayer.frame = CGRect(x: 0, y: 25, width: size.width, height: size.height / 6)
            animatedTitleLayer.addSublayer(titleLayer)
            
            let beginTime = AVCoreAnimationBeginTimeAtZero + Double(i)*timeInterval!
            titleLayer.add(fadeInAnimation(atBeginTime: beginTime), forKey: "opacity")
            animatedTitleLayer.add(fadeOutAnimation(atBeginTime: beginTime + timeInterval! - 0.5), forKey: "opacity")
            
            parentlayer.addSublayer(animatedTitleLayer)

        }
        
        let layerComposition = AVMutableVideoComposition()
        layerComposition.frameDuration = CMTimeMake(1, 30)
        layerComposition.renderSize = size
        layerComposition.renderScale = 1.0
        layerComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentlayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: composition.duration)
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(
            assetTrack: compositionVideoTrack)
        let t1 = CGAffineTransform(translationX: compositionVideoTrack.naturalSize.width-40, y: -(compositionVideoTrack.naturalSize.width - compositionVideoTrack.naturalSize.height)/2)
        let t2: CGAffineTransform = t1.rotated(by: .pi/2)
        let finalTransform: CGAffineTransform = t2
        layerinstruction.setTransform(finalTransform, at: kCMTimeZero)
        instruction.layerInstructions = NSArray(object: layerinstruction) as! [AVVideoCompositionLayerInstruction]
        layerComposition.instructions = NSArray(object: instruction) as! [AVVideoCompositionInstructionProtocol]
        
        addAudioTrack(toComposition: composition, withVideoAsset: vidAsset)
        
        let movieDestinationURL: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mov")
        
        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/newVideo.mov"){
            do {try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/newVideo.mov")} catch {
                print(error)
            }
        }
        
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        assetExport?.videoComposition = layerComposition
        assetExport?.outputFileType = AVFileType.mov
        assetExport?.outputURL = movieDestinationURL
        
        assetExport!.exportAsynchronously(completionHandler: {
            switch assetExport!.status{
            case AVAssetExportSessionStatus.completed:
                print("Export Complete")
                OperationQueue.main.addOperation({ () -> Void in
                    self.performSegue(withIdentifier: "showVideo", sender: movieDestinationURL)
                })
            case AVAssetExportSessionStatus.failed:
                print("Export failed due to \(assetExport?.error?.localizedDescription)")
            case AVAssetExportSessionStatus.cancelled:
                print("Export cancelled")
            default:
                print("Done")
                }
        })
        
        
    }
    
    func getSubtitlesAnimation(withFrames frames: [String], duration: CFTimeInterval)->CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath:"string")
        animation.calculationMode = kCAAnimationDiscrete
        animation.duration = duration
        animation.values = frames
        animation.keyTimes = [0,0.5,1]
        animation.repeatCount = Float(frames.count)
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        return animation
    }
    
    func fadeInAnimation(atBeginTime beginTime: CFTimeInterval) -> CABasicAnimation{
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 0.5
        animation.isAdditive = false
        animation.isRemovedOnCompletion = false
        animation.beginTime = beginTime
        animation.duration = 0.3
        animation.autoreverses = false
        animation.fillMode = kCAFillModeBoth
        
        return animation
    }
    
    func fadeOutAnimation(atBeginTime beginTime: CFTimeInterval) -> CABasicAnimation{
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.5
        animation.toValue = 0.0
        animation.isAdditive = false
        animation.isRemovedOnCompletion = false
        animation.beginTime = beginTime
        animation.duration = 0.3
        animation.autoreverses = false
        animation.fillMode = kCAFillModeBoth
        
        return animation
    }
    
    func settingUpSubtitlesTransition(withFrames frames: [String], interval: CFTimeInterval, atLayer layer: CATextLayer){
        
        let transition = CATransition()
        transition.duration = 2
        transition.type = kCATransitionPush
        layer.add(transition, forKey: "transition")
        
        layer.backgroundColor = UIColor.red.cgColor
        layer.string = "Hahaha"
    }
    
    
    
    
    /// Merges video and sound while keeping sound of the video too
    ///
    /// - Parameters:
    ///   - videoUrl: URL to video file
    ///   - audioUrl: URL to audio file
    ///   - shouldFlipHorizontally: pass True if video was recorded using frontal camera otherwise pass False
    ///   - completion: completion of saving: error or url with final video
    /// Not Using it for the time being; Might be useful in the next V2.0.0
    func mergeVideoAndAudio(videoUrl: URL,
                            audioUrl: URL,
                            shouldFlipHorizontally: Bool = false,
                            completion: @escaping (_ error: Error?, _ url: URL?) -> Void) {
        
        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()
        
        //start merge
        
        let aVideoAsset = AVAsset(url: videoUrl)
        let aAudioAsset = AVAsset(url: audioUrl)
        
        let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                 preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                 preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioOfVideoAssetTrack: AVAssetTrack? = aVideoAsset.tracks(withMediaType: AVMediaType.audio).first
        let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        // Default must have tranformation
        compositionAddVideo?.preferredTransform = CGAffineTransform(rotationAngle: CGFloat(1/2*Float.pi))
        
        
        if shouldFlipHorizontally {
            // Flip video horizontally
            var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            frontalTransform = frontalTransform.translatedBy(x: -aVideoAssetTrack.naturalSize.width, y: 0.0)
            frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -aVideoAssetTrack.naturalSize.width)
            compositionAddVideo?.preferredTransform = frontalTransform
        }
        
        mutableCompositionVideoTrack.append(compositionAddVideo!)
        mutableCompositionAudioTrack.append(compositionAddAudio!)
        
        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                                aVideoAssetTrack.timeRange.duration),
                                                                of: aVideoAssetTrack,
                                                                at: kCMTimeZero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                                aVideoAssetTrack.timeRange.duration),
                                                                of: aAudioAssetTrack,
                                                                at: kCMTimeZero)
            
            // adding audio (of the video if exists) asset to the final composition
            if let aAudioOfVideoAssetTrack = aAudioOfVideoAssetTrack {
                try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                                           aVideoAssetTrack.timeRange.duration),
                                                                           of: aAudioOfVideoAssetTrack,
                                                                           at: kCMTimeZero)
            }
        } catch {
            print(error.localizedDescription)
        }
        
        // Exporting
        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        
        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/newVideo.mp4"){
            do {try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/newVideo.mp4")} catch {
                print(error)
            }
        }
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        assetExport.exportAsynchronously{ () -> Void in
                
            switch assetExport.status {
            case AVAssetExportSessionStatus.completed:
                print("success")
                completion(nil, savePathUrl)
            case AVAssetExportSessionStatus.failed:
                print("failed \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            default:
                print("complete")
                completion(assetExport.error, nil)
                }
                
            
            
            
        }
        
    }
    func autoFit(constant: CGFloat) -> CGFloat{
        let width:CGFloat = UIScreen.main.bounds.width
        let widthForPhoneX:CGFloat = 375
        return width/widthForPhoneX * constant
    }
}
    








