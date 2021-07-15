# iOS-Phantom4Missions

## Introduction

From this demo, you will learn how to use the TapFly and ActiveTrack Missions of DJI iOS SDK to create a cool application for Mavic Pro. You will get familiar with DJIMissionManager and use the Simulator of DJI Assistant 2 for testing, which is convenient for you to test the missions indoor.

## Requirements

 - iOS 9.0+
 - Xcode 8.0+
 - DJI iOS SDK 4.15
 - DJIWidget 1.6.4

## Supported DJI Products

- Mavic Pro
- Phantom 4
- Phantom 4 Pro
- Phantom 4 Advanced
- Inspire 2
- M200

## SDK Installation with CocoaPods

Since this project has been integrated with [DJI iOS SDK CocoaPods](https://cocoapods.org/pods/DJI-SDK-iOS) now, please check the following steps to install **DJISDK.framework** using CocoaPods after you downloading this project:

**1.** Install CocoaPods

Open Terminal and change to the download project's directory, enter the following command to install it:

~~~
sudo gem install cocoapods
~~~

The process may take a long time, please wait. For further installation instructions, please check [this guide](https://guides.cocoapods.org/using/getting-started.html#getting-started).

**2.** Install SDK and DJIWidget with CocoaPods in the Project

Run the following command in the **ObjcSampleCode** and **SwiftSampleCode** paths:

~~~
pod install
~~~

If you install it successfully, you should get the messages similar to the following:

~~~
Analyzing dependencies
Downloading dependencies
Installing DJI-SDK-iOS (4.15)
Installing DJIWidget (1.6.2)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `P4Missions.xcworkspace` for this project from now on.
Pod installation complete! There is 1 dependency from the Podfile and 1 total pod
installed.
~~~

> **Note**: If you saw "Unable to satisfy the following requirements" issue during pod install, please run the following commands to update your pod repo and install the pod again:
>
> ~~~
> pod repo update
> pod install
> ~~~

## Tutorial

For this demo's tutorial: **Creating a TapFly and ActiveTrack Missions Application**, please refer to <https://developer.dji.com/mobile-sdk/documentation/ios-tutorials/P4MissionsDemo.html>.

## Feedback

We’d love to hear your feedback on this demo and tutorial.

Please use **DJI Developer Forum** [dji-forum](https://forum.dji.com/forum-139-1.html?from=developer) or **email** [dev@dji.com](dev@dji.com) when you meet any problems of using this demo. At a minimum please let us know:

* Which DJI Product you are using?
* Which iOS Device and iOS version you are using?
* A short description of your problem includes debugging logs or screenshots.
* Any bugs or typos you come across.

## License

iOS-Phantom4Missions is available under the MIT license. Please see the LICENSE file for more info.

## Join Us

DJI is looking for all kinds of Software Engineers to continue building the Future of Possible. Available positions in Shenzhen, China and around the world. If you are interested, please send your resume to <software-sz@dji.com>. For more details, and list of all our global offices, please check <https://we.dji.com/jobs_en.html>.

DJI 招软件工程师啦，based在深圳，如果你想和我们一起把DJI产品做得更好，请发送简历到 <software-sz@dji.com>.  详情请浏览 <https://we.dji.com/zh-CN/recruitment>.
