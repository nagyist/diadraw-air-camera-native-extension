# Native Camera Extension, `ActionScript 3` API #



## startVideoCamera ##
```
public function startVideoCamera( 
			_preset : String, 
			_minFPS : Number,
			_maxFPS : Number, 
			_useFrontCamera : Boolean = false ) : Boolean
```
Starts the video stream. `NativeCameraExtensionEvent.IMAGE_READY` is dispatched, when a frame is ready to be read.

  * `_preset`:  One of the following constants:
    * `PresetPhoto`
    * `PresetHigh`
    * `PresetMedium`
    * `PresetLow`
    * `Preset352x288`
    * `Preset640x480`
    * `PresetiFrame960x540`
    * `Preset1280x720`
    * `PresetiFrame1280x720`

  * `_minFPS`: Minimum frames per second
  * `_maxFPS`: Maximum frames per second
  * `_useFrontCamera`: Optional. If set to true, the front camera of the device is used, where supported. Otherwise the back camera is used.

Returns `true` if the camera was started, `false` otherwise. If the camera didn't start, the native code sends a StatusEvent with a message, describing what the problem was: unsupported preset, front camera not supported, etc.



## stopVideoCamera ##
```
public function stopVideoCamera() : void
```
Stops the video stream.



## getFrameBuffer ##
```
public function getFrameBuffer( _bufferData : ByteArray, _lastFrameIndex : Number ) : Number
```
Requests a single frame from the video stream.

  * `_bufferData`: A `ByteArray` into which the frame pixels will be copied.
**NOTE:** _bufferData must not be null. However, you don't need to set it to a particular size - this is done by the native code.
  * `_lastFrameIndex`: The index of the last frame which was requested._

Returns the index of the frame that was copied into `_bufferData`. If it is the same as `_lastFrameIndex`, then we have already got the newest frame and no copying was done.



## setExposureMode ##
```
public function setExposureMode( _mode : Number, _pointOfInterest : Point = null ) : void
```

  * `_mode`: One of the following constants:
    * `ExposureModeLocked`: The exposure mode is fixed.
    * `ExposureModeAutoExpose`: The device performs an auto-expose operation and reverts to locked.
    * `ExposureModeContinuousAutoExposure`: The device continuously monitors exposure levels and auto exposes when neccessary.

  * `_pointOfInterest`: Optional point of interest, which is supported on some devices. (0, 0) corresponds to the top left and (1, 1) - to the bottom right of the picture area with the home button on the right - applies even if the device is in portrait mode.




## setFocusMode ##
```
public function setFocusMode( _mode : Number, _point : Point = null ) : void
```

Allows you to choose between automatically focusing or locking the focus.

  * `_mode`: One of the following constants:
    * `FocusModeLocked`: The focal length is fixed.
    * `FocusModeAutoFocus`: The camera does a single scan focus then reverts to locked.
    * `FocusModeContinuousAutoFocus`: The camera continuously auto-focuses as needed.

  * `_pointOfInterest`: Optional point of interest, which is supported on some devices. (0, 0) corresponds to the top left and (1, 1) - to the bottom right of the picture area with the home button on the right - applies even if the device is in portrait mode.



## setWhiteBalanceMode ##
```
public function setWhiteBalanceMode( _mode : Number ) : void
```

Allows you to choose how the white balance is set.

  * `_mode`: One of the following constants:
    * `WhiteBalanceModeLocked`: The white balance setting is locked.
    * `WhiteBalanceModeAutoWhiteBalance`: The device performs an auto white balance operation now.
    * `WhiteBalanceModeContinuousAutoWhiteBalance`: The device continuously monitors white balance and adjusts when necessary.



## setRotationAngle ##
```
public function setRotationAngle( _angleDegrees : Number ) : void
```

Allows you to rotate the frame to an arbitrary angle.

  * `_angleDegrees`: The rotation angle in degrees.



## setCropRectanglePixels ##
```
public function setCropRectanglePixels( _x : Number, _y : Number, _w : Number, _h : Number ) : void
```

Allows you to define a rectangle for cropping the frame.

  * `_x`: Crop rectangle left coordinate in pixels.
  * `_y`: Crop rectangle top coordinate in pixels.
  * `_w`: Crop rectangle width in pixels.
  * `_h`: Crop rectangle height in pixels.

