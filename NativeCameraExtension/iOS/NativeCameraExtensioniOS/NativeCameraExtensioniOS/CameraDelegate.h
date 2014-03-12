//
//  CameraDelegate.h
//  NativeCameraExtensioniOS
//
//  Created by Radoslava Leseva on 07/07/2012.
//  Copyright (c) 2012 DiaDraw. All rights reserved.
//


#import <AVFoundation/AVCaptureOutput.h>
#import <AVFoundation/AVCaptureDevice.h>
#import "FlashRuntimeExtensions.h"


typedef void ( *SendMessageCallBackType )( const NSString * const, const NSString * const );


@interface CameraDelegate : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{}


@property CGPoint translationPixels;
@property double  rotationRadians;
@property CGRect  cropRectangle;

@property ( retain ) NSData * readBuffer;
@property ( retain ) NSData * writeBuffer;
@property ( retain ) NSData * reserveBuffer;

@property int32_t frameIndex;

@property size_t frameWidth;
@property size_t frameHeight;


- (BOOL) startVieoCamera: ( NSString * ) preset
                  minFPS: ( uint32_t ) minFPS
                  maxFPS: ( uint32_t ) maxFPS
          useFrontCamera: ( BOOL ) useFrontCamera;

- (void) stopVideoCamera;

- (void) setExposureMode : ( AVCaptureExposureMode ) exposureMode
               exposureX : ( CGFloat ) exposureX
               exposureY : ( CGFloat ) exposureY;

- (void) setFocusMode : ( AVCaptureFocusMode ) focusMode
               focusX : ( CGFloat ) focusX
               focusY : ( CGFloat ) focusY;

- (void) setWhiteBalanceMode : ( AVCaptureWhiteBalanceMode ) whiteBalanceMode;

- (void) setTorchMode : ( AVCaptureTorchMode ) torchMode;

- (BOOL) isTorchAvailable;

- ( BOOL ) copyLastFrame: ( int32_t ) lastFrameCopied
                  buffer: ( FREObject ) objectByteArray
            currentFrame: ( int32_t * ) lastFrameConsumedUpdate;

@end
