# opus-swift
A swift wrapper to use the [Opus Interactive Audio Codec](https://opus-codec.org/) libopus API. 

Intension of this project is to support [audio player SDK](https://github.com/ybrid/player-sdk-swift) with a platform independend XCFramework that can be integrated in swift projects via CocoaPod.

It supports iOS devices and simulators (version 9 to 14) and macOS (versions 10.10 to 11.5)

# Versions
We support version 1.3.1 of [libopus API](https://opus-codec.org/docs/opus_api-1.3.1).

# Integration 
After integration use 
```swift 
import YbridOpus
``` 
in your Swift code.

## If you use CocoaPods
This fork is distributed straight from its GitHub releases (the `YbridOpus` name on the public
CocoaPods trunk belongs to the upstream project), so reference the podspec by URL:
```ruby
platform :ios, '12.0'
target 'player-sdk-swift' do
  use_frameworks!
  pod 'YbridOpus', :podspec => 'https://github.com/vizoss/opus-swift/releases/download/0.8.0/YbridOpus.podspec'
end
```
Replace `0.8.0` with the release version you want.
## If you use Swift Package Management
The Package.swift using this framework should look like
```swift 
  ...
  dependencies: [
    .package(
      url: "https://github.com/vizoss/opus-swift.git", 
      from: "0.8.0"),
  ...
```
## If you don't use CocoaPods or Swift Package Managenment
If you manage packages in another way you may download YbridOpus.xcframework.zip from [the latest release of this repository](https://github.com/vizoss/opus-swift/releases) and embed it into your own project manually. 

Unzip the file into a directory called 'Frameworks' of your XCode project. In the properties editor, drag and drop the directory into the section 'Frameworks, Libraries and Embedded Content' of the target's 'General' tab.

# Contributing
You are welcome to [contribute](https://github.com/vizoss/opus-swift/blob/master/CONTRIBUTING.md).

# Licenses
This project is under MIT license. We create the opus binaries for iOS and macOS from [opus sources of version 1.3.1](https://opus-codec.org/release/stable/2019/04/12/libopus-1_3_1.html). Opus is freely licensed under BSD, see the [LICENSE](https://github.com/vizoss/opus-swift/blob/master/LICENSE) file.