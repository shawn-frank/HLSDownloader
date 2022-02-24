//
//  ViewController.swift
//  HLSDownloader
//
//  Created by Shawn Frank on 20/02/2022.
//

import UIKit
import AVKit

fileprivate enum HLSSampleSize
{
    case small
    case large
}

class ViewController: UIViewController
{
    private let downloadButton = UIButton(type: .system)
    private let progressView = UIProgressView()
    private let progressLabel = UILabel()
    
    private let downloadTaskIdentifier = "com.mindhyve.HLSDOWNLOADER"

    private var backgroundConfiguration: URLSessionConfiguration?
    private var assetDownloadURLSession: AVAssetDownloadURLSession!
    private var downloadTask: AVAssetDownloadTask!
    
    // Your file will be saved at this path
    private var destinationURL: URL?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        configureDownloadButton()
        configureProgressView()
        
        subscribeToNotifications()
        
        initializeDownloadSession()
    }
    
    // MARK: DOWNLOAD TASK
    private func initializeDownloadSession()
    {
        // This will create a new configuration if the identifier does not exist
        // Otherwise, it will reuse the existing identifier which is how a download
        // task resumes
        backgroundConfiguration
            = URLSessionConfiguration.background(withIdentifier: downloadTaskIdentifier)
        
        // Resume will happen automatically when this configuration is made
        assetDownloadURLSession
            = AVAssetDownloadURLSession(configuration: backgroundConfiguration!,
                                        assetDownloadDelegate: self,
                                        delegateQueue: OperationQueue.main)
    }
    
    private func resumeDownloadTask()
    {
        var sourceURL = getHLSSourceURL(.small)
        
        // Now Check if we have any previous download tasks to resume
        if let destinationURL = destinationURL
        {
            sourceURL = destinationURL
        }
        
        if let sourceURL = sourceURL
        {
            let urlAsset = AVURLAsset(url: sourceURL)
            
            downloadTask = assetDownloadURLSession.makeAssetDownloadTask(asset: urlAsset,
                                                                         assetTitle: "Movie",
                                                                         assetArtworkData: nil,
                                                                         options: nil)
            
            downloadTask.resume()
        }
    }

    func cancelDownloadTask()
    {
        downloadTask.cancel()
        downloadButton.setTitle("Resume", for: .normal)
    }
    
    private func getHLSSourceURL(_ size: HLSSampleSize) -> URL?
    {
        if size == .large
        {
            return URL(string: "https://video.film.belet.me/45505/480/ff27c84a-6a13-4429-b830-02385592698b.m3u8")
        }
        
        return URL(string: "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8")
    }
    
    private func playMovie()
    {
        if let destinationURL = destinationURL
        {
            let playerViewController = AVPlayerViewController()
            
            let player = AVPlayer(url: destinationURL)
            
            playerViewController.player = player
            
            present(playerViewController, animated: true)
            {
                player.play()
            }
        }
    }

    // MARK: INTENTS
    @objc
    private func downloadButtonTapped()
    {
        print("\(downloadButton.titleLabel!.text!) tapped")
        
        if downloadTask != nil,
           downloadTask.state == .running
        {
            cancelDownloadTask()
        }
        else
        {
            resumeDownloadTask()
        }
    }
}

// MARK: OBSERVERS
extension ViewController
{
    @objc
    private func didEnterForeground()
    {
        if #available(iOS 13.0, *) { return }
        
        // In iOS 12 and below, there seems to be a bug with AVAssetDownloadDelegate.
        // It will not give you progress when coming from the background so we cancel
        // the task and resume it and you should see the progress in maybe 5-8 seconds
        if let downloadTask = downloadTask
        {
            downloadTask.cancel()
            initializeDownloadSession()
            resumeDownloadTask()
        }
    }

    //
    private func subscribeToNotifications()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
}

// MARK: AVAssetDownloadDelegate
extension ViewController: AVAssetDownloadDelegate
{
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?)
    {
        guard error != nil else
        {
            // Download completes here, do what you want
            playMovie()
            return
        }
        
        // Handle errors
    }

    func urlSession(_ session: URLSession,
                    assetDownloadTask: AVAssetDownloadTask,
                    didFinishDownloadingTo location: URL)
    {
        // Save the download path of the task to resume downloads
        destinationURL = location
    }
    
    func urlSession(_ session: URLSession,
                    assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange)
    {
        downloadButton.setTitle("Pause", for: .normal)
        var percentageComplete = 0.0
        
        // Iterate over loaded time ranges
        for value in loadedTimeRanges {
            // Unpack CMTimeRange value
            let loadedTimeRange = value.timeRangeValue
            percentageComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        progressView.setProgress(Float(percentageComplete), animated: true)
        
        let downloadCompletedString = String(format: "%.3f", percentageComplete * 100)
        
        print("\(downloadCompletedString)% downloaded")
        progressLabel.text = "\(downloadCompletedString)%"
        
    }
}

// MARK: AUTOLAYOUT UI CONFIGURATION
extension ViewController
{
    private func configureDownloadButton()
    {
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.setTitle("Download", for: .normal)
        downloadButton.setTitleColor(.blue, for: .normal)
        downloadButton.addTarget(self,
                                 action: #selector(downloadButtonTapped),
                                 for: .touchUpInside)
        view.addSubview(downloadButton)
        
        downloadButton.leadingAnchor
            .constraint(equalTo: view.leadingAnchor,
                        constant: 20).isActive = true
        
        var bottomAnchor = view.bottomAnchor
        
        if #available(iOS 13.0, *)
        {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        }
        
        downloadButton.bottomAnchor
            .constraint(equalTo: bottomAnchor,
                        constant: -20).isActive = true
        
        downloadButton.trailingAnchor
            .constraint(equalTo: view.trailingAnchor,
                        constant: -20).isActive = true
        
        downloadButton.heightAnchor
            .constraint(equalToConstant: 80).isActive = true
    }
    
    private func configureProgressView()
    {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .lightGray
        progressView.progressTintColor = .systemBlue
        view.addSubview(progressView)
        
        progressView.leadingAnchor
            .constraint(equalTo: view.leadingAnchor,
                        constant: 20).isActive = true
        
        progressView.bottomAnchor
            .constraint(equalTo: downloadButton.topAnchor,
                        constant: -20).isActive = true
        
        let width = 0.75 * UIScreen.main.bounds.width
        
        progressView.widthAnchor
            .constraint(equalToConstant: width).isActive = true
        
        progressView.heightAnchor
            .constraint(equalToConstant: 10).isActive = true
        
        configureProgressLabel()
    }
    
    private func configureProgressLabel()
    {
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.textColor = .black
        progressLabel.textAlignment = .center
        progressLabel.text = "0%"
        view.addSubview(progressLabel)
        
        progressLabel.leadingAnchor
            .constraint(equalTo: progressView.trailingAnchor,
                        constant: 20).isActive = true
        
        progressLabel.bottomAnchor
            .constraint(equalTo: progressView.bottomAnchor).isActive = true
        
        progressLabel.trailingAnchor
            .constraint(equalTo: view.trailingAnchor,
                        constant: -20).isActive = true
        
        progressLabel.heightAnchor
            .constraint(equalToConstant: 30).isActive = true
    }
}

