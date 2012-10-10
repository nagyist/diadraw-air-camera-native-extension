//
//  CameraDelegate.m
//  NativeCameraExtensioniOS
//
//  Created by Radoslava Leseva on 07/07/2012.
//  Copyright (c) 2012 DiaDraw. All rights reserved.
//


#import <CoreGraphics/CGBitmapContext.h>
#import <CoreImage/CIFilter.h>
#import <CoreImage/CIImage.h>
#import <CoreImage/CIContext.h>
#import <CoreImage/CIVector.h>

#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureSession.h>

#import "CameraDelegate.h"


@implementation CameraDelegate


@synthesize translationPixels;
@synthesize rotationRadians;
@synthesize cropRectangle;
@synthesize readBuffer;
@synthesize writeBuffer;
@synthesize reserveBuffer;
@synthesize frameIndex;
@synthesize synchObject;
@synthesize sendMessage;


CFMutableDictionaryRef pixelBufferAttributes;
CFDictionaryRef emptyIOSurfaceAttributes;
AVCaptureSession * captureSession;
AVCaptureVideoDataOutput * videoDataOutput;
AVCaptureDeviceInput * cameraInput;
AVCaptureDevice * currentDevice;


static const NSString * const MSG_WARNING = @"WARNING";
static const NSString * const MSG_ERROR = @"ERROR";
static const NSString * const MSG_FRAME_READY = @"IMAGE_READY";


- ( id ) init
{
    if ( self = [ super init ] )
    {
        captureSession = [ [ AVCaptureSession alloc ] init ];
        rotationRadians = 0.0;
        
        // Initialise the pixelBufferAttributes dictionary, which is used when capturing frames:
        emptyIOSurfaceAttributes = CFDictionaryCreate( kCFAllocatorDefault, 
                                                       NULL,
                                                       NULL,
                                                       0,
                                                       &kCFTypeDictionaryKeyCallBacks,
                                                       &kCFTypeDictionaryValueCallBacks );
        
        pixelBufferAttributes = CFDictionaryCreateMutable( kCFAllocatorDefault,
                                                           1,
                                                           &kCFTypeDictionaryKeyCallBacks,
                                                           &kCFTypeDictionaryValueCallBacks );
        
        CFDictionarySetValue( pixelBufferAttributes,
                              kCVPixelBufferIOSurfacePropertiesKey,
                              emptyIOSurfaceAttributes );
        
    }
    
    return self;
}


- ( void ) dealloc 
{
	[ captureSession stopRunning];
    
	[ captureSession release ], captureSession = nil;
    [ currentDevice release ], currentDevice = nil;
    
    CFDictionaryRemoveAllValues( pixelBufferAttributes );
    
	[ super dealloc ];
}


- ( BOOL ) startVieoCamera: ( NSString * ) preset
                    minFPS: ( uint32_t ) minFPS
                    maxFPS: ( uint32_t ) maxFPS
            useFrontCamera: ( BOOL ) useFrontCamera 
{
    if ( [ captureSession canSetSessionPreset: preset ] )
    {
        captureSession.sessionPreset = preset;
        
        [ self addVideoDataOutput :minFPS maxFPS:maxFPS ];
        [ self addVideoInput : useFrontCamera ];
        [ captureSession startRunning];
        
        frameIndex = 0;
        
        return YES;
    }
    else 
    {
        sendMessage( MSG_ERROR, @"Preset not supported on device" );
        
        return NO;
    }
}


- (void) stopVideoCamera
{
    @synchronized( synchObject )
    { 
        [ captureSession stopRunning];
        [ captureSession removeOutput: videoDataOutput ];
        [ captureSession removeInput: cameraInput ];
    }
}



- (void) setWhiteBalanceMode : ( AVCaptureWhiteBalanceMode ) whiteBalanceMode
{
    if ( [ currentDevice isWhiteBalanceModeSupported: whiteBalanceMode ] )
    {
        NSError * error = nil;
        
        if ( [ currentDevice lockForConfiguration: &error ] )
        {
            
            [ currentDevice setWhiteBalanceMode: whiteBalanceMode ];
            
            [ currentDevice unlockForConfiguration ];
        }
    }
    else
    {
        sendMessage( MSG_ERROR, @"Exposure mode not supported" );
    }
}



- (void) setFocusMode : ( AVCaptureFocusMode ) focusMode
               focusX : ( CGFloat ) focusX
               focusY : ( CGFloat ) focusY
{
    if ( [ currentDevice isFocusModeSupported: focusMode ] )
    {
        NSError * error = nil;
        
        if ( [ currentDevice lockForConfiguration: &error ] )
        {
            if ( [ currentDevice isFocusPointOfInterestSupported ] )
            {
                CGPoint focalPoint = CGPointMake( focusX, focusY );
                [ currentDevice setFocusPointOfInterest: focalPoint ];
            }
            else 
            {
                sendMessage( MSG_WARNING, @"Focus point of interest not supported" );
            }
            
            [ currentDevice setFocusMode: focusMode ];
            
            [ currentDevice unlockForConfiguration ];
        }
    }
    else 
    {
        sendMessage( MSG_ERROR, @"Focus mode not supported" );
    }
}


- ( void ) setExposureMode : ( AVCaptureExposureMode ) exposureMode
                 exposureX : ( CGFloat ) exposureX
                 exposureY : ( CGFloat ) exposureY
{
    if ( [ currentDevice isExposureModeSupported: exposureMode ] )
    {
        NSError * error = nil;
        
        if ( [ currentDevice lockForConfiguration: &error ] )
        {
            if ( [ currentDevice isExposurePointOfInterestSupported ] )
            {
                CGPoint exposurePoint = CGPointMake( exposureX, exposureY );
                [ currentDevice setExposurePointOfInterest: exposurePoint ];
            }
            else 
            {
                sendMessage( MSG_WARNING, @"Exposure point of interest not supported" );
            }
            
            [ currentDevice setExposureMode: exposureMode ];
            
            [ currentDevice unlockForConfiguration ];
        }
        else if ( nil != error )
        {
            sendMessage( [ error description ], NULL );
        }
    }
    else 
    {
        sendMessage( MSG_ERROR, @"Exposure mode not supported" );
    }
}


- ( void ) addVideoInput:( BOOL ) useFrontCamera 
{
    NSArray *devices = [AVCaptureDevice devices];
    
    for ( AVCaptureDevice * device in devices ) 
    {
        if ( [ device hasMediaType: AVMediaTypeVideo ] ) 
        {
            switch ( [ device position ] ) 
            {
                case AVCaptureDevicePositionFront:
                {
                    if ( useFrontCamera )
                    {
                        currentDevice = device;
                        
                    }
                }
                break;
                    
                case AVCaptureDevicePositionBack:
                {
                    if ( !useFrontCamera )
                    {
                        currentDevice = device;
                    }
                }
                break;
                    
                default:
                {
                    sendMessage( MSG_ERROR, @"Camera position not recognised" );
                }
                break;
            }
        }
    }
    
    NSError * error = nil;
    /*AVCaptureDeviceInput **/ cameraInput = [ AVCaptureDeviceInput deviceInputWithDevice: currentDevice error: &error ];
    if (!error) 
    {
        if ( [ captureSession canAddInput: cameraInput ] ) 
        {
            [ captureSession addInput: cameraInput ];
        } 
    }
    else 
    { 
        sendMessage( error.localizedDescription, NULL );   
    }
}	


- ( CVPixelBufferRef ) applyFilters: ( CMSampleBufferRef ) sampleBuffer
{
    // 1. Get the pixel buffer and lock it for reading
    CVPixelBufferRef pixelBuffer = ( CVPixelBufferRef ) CMSampleBufferGetImageBuffer( sampleBuffer );
    CVReturn status = CVPixelBufferLockBaseAddress( pixelBuffer, 0 );    
    NSParameterAssert( kCVReturnSuccess == status );
    
    if ( 0 == rotationRadians )
    {
        // No rotation or cropping to perform, just display the frame we've got
        return pixelBuffer;
    }
    
    // 2. Apply transformations - rotate the image
    CIImage * originalImg = [ CIImage imageWithCVPixelBuffer: pixelBuffer ];
    CGRect originalImageRect = [ originalImg extent ];
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation( rotationRadians );
    CIImage * resultImg = [ originalImg imageByApplyingTransform: rotation ]; 
    
    CGRect extent = [ resultImg extent ];
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation( -extent.origin.x, -extent.origin.y );
    resultImg = [ resultImg imageByApplyingTransform: translation ];
    
    CGRect cropRect = CGRectMake( 0, 0, originalImageRect.size.height, originalImageRect.size.width );
    resultImg = [ resultImg imageByCroppingToRect: cropRect ];
    
    extent = [ resultImg extent ];

    // 3. Create a pixel buffer to render the result in
    CVPixelBufferRef resultBuffer = NULL;
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType( pixelBuffer );
 
    status = CVPixelBufferCreate( NULL, extent.size.width, extent.size.height, pixelFormatType, pixelBufferAttributes, &resultBuffer );    
    NSParameterAssert( kCVReturnSuccess == status && NULL != resultBuffer );
    
    status = CVPixelBufferLockBaseAddress( resultBuffer, 0 );
    NSParameterAssert( kCVReturnSuccess == status );
   
    CIContext * ciContext = [ CIContext contextWithOptions: NULL ];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    [ ciContext render: resultImg toCVPixelBuffer:resultBuffer bounds: extent colorSpace: colorSpace ];
   
    // 4. Tidy up
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );    
    CGColorSpaceRelease( colorSpace );
    
    // 5. And return the result pixel buffer to be displayed
    return resultBuffer; 
}


- ( void ) captureOutput: ( AVCaptureOutput * ) captureOutput 
   didOutputSampleBuffer: ( CMSampleBufferRef ) sampleBuffer 
          fromConnection: ( AVCaptureConnection * ) connection
{
    @autoreleasepool 
    {
        // pixelBuffer will have its base address locked by applyFilters
        CVPixelBufferRef pixelBuffer = [ self applyFilters: sampleBuffer ];
        
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow( pixelBuffer );
        size_t height = CVPixelBufferGetHeight( pixelBuffer );
        size_t width = CVPixelBufferGetWidth( pixelBuffer );
        
        void * src_buff = CVPixelBufferGetBaseAddress( pixelBuffer );
        [ self setWriteBuffer:[ NSData dataWithBytes: src_buff length: bytesPerRow * height ] ];
        
        @synchronized( synchObject )
        {
            // Swap the read, write and reserve buffers:
            
            NSData * tmp = reserveBuffer;
            reserveBuffer = readBuffer;
            readBuffer = writeBuffer;
            writeBuffer = tmp;
            
            ++frameIndex;
            
            if ( frameIndex >= NSIntegerMax - 1 )
            {
                frameIndex = 0;
            }   
        }
        
        NSString * frameSize = [ [ NSString alloc ] initWithFormat: @"%lu,%lu", width, height ] ;
        sendMessage( MSG_FRAME_READY, frameSize );
        [ frameSize release ];
        
        CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 ); 
    }
}


- ( void ) addVideoDataOutput: ( uint32_t ) minFPS
                       maxFPS: ( uint32_t ) maxFPS
{
    videoDataOutput = [ [ [ AVCaptureVideoDataOutput alloc ] init] autorelease ];
    
    dispatch_queue_t queue = dispatch_queue_create( "videoFramesQueue", NULL );
    [ videoDataOutput setSampleBufferDelegate: self queue: queue];
    dispatch_release( queue );
    
    videoDataOutput.videoSettings = [ NSDictionary 
                                     dictionaryWithObject: [ NSNumber numberWithInt: kCVPixelFormatType_32BGRA ] 
                                     forKey: ( id ) kCVPixelBufferPixelFormatTypeKey ];
    
    AVCaptureConnection * videoConnection = nil;
    
    for ( AVCaptureConnection * connection in [ videoDataOutput connections ] ) 
    {
        for ( AVCaptureInputPort * port in [ connection inputPorts ] ) 
        {
            if ( [ [ port mediaType ] isEqual: AVMediaTypeVideo ] ) 
            {
                videoConnection = connection;
                
                if ( videoConnection.supportsVideoMinFrameDuration )
                {
                    videoConnection.videoMinFrameDuration = CMTimeMake( 1, minFPS );
                }
                
                if ( videoConnection.supportsVideoMaxFrameDuration )
                {
                    videoConnection.videoMaxFrameDuration = CMTimeMake( 1, maxFPS );
                }
                
                break;
            }
        }
        if ( videoConnection ) 
        { 
            break; 
        }
    }

    [ captureSession addOutput: videoDataOutput ];
}


@end
