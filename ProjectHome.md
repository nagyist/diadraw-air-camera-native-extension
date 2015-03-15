# Want more functionality and Android support? #
Check out our DiaDraw Native Camera Driver: http://easynativeextensions.com/product/diadraw-camera-driver-ios-android


# April 2014 update #
We have turned this project into a tutorial, which shows you how to make an iOS Camera ANE step by step. It comes with source code too. Check it out:
http://easynativeextensions.com/tutorials-category


# iOS Camera ANE for Adobe AIR #

Adobe AIR has its limitations, when it comes to control over an iPhone or iPad camera functions, such as **focus**, **exposure** and **white balance**.
This Native Extension offers an API for accessing these functions and adds options for applying filters for cropping and rotating frames.

# What it does #

The Extension allows you to capture static frames from the iPhone/iPad video camera at a frame rate and resolution, chosen by you.

You can choose whether to lock the focus, exposure or white balance or to have them done automatically by the camera. You can also set a point of interest to expose for or to focus on.

The extension also allows you to rotate, crop or translate frames, as they come in:

<a href='http://www.youtube.com/watch?feature=player_embedded&v=nxqnUvscq9Y' target='_blank'><img src='http://img.youtube.com/vi/nxqnUvscq9Y/0.jpg' width='425' height=344 /></a>



# Examples #
See the [Examples Wiki page](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/Examples).

# Building the extension #
The extension code comes with ANT and bash scripts, which automate the building process. For more information see our blog post [One-step build: AIR mobile project with an iOS native extension](http://blog.diadraw.com/one-step-build-air-mobile-project-with-an-ios-native-extension/).

# Camera Extension API for `ActionScript 3` #
The extension exposes the following API at the moment. Click on a function name to see a detailed explanation or go to [Extension API](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI).
  * [startVideoCamera](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#startVideoCamera)
  * [stopVideoCamera](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#stopVideoCamera)
  * [getFrameBuffer](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#getFrameBuffer)
  * [setExposureMode](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#setExposureMode)
  * [setFocusMode](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#setFocusMode)
  * [setWhiteBalanceMode](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI?ts=1349937653&updated=ExtensionAPI#setWhiteBalanceMode)
  * [setRotationAngle](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#setRotationAngle)
  * [setTranslationPoint](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#setTranslationPoint)
  * [setCropRectanglePixels](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI?ts=1349937653&updated=ExtensionAPI#setCropRectanglePixels)