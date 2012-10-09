/** 
 * Native camera extension library 
 * @author Radoslava Leseva, diadraw.com
 */ 

package com.diadraw.extensions.camera
{
	import flash.display.BitmapData;
	import flash.events.DataEvent;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	
	public class NativeCameraExtension extends EventDispatcher
	{
		public static const FocusModeLocked              : Number = 0; // The focal length is fixed.
		public static const FocusModeAutoFocus           : Number = 1; // The camera does a single scan focus then reverts to locked.
		public static const FocusModeContinuousAutoFocus : Number = 2; // The camera continuously auto-focuses as needed.
			
		public static const ExposureModeLocked              	: Number = 0; // The exposure mode is fixed.
		public static const ExposureModeAutoExpose           	: Number = 1; // The device performs an auto-expose operation and reverts to locked.
		public static const ExposureModeContinuousAutoExposure 	: Number = 2; // The device continuously monitors exposure levels and auto exposes when neccessary.
		
		public static const WhiteBalanceModeLocked            			: Number = 0; // The white balance setting is locked.
		public static const WhiteBalanceModeAutoWhiteBalance   			: Number = 1; // The device performs an auto white balance operation now.
		public static const WhiteBalanceModeContinuousAutoWhiteBalance 	: Number = 2; // The device continuously monitors white balance and adjusts when necessary.
		
		
		public static const PresetPhoto 			: String = "AVCaptureSessionPresetPhoto";
		public static const PresetHigh 				: String = "AVCaptureSessionPresetHigh";
		public static const PresetMedium 			: String = "AVCaptureSessionPresetMedium";
		public static const PresetLow 				: String = "AVCaptureSessionPresetLow";
		public static const Preset352x288 			: String = "AVCaptureSessionPreset352x288";
		public static const Preset640x480 			: String = "AVCaptureSessionPreset640x480";
		public static const PresetiFrame960x540 	: String = "AVCaptureSessionPresetiFrame960x540";
		public static const Preset1280x720 			: String = "AVCaptureSessionPreset1280x720";
		public static const PresetiFrame1280x720 	: String = "AVCaptureSessionPresetiFrame1280x720";
		
		
		public function NativeCameraExtension( _target : IEventDispatcher = null )
		{
			super( _target );
		}
		
		
		public function dispose() : void 
		{
			ensureContext();
			
			m_extContext.removeEventListener( StatusEvent.STATUS, onStatusEvent );
			m_extContext.dispose();
		}	
		
		
		/** 
		 * Starts the video stream. 
		 * NativeCameraExtensionEvent.IMAGE_READY is dispatched, when a frame is ready to be read.
		 * 
		 * @param _preset Use one of the NativeCameraExtension.Preset* constants
		 * @param _minFPS Minimum frames per second
		 * @param _maxFPS Maximum frames per second
		 * @param _useFrontCamera Optional. If set to true, the front camera of the device is used, where supported. 
		 * 						  Otherwise the back camera is used.
		 * 
		 * @return true if the camera was started, false otherwise. If the camera didn't start, 
		 * 		   the native code sends a StatusEvent with a message, describing what the problem was: unsupported preset, 
		 * 		   front camera not supported, etc.	   	
		 * 
		 * @see getFrameBuffer for how to get the video frame data 
		 * @see onStatusEvent for StatusEvent handling
		 */ 
		public function startVideoCamera( 
			_preset : String, 
			_minFPS : Number,
			_maxFPS : Number, 
			_useFrontCamera : Boolean = false ) : Boolean
		{
			ensureContext();
			return m_extContext.call( "as_startVideoCamera", _preset, _minFPS, _maxFPS, _useFrontCamera ) as Boolean;		
		}
		
		
		/** 
		 * Stops the video stream. 
		 */
		public function stopVideoCamera() : void
		{
			ensureContext();
			m_extContext.call( "as_stopVideoCamera");		
		}
		
		
		/** 
		 * Requests a single frame from the video stream.
		 * 
		 * @param _bufferData ByteArray into which the frame pixels will be copied. 
		 * 		  NOTE: _bufferData must not be null. Its size however is set by the native code.
		 * @param _lastFrameIndex The index of the last frame we requested.
		 * 
		 * @return The index of the frame that was copied into _bufferData.
		 * 		   If it is the same as _lastFrameIndex, then we have already got the newest frame and no copying was done.	   	
		 */ 
		public function getFrameBuffer( _bufferData : ByteArray, _lastFrameIndex : Number ) : Number
		{
			ensureContext();
			return m_extContext.call( "as_getFrameBuffer", _bufferData, _lastFrameIndex ) as int;
		}
		
		
		/** 
		 * Sets the exposure mode.
		 * 
		 * @param _mode: Use one of the NativeCameraExtension.ExposureMode* constants 
		 * @param _pointOfInterest: Optional point of interest, which is supported on some devices.
		 * 							(0, 0) corresponds to the top left and (1, 1) - to the bottom right
		 * 							of the picture area with the home button on the right - 
		 * 							applies even if the device is in portrait mode
		 */ 
		public function setExposureMode( _mode : Number, _pointOfInterest : Point = null ) : void
		{
			ensureContext();
			
			if ( null != _pointOfInterest )
			{
				m_extContext.call( "as_setExposureMode", _mode, _pointOfInterest.x, _pointOfInterest.y );	
			}
			else
			{	
				m_extContext.call( "as_setExposureMode", _mode );
			}	
		}
		
		
		public function setFocusMode( _mode : Number, _pointOfInterest : Point = null ) : void
		{
			ensureContext();
			m_extContext.call( "as_setFocusMode", _mode );	
			
			if ( null != _pointOfInterest )
			{
				m_extContext.call( "as_setFocusMode", _mode, _pointOfInterest.x, _pointOfInterest.y );	
			}
			else
			{	
				m_extContext.call( "as_setFocusMode", _mode );
			}
		}
		
		
		public function setWhiteBalanceMode( _mode : Number ) : void
		{
			ensureContext();
			m_extContext.call( "as_setWhiteBalance", _mode );	
		}
		
		
		public function setRotationAngle( _angleDegrees : Number ) : void
		{
			ensureContext();
			
			m_extContext.call( "as_setRotationAngle", _angleDegrees );
		}
		
		
		public function setTranslationPoint( _offsetX : Number, _offsetY : Number ) : void
		{
			ensureContext();
			
			m_extContext.call( "as_setTranslationPoint", _offsetX, _offsetY );
		}
		
		
		public function setCropRectanglePixels( _x : Number, _y : Number, _w : Number, _h : Number ) : void
		{
			ensureContext();
			
			m_extContext.call( "as_setCropRectanglePixels", _x, _y, _w, _h );
		}
		
		
		private function ensureContext() : void	
		{
			if ( null == m_extContext )
			{
				m_extContext = ExtensionContext.createExtensionContext( EXTENSION_ID, null);
				
				try
				{
					m_extContext = ExtensionContext.createExtensionContext( EXTENSION_ID, null );
				}
				catch ( error : ArgumentError )
				{
					dispatchEvent( new NativeCameraExtensionEvent( NativeCameraExtensionEvent.STATUS_EVENT, "Error: " + error.toString() ) );
				}
			}
			
			m_extContext.removeEventListener( StatusEvent.STATUS, onStatusEvent );
			m_extContext.addEventListener( StatusEvent.STATUS, onStatusEvent );
		}
		
			
		private function onStatusEvent( _event : StatusEvent ) : void
		{
			switch ( _event.code )
			{
				case ( NativeCameraExtensionEvent.IMAGE_READY ):
					{
						var imgReadyEvent : NativeCameraExtensionEvent = new NativeCameraExtensionEvent( NativeCameraExtensionEvent.IMAGE_READY );
						
						var imgSize : String = _event.level;
						var separatorIdx : Number = imgSize.indexOf( "," );
						
						var sizeVals : Array = imgSize.split( "," );
						
						if ( 2 == sizeVals.length )
						{
							imgReadyEvent.frameWidth  = Number( sizeVals[ 0 ] );
							imgReadyEvent.frameHeight = Number( sizeVals[ 1 ] );
						}
						
						dispatchEvent( imgReadyEvent );
					}
					break;
				
				default:
					{
						dispatchEvent( new NativeCameraExtensionEvent( NativeCameraExtensionEvent.STATUS_EVENT, _event.level ) );
					}
					break;
			}
		}

		
		protected var m_extContext:ExtensionContext;
		
		private static const EXTENSION_ID : String = "com.diadraw.extensions.camera.NativeCameraExtension";
	}
}