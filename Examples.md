#This page shows how to use the iOS Native Camera Extension


# An example iOS app #

Is available in the source repository: [FlexApp](http://code.google.com/p/diadraw-air-camera-native-extension/source/browse/FlexApp/).

The meat of the code is in [CameraTestAppHomeView.mxml](http://code.google.com/p/diadraw-air-camera-native-extension/source/browse/FlexApp/src/views/CameraTestAppHomeView.mxml), where you can find all of the examples below put together.

# Examples #

## Creating and initializing the Extension ##
```
import com.diadraw.extensions.camera.NativeCameraExtension;

var m_cameraExt : NativeCameraExtension;
m_cameraExt = new NativeCameraExtension();
```


## Starting the video stream ##
Call `startVideoCamera`, specifying which camera you would like to use (front or back), the minimum and maximum frames per second you want it to run with and the resolution of the frames. See [FlexCameraExtensionLib/src/com/diadraw/extensions/camera/ NativeCameraExtension.as](http://code.google.com/p/diadraw-air-camera-native-extension/source/browse/FlexCameraExtensionLib/src/com/diadraw/extensions/camera/NativeCameraExtension.as) for a list of resolution presets.

Whenever a frame is ready to be consumed, the native extension will send a NativeCameraExtensionEvent.IMAGE\_READY signal, so set up a handler for it. The native extension will also tell you the number of the last frame that was consumed, so you can keep track of that and reset its number, when you start the video stream.

```
private var m_lastFrameIdx : Number;
...
var minFramesPerSecond : Number = 15;
var maxFramesPerSecond : Number = 30;

var usingFrontCamera : Boolean = false;

if ( m_cameraExt.startVideoCamera( NativeCameraExtension.Preset640x480, 
                                   minFramesPerSecond, 
                                   maxFramesPerSecond, 
                                   usingFrontCamera ) )
{
     m_lastFrameIdx = int.MIN_VALUE;
     m_cameraExt.addEventListener( NativeCameraExtensionEvent.IMAGE_READY, handleImageReady );
}
```


## Stopping the video stream ##
```
m_cameraExt.stopVideoCamera();
```



## Getting a frame from the video stream ##
When a frame from the video stream is ready to be consumed, the native extension sends a **`NativeCameraExtensionEvent.IMAGE_READY`** event.
Call **`getFrameBuffer`** in the event handler to get the frame pixels. These are stored in a `ByteArray`, which you need to create, but you don't need to set it to a particular size - the native code does that for you.

```
private function handleImageReady( _event : NativeCameraExtensionEvent ) : void
{
    // Create a ByteArray to get the frame data into. You don't need to resize the array:
    m_byteArray = new ByteArray();                   
    var currentFrameIdx : Number = m_cameraExt.getFrameBuffer( m_byteArray, m_lastFrameIdx );

    // Check if we have already got this frame:                                
    if ( currentFrameIdx != m_lastFrameIdx )
    {
        m_lastFrameWidth = _event.frameWidth;
        m_lastFrameHeight = _event.frameHeight;

        // Extract BitmapData from the ByteArray
        var bd : BitmapData = new BitmapData( m_lastFrameWidth, m_lastFrameHeight, true );
        bd.setPixels( renderRect, _byteArray );

        // Perform any pixel processing here

        m_lastFrameIdx = currentFrameIdx;
    }       
}
```


## Setting the Focus ##
Call [setFocusMode](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#setFocusMode), passing one of these options:
  * `FocusModeLocked`: The focal length is fixed.
  * `FocusModeAutoFocus`: The camera does a single scan focus then reverts to locked.
  * `FocusModeContinuousAutoFocus`: The camera continuously auto-focuses as needed.

### Setting a point of focus ###
You can optionally set a point of interest for the camera to focus on:
```
// x and y can come from the point, where the user tapped the screen:
var pointOfInterest : Point = new Point( x, y );
m_cameraExt.setFocusMode( NativeCameraExtension.FocusModeContinuousAutoFocus, pointOfInterest );
```



## Setting the Exposure ##
Call [setExposureMode](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#setExposureMode), passing one of these options:
  * `FocusModeLocked`: The focal length is fixed.
  * `FocusModeAutoFocus`: The camera does a single scan focus then reverts to locked.
  * `FocusModeContinuousAutoFocus`: The camera continuously auto-focuses as needed.

### Setting a point of interest for exposure ###
You can optionally set a point of interest for the camera to focus on:
```
// x and y can come from the point, where the user tapped the screen:
var pointOfInterest : Point = new Point( x, y );
m_cameraExt.setExposureMode( NativeCameraExtension.ExposureModeContinuousAutoExposure, pointOfInterest );
```



## Setting the White Balance ##
Call [setWhiteBalanceMode](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/ExtensionAPI#setWhiteBalanceMode) with one of these options:
  * `WhiteBalanceModeLocked`: The white balance setting is locked.
  * `WhiteBalanceModeAutoWhiteBalance`: The device performs an auto white balance operation now.
  * `WhiteBalanceModeContinuousAutoWhiteBalance`: The device continuously monitors white balance and adjusts when necessary.



## Listening for and processing events from the native side ##

### `NativeCameraExtensionEvent.IMAGE_READY` ###
This event is dispatched, when a frame from the video stream is ready to be consumed. See [Getting a frame from the video stream](http://code.google.com/p/diadraw-air-camera-native-extension/wiki/Examples?ts=1349957707&updated=Examples#Getting_a_frame_from_the_video_stream) for details.

```
 m_cameraExt.addEventListener( NativeCameraExtensionEvent.IMAGE_READY, handleImageReady );
```

### All other events ###
```
import com.diadraw.extensions.camera.NativeCameraExtensionEvent;

m_cameraExt.addEventListener( NativeCameraExtensionEvent.STATUS_EVENT, handleStatusEvent );

private function handleStatusEvent( _event : NativeCameraExtensionEvent ) : void
{
    //Put the code, which handles the event here. Check _event.message and _event.data.
}
```