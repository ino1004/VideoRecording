//
//  ViewController.swift
//  VideoRecording
//
//  Created by Stephen Chui on 2018/12/25.
//  Copyright © 2018 Stephen Chui. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let captureSession: AVCaptureSession = {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        return captureSession
    }()
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        return previewLayer
    }()
    
    private var activeInput: AVCaptureDeviceInput?
    private let movieOutput = AVCaptureMovieFileOutput()
    
    // 計時器Label
    private var recordingLabel: RecordingLabel = {
        let label = RecordingLabel(frame: CGRect(x: 0, y: 0, width: 140, height: 20))
        label.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 150)
        return label
    }()
    
    // 錄影Button
    private var takeVideoButton: RecordingButton = {
        let button = RecordingButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        button.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
        button.addTarget(self, action: #selector(takeVideoButtonDidPress(_:)), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
        if setupSession() {
            startSession()
        }
    }
    
    private func setupPreviewLayer() {
        // 加上AVCaptureVideoPreviewLayer
        previewLayer.frame = UIScreen.main.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        view.addSubview(recordingLabel)
        view.addSubview(takeVideoButton)
    }
    
    private func setupSession() -> Bool {
        // 設置session的input & output
        // Camera
        // 這邊設定前/後鏡頭
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return false }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            guard captureSession.canAddInput(input) else { return false }
            captureSession.addInput(input)
            activeInput = input
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        // Microphone
        guard let microphone = AVCaptureDevice.default(for: .audio) else { return false }
        do {
            let input = try AVCaptureDeviceInput(device: microphone)
            guard captureSession.canAddInput(input) else { return false }
            captureSession.addInput(input)
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        // Movie output
        guard captureSession.canAddOutput(movieOutput) else { return false }
        captureSession.addOutput(movieOutput)
        
        return true
    }
    
    
    // MARK: - Start/Stop AVCaptureSession
    
    private func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.main.async {
                self.captureSession.startRunning()
            }
        }
    }
    
    private func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.main.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    
    // MARK: - Start / stop recording
    
    @objc private func startRecording() {
        guard !movieOutput.isRecording else {
            stopRecording()
            return
        }
        
        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoStabilizationSupported {
                // An appropriate stabilization mode will be chosen based on the format and frame rate.
                connection.preferredVideoStabilizationMode = .auto
            }
        }
        
        if let device = activeInput?.device {
            if device.isSmoothAutoFocusSupported {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        if let outputUrl = tempURL() {
            recordingLabel.start()
            movieOutput.startRecording(to: outputUrl, recordingDelegate: self)
            takeVideoButton.recordingState = .start
        }
    }
    
    private func stopRecording() {
        if movieOutput.isRecording {
            recordingLabel.stop()
            movieOutput.stopRecording()
            takeVideoButton.recordingState = .stop
        }
    }
    
    // MARK: - Encode
    // 轉成mp4
    private func encodeVideo(videoUrl: URL, completionHandler: @escaping ((URL?) -> Void)) {
        // 建立Path
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var finalUrl = documentDirectory.appendingPathComponent("output")
        
        // Path重覆的話移除，不能移除則return nil
        if FileManager.default.fileExists(atPath: finalUrl.path) {
            do {
                try FileManager.default.removeItem(atPath: finalUrl.path)
            } catch {
                print("Delete file failed: \(error.localizedDescription)")
                completionHandler(nil)
            }
        }
        
        // 建立Directory
        do {
            try FileManager.default.createDirectory(at: finalUrl, withIntermediateDirectories: true, attributes: nil)
            finalUrl = finalUrl.appendingPathComponent("Test.mp4")
        } catch {
            print("Create directory failed: \(error.localizedDescription)")
            completionHandler(nil)
        }
        
        // 建立AVAssset & 設定AVAssetExportSession
        let asset = AVAsset(url: videoUrl)
        if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) {
            exportSession.outputURL = finalUrl
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
            let range = CMTimeRangeMake(start: start, duration: asset.duration)
            exportSession.timeRange = range
            
            // Export with async
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("Export completed")
                    completionHandler(finalUrl)
                case .cancelled:
                    print("Export cancelled")
                case .failed:
                    print("Export failed, \(exportSession.error?.localizedDescription ?? "")")
                default:
                    break
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    
    // MARK: Action
    
    @objc func takeVideoButtonDidPress(_ sender: UIButton) {
        startRecording()
    }
    
    @objc func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let _ = error {
            print("Error, video failed to save")
        }else{
            print("Successfully, video was saved")
        }
    }
    
    
    // MARK: - Others
    
    private func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(UUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
}


// MARK: - AVCaptureFileOutputRecordingDelegate

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
    }
    
    // Finally output
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        } else {
            encodeVideo(videoUrl: outputFileURL) { url in
                if let url = url {
                    print("Encode completed with URL: \(url)")
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(ViewController.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
                }
            }
        }
    }
}



