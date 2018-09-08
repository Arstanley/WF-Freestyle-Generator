//
//  recordView!.swift
//  WF
//
//  Created by Bo Ni on 6/19/18.
//  Copyright © 2018 Bo Ni. All rights reserved.
//

import UIKit
import AVFoundation

class recordView_: UIView, AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil{
            print(error?.localizedDescription ?? "Some error has occured during recording")
        }else{
            _ = outputURL as URL
            
        }
        outputURL = nil
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    }
    
    

    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var audioOutPut = AVCaptureAudioDataOutput()
    var movieOutPut = AVCaptureMovieFileOutput()
    
    var captureDeviceMic: AVCaptureDevice!
    var captureDeviceCamera: AVCaptureDevice!
    var outputURL: URL!
    
    func prepareCamera(){
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        let availableDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front).devices
        captureDeviceMic = AVCaptureDevice.default(for: AVMediaType.audio)
        captureDeviceCamera = availableDevice.first
        setUpSession()
    }
    
    func setUpSession(){
        do{
            let captureCameraDeviceInput = try AVCaptureDeviceInput(device: captureDeviceCamera)
            captureSession.addInput(captureCameraDeviceInput)
        } catch{
            print(error.localizedDescription)
        }
        
        do{
            let captureMicInput = try AVCaptureDeviceInput(device: captureDeviceMic)
            captureSession.addInput(captureMicInput)
        }catch{
            print(error.localizedDescription)
        }
        
        setUpPreviewLayer()
        captureSession.startRunning()
    
        if captureSession.canAddOutput(audioOutPut){
            print("added audioOutPut")
            captureSession.addOutput(audioOutPut)
        }
        
        if captureSession.canAddOutput(movieOutPut){
            print("added movieOutPut")
            captureSession.addOutput(movieOutPut)
        }
        
        captureSession.commitConfiguration()
    }
    
    func setUpPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.layer.addSublayer(previewLayer)
        self.previewLayer.frame = self.layer.bounds
    }
    
    func startSession(){
        if !captureSession.isRunning{
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession(){
        if captureSession.isRunning{
            videoQueue().async{
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue{
        return DispatchQueue.main
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation{
        var orientation: AVCaptureVideoOrientation!
        
        switch UIDevice.current.orientation{
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeRight
        case .landscapeLeft:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.portrait
        }
        return orientation
    }
    
    @objc func startCapture(){
        startRecording()
    }
    
    func tempURL() -> URL?{
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != ""{
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func startRecording(){
        if movieOutPut.isRecording == false{
            
            let connection = movieOutPut.connection(with: AVMediaType.video)
            if (connection?.isVideoOrientationSupported) == true {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported) == true{
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            if captureDeviceCamera?.isSmoothAutoFocusSupported == true{
                do{
                    try captureDeviceCamera.lockForConfiguration()
                    captureDeviceCamera.isSmoothAutoFocusEnabled = false
                    captureDeviceCamera.unlockForConfiguration()
                }catch{
                    print("error setting configuration: \(error)")
                }
            }
            outputURL = tempURL()
            print(outputURL)
            movieOutPut.startRecording(to: outputURL, recordingDelegate: self)
        }else{
            stopRecording()
        }
    }
    
    func stopRecording(){
        if movieOutPut.isRecording == true{
            movieOutPut.stopRecording()
        }
    }
    }

    


