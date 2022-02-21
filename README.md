# HLSDownloader
An example of using AVAssetDownloadTask in Swift to download HLS content to disk for offline playback in iOS devices.

This sample was primarily created in response to [this StackOverflow question](https://stackoverflow.com/questions/71091781/how-can-i-track-download-progress-after-app-is-did-become-active-from-background) with regards to a bug in `AVAssetDownloadDelegate` in iOS 12 and below.

The issue is that the `AVAssetDownloadDelegate` callbacks do not seem to fire after the app returns to the foreground when coming from the background.

The download seems to continue, however the progress does not get updated. The solution that seems to work for now is to:
 1. Subscribe to the `UIApplication.willEnterForegroundNotification` notification
 2. Check if the device is running iOS 12 and below as the app is returns to the foreground
 3. If it does, `cancel` and then `resume` the download task with the url of location on the iOS device where the file was partially downloaded 

This solution seems to reset the delegate and all the `AVAssetDownloadDelegate` callbacks seem to fire again.
