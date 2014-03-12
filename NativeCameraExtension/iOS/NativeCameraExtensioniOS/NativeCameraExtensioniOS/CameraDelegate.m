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


extern void sendMessage( const NSString * const messageType, const NSString * const message );


@interface CameraDelegate()
{
@private
}
@end


@implementation CameraDelegate


@synthesize translationPixels;
@synthesize rotationRadians;
@synthesize cropRectangle;
@synthesize readBuffer;
@synthesize writeBuffer;
@synthesize reserveBuffer;
@synthesize frameIndex;

@synthesize frameWidth;
@synthesize frameHeight;


CFMutableDictionaryRef pixelBufferAttributes;
CFDictionaryRef emptyIOSurfaceAttributes;
AVCaptureSession * captureSession;
AVCaptureVideoDataOutput * videoDataOutput;
AVCaptureDeviceInput * cameraInput;
AVCaptureDevice * currentDevice;


static const NSString * const MSG_WARNING = @"WARNING";
static const NSString * const MSG_ERROR = @"ERROR";
static const NSString * const MSG_FRAME_READY = @"IMAGE_READY";
static const NSString * const MSG_CAMERA_STARTED = @"CAMERA_STARTED";


#define REPORT_MEMORY_USE 0

#if REPORT_MEMORY_USE
#import <mach/mach.h>
#import<malloc/malloc.h>

static const double MB = 1.0 / ( 1024.0 * 1024.0 );

static int lastUsedMemory = 0;
static int maxUsedMemory = 0;
static int frIdx = 0;

- ( void ) report_memory: ( BOOL ) deltaOnly
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    
    kern_return_t kerr = task_info( mach_task_self(), TASK_BASIC_INFO, ( task_info_t ) &info, &size );
    
    
    if ( 1 == frIdx )
    {
        NSLog(@"Frame [ %d ], memory in use (MB): %f", frIdx, info.resident_size * MB );
    }
    
    
    if ( deltaOnly )
    {
        if ( ( maxUsedMemory - info.resident_size ) * MB > 100 && lastUsedMemory > info.resident_size )
        {
            NSLog(@"Frame [ %d ], memory in use (MB): %f, maximum memory used (MB): %f", frIdx, info.resident_size * MB, maxUsedMemory * MB );
        }
    }
    else
    {
        if ( KERN_SUCCESS == kerr )
        {
            NSLog(@"Frame [ %d ], memory in use (MB): %f", frIdx, info.resident_size * MB );
        }
        else
        {
            NSLog( @"Error with task_info(): %s", mach_error_string(kerr));
        }
    }
    
    lastUsedMemory = info.resident_size;
    if ( lastUsedMemory > maxUsedMemory )
    {
        maxUsedMemory = lastUsedMemory;
    }
}
#endif


- ( id ) init
{
    if ( self = [ super init ] )
    {
        captureSession = [ [ AVCaptureSession alloc ] init ];
        rotationRadians = 0.0;
        [ self setFrameWidth: 0 ];
        [ self setFrameHeight: 0 ];
        
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
    BOOL result = false;
    
    if ( [ captureSession canSetSessionPreset: preset ] )
    {
        captureSession.sessionPreset = preset;
        
        [ self addVideoDataOutput: minFPS maxFPS: maxFPS ];
        
        if ( [ self addVideoInput : useFrontCamera ] )
        {
            id didStartRunningObserver = [ [ NSNotificationCenter defaultCenter ] addObserverForName: AVCaptureSessionDidStartRunningNotification
                                                                                              object: captureSession
                                                                                               queue: [ NSOperationQueue mainQueue ]
                                                                                          usingBlock: ^( NSNotification * note )
                                          {
                                              sendMessage( MSG_CAMERA_STARTED, @"Camera started" );
                                          } ];
            
            
            
            
            
            [ captureSession startRunning];
        
            frameIndex = 0;
        
            result = didStartRunningObserver;
        }
    }
    else 
    {
        sendMessage( MSG_ERROR, @"Preset not supported on device" );
    }
    
    return result;
}


- (void) stopVideoCamera
{
    @synchronized( self )
    {
        if ( [ captureSession isRunning ] )
        {
            [ captureSession stopRunning];
            [ captureSession removeOutput: videoDataOutput ];
            [ captureSession removeInput: cameraInput ];
        }
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
        sendMessage( MSG_ERROR, @"White balance mode not supported" );
    }
}


- (BOOL) isTorchAvailable 
{
    return [ currentDevice hasTorch ];
}


- (void) setTorchMode : ( AVCaptureTorchMode ) torchMode
{
    if ( [ currentDevice isTorchModeSupported: torchMode ] )
    {
        NSError * error = nil;
        
        if ( [ currentDevice lockForConfiguration: &error ] )
        {
            
            [ currentDevice setTorchMode: torchMode ];
            
            [ currentDevice unlockForConfiguration ];
        }
    }
    else
    {
        sendMessage( MSG_ERROR, @"Torch mode not supported" );
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


- ( BOOL ) addVideoInput:( BOOL ) useFrontCamera
{
    BOOL result = false;
    
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
    cameraInput = [ AVCaptureDeviceInput deviceInputWithDevice: currentDevice error: &error ];
    if (!error) 
    {
        if ( [ captureSession canAddInput: cameraInput ] ) 
        {
            [ captureSession addInput: cameraInput ];
            result = true;
        }
        else
        {
            sendMessage( MSG_ERROR, [ NSString stringWithFormat: @"Preset not supported on %@", ( useFrontCamera ? @"front camera" : @"back camera" ) ]);
        }
    }
    else 
    { 
        sendMessage( error.localizedDescription, NULL );   
    }
    
    return result;
}


- ( BOOL ) copyLastFrame: ( int32_t ) lastFrameCopied
                  buffer: ( FREObject ) objectByteArray
            currentFrame: ( int32_t * ) lastFrameConsumedUpdate
{
    BOOL isFrameCopied = NO;
    *lastFrameConsumedUpdate = -10;
    
    @synchronized( self )
    {
        if ( NULL != readBuffer )
        {
            [ self setReserveBuffer: NULL ];
            [ self setReserveBuffer: readBuffer ];
            [ self setReadBuffer: NULL ];
        }
        else
        {
            *lastFrameConsumedUpdate = 11;
        }
    }
    
    if ( NULL == reserveBuffer )                { *lastFrameConsumedUpdate = -2; return NO; }
    
    if ( NULL == reserveBuffer.bytes )          { *lastFrameConsumedUpdate = -3; return NO; }
    
    if ( lastFrameCopied == [ self frameIndex ] )   { *lastFrameConsumedUpdate = -4; return NO; }
    
    uint32_t lengthValue = reserveBuffer.length;
    
    if ( 0 == lengthValue )                         { *lastFrameConsumedUpdate = -5; return NO; }
    
    FREObject    length;
    FRENewObjectFromUint32( lengthValue, &length );
    
    FREObject thrownException;
    FREResult status = FRESetObjectProperty( objectByteArray, ( const uint8_t* ) "length", length, &thrownException );
    if ( FRE_OK != status )
    {
        *lastFrameConsumedUpdate = -7;
        
        FREObjectType objectType;
        FREResult res = FREGetObjectType( thrownException, &objectType );
        
        if ( FRE_TYPE_OBJECT == objectType )
        {
            FREObject callResult;
            
            FREObject newException;
            
            res = FRECallObjectMethod( thrownException, ( const uint8_t * ) "toString", 0, NULL, &callResult, &newException );
            uint32_t strLength = 0;
            const uint8_t * argCString = NULL;
            FREResult argumentResult = FREGetObjectAsUTF8( callResult, &strLength, &argCString );
            
            if ( FRE_OK == argumentResult )
            {
                sendMessage( MSG_ERROR, [ NSString stringWithFormat: @"exception: %s", argCString ] );
                
                *lastFrameConsumedUpdate = -99;
            }
            else
            {
                *lastFrameConsumedUpdate = -50;
            }
        }
        
        /**/
        return NO;
    }
    
    FREByteArray byteArray;
    status = FREAcquireByteArray( objectByteArray, &byteArray );
    if ( FRE_OK != status )                         { *lastFrameConsumedUpdate = -8; return NO; }
    
    if ( byteArray.length != reserveBuffer.length ) { *lastFrameConsumedUpdate = byteArray.length; return NO; }
    
    memcpy( byteArray.bytes, reserveBuffer.bytes, byteArray.length );
    
    status = FREReleaseByteArray( objectByteArray );
    if ( FRE_OK != status )                         { *lastFrameConsumedUpdate = -9; return NO; }
    
    *lastFrameConsumedUpdate = frameIndex;
    
    isFrameCopied = YES;
    
    if ( !isFrameCopied )
    {
        *lastFrameConsumedUpdate = -6;
    }
    
    [ self setReserveBuffer: NULL ];
    
    return isFrameCopied;
}



- ( void ) applyFilters: ( CVPixelBufferRef * ) pixelBuffer
{
    assert( NULL != pixelBuffer );
    assert( NULL != * pixelBuffer );
    
    @autoreleasepool
    {
        // 1. Apply transformations - rotate the image
        CIImage * originalImg = [ CIImage imageWithCVPixelBuffer: *pixelBuffer ];
        
        CGAffineTransform rotation = CGAffineTransformMakeRotation( rotationRadians );
        CIImage * resultImg = [ originalImg imageByApplyingTransform: rotation ];
        
        CGRect extent = [ resultImg extent ];
        
        CGAffineTransform translation = CGAffineTransformMakeTranslation( -extent.origin.x, -extent.origin.y );
        resultImg = [ resultImg imageByApplyingTransform: translation ];
        
        extent = [ resultImg extent ];
        
        // 2. Create a pixel buffer to render the result in
        CVPixelBufferRef resultBuffer = NULL;
        OSType pixelFormatType = CVPixelBufferGetPixelFormatType( *pixelBuffer );
        
        CVReturn status = CVPixelBufferCreate( NULL, extent.size.width, extent.size.height, pixelFormatType, pixelBufferAttributes, &resultBuffer );
        NSParameterAssert( kCVReturnSuccess == status && NULL != resultBuffer );
        
        status = CVPixelBufferLockBaseAddress( resultBuffer, 0 );
        NSParameterAssert( kCVReturnSuccess == status );
        
        CIContext * ciContext = [ CIContext contextWithOptions: NULL ];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        [ ciContext render: resultImg toCVPixelBuffer: resultBuffer bounds: extent colorSpace: colorSpace ];
        
        [ self swapFrameBuffers: resultBuffer ];
        
        // 3. Tidy up
        CGColorSpaceRelease( colorSpace );
        
        ciContext = NULL;
        originalImg = NULL;
        resultImg = NULL;
        
        CVPixelBufferUnlockBaseAddress( resultBuffer, 0 );
        CVPixelBufferRelease( resultBuffer );
    }
}


- ( void ) swapFrameBuffers: ( CVPixelBufferRef ) pixelBuffer
{
    // The pixel buffer's base address will already have been locked
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow( pixelBuffer );
    size_t height = CVPixelBufferGetHeight( pixelBuffer );
    size_t width = CVPixelBufferGetWidth( pixelBuffer );
    
    void * src_buff = CVPixelBufferGetBaseAddress( pixelBuffer );
    [ self setWriteBuffer:[ NSData dataWithBytes: src_buff length: bytesPerRow * height ] ];
    
    @synchronized( self )
    {
        [ self setReadBuffer: writeBuffer ];
        [ self setWriteBuffer: NULL ];
        
        ++frameIndex;
        
        if ( frameIndex >= NSIntegerMax - 1 )
        {
            frameIndex = 0;
        }
    }
    
    size_t widthPadding = ( bytesPerRow - ( width * 4 ) ) / 4.0;
    
    [ self setFrameWidth: width + widthPadding ];
    [ self setFrameHeight: height ];
    
    NSString * frameSize = [ [ NSString alloc ] initWithFormat: @"%lu,%lu", width + widthPadding, height ] ;
    sendMessage( MSG_FRAME_READY, frameSize );
    [ frameSize release ];
    // The pixel buffer's base address will be unlocked by the caller
}


- ( void ) captureOutput: ( AVCaptureOutput * ) captureOutput
   didOutputSampleBuffer: ( CMSampleBufferRef ) sampleBuffer 
          fromConnection: ( AVCaptureConnection * ) connection
{
    CVPixelBufferRef pixelBuffer = ( CVPixelBufferRef ) CMSampleBufferGetImageBuffer( sampleBuffer );
    
    @autoreleasepool 
    {
        CVReturn status = CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
        NSParameterAssert( kCVReturnSuccess == status );

        if ( 0 == rotationRadians )
        {
            [ self swapFrameBuffers: pixelBuffer ];
        }
        else
        {
            [ self applyFilters: &pixelBuffer ];
        }
        
        CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    }

    
#if REPORT_MEMORY_USE
    [ self report_memory: NO ];
#endif
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
