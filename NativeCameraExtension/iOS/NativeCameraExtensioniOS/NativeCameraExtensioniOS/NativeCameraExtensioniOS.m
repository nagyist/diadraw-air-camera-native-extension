//
//  NativeCameraExtensioniOS.m
//  NativeCameraExtensioniOS
//
//  Created by Radoslava Leseva on 07/07/2012.
//  Copyright (c) 2012 DiaDraw. All rights reserved.
//


#import "CameraDelegate.h"
#import "NativeCameraExtensioniOS.h"


CameraDelegate * cameraDelegate;
FREContext g_ctx;


//------------------------------------
//
// Auxiliary functions
//
//------------------------------------
void sendMessage( const NSString * const messageType, const NSString * const message ) 
{
    assert( messageType );
    
    if ( NULL != message )
    {
        FREDispatchStatusEventAsync( g_ctx, ( uint8_t * ) [ messageType UTF8String ], ( uint8_t * ) [ message UTF8String ] );
    }
    else
    {
        FREDispatchStatusEventAsync( g_ctx, ( uint8_t * ) [ @"STATUS_EVENT" UTF8String ], ( uint8_t * ) [ messageType UTF8String ] );
    }
}


void ensureCameraDelegate( void )
{
    assert( g_ctx );
    
    if ( !cameraDelegate )
    {
        cameraDelegate = [ [ CameraDelegate alloc ] init ];
        cameraDelegate.synchObject = g_ctx;
        cameraDelegate.sendMessage = sendMessage;
    }
}


NSString * getNSStringFromCString( FREObject arg )
{
    NSString * resultString = NULL;
    
    uint32_t strLength = 0;
    const uint8_t * argCString = NULL;
    FREResult argumentResult = FREGetObjectAsUTF8( arg, &strLength, &argCString );
    
    if ( ( FRE_OK == argumentResult ) && ( 0 < strLength ) && ( NULL != argCString ) )
    {
        resultString = [ NSString stringWithUTF8String:(const char *) argCString ];
    }
    
    return resultString;
}


//------------------------------------
//
// ActionScript interface
//
//------------------------------------

FREObject ASStartVideoCamera( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    assert( 4 == argc );
    
    ensureCameraDelegate();
    
    NSString * preset = getNSStringFromCString( argv[ 0 ] );
    
    uint32_t minFPS = 0;
    FREGetObjectAsUint32( argv[ 1 ], &minFPS );
    
    uint32_t maxFPS = 0;
    FREGetObjectAsUint32( argv[ 2 ], &maxFPS );
    
    uint32_t useFrontCamera = NO;
    FREGetObjectAsBool( argv[ 3 ], &useFrontCamera );
    
    uint32_t isCameraStarted = [ cameraDelegate startVieoCamera: preset minFPS:minFPS maxFPS:maxFPS useFrontCamera:useFrontCamera ];
    
    FREObject cameraStartedResult = nil;
    FRENewObjectFromBool( isCameraStarted, &cameraStartedResult );
    
    return cameraStartedResult;
}


FREObject ASStopVideoCamera( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    [ cameraDelegate stopVideoCamera ];
    
    return NULL;
}


FREObject ASSetExposureMode( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();

    int32_t exposureMode = 0;
    FREGetObjectAsInt32( argv[ 0 ], &exposureMode );
    
    assert( AVCaptureExposureModeLocked <= exposureMode && exposureMode <= AVCaptureExposureModeContinuousAutoExposure );
    
    double x = 0.5f;
    double y = 0.5f;
    
    if ( 3 == argc )
    {
        FREGetObjectAsDouble( argv[ 1 ], &x );
        assert( 0.0 <= x && x <= 1.0 );
        
        FREGetObjectAsDouble( argv[ 2 ], &y );
        assert( 0.0 <= y && y <= 1.0 );
    }
   
    [ cameraDelegate setExposureMode: exposureMode exposureX:x exposureY:x ];

    return NULL;
}



FREObject ASSetFocusMode( FREContext cts, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    int32_t focusMode = 0;
    FREGetObjectAsInt32( argv[ 0 ], &focusMode );
    
    assert( AVCaptureFocusModeLocked <= focusMode && focusMode <= AVCaptureFocusModeContinuousAutoFocus );
    
    double x = 0.5f;
    double y = 0.5f;
    
    if ( 3 == argc )
    {
        FREGetObjectAsDouble( argv[ 1 ], &x );
        assert( 0.0 <= x && x <= 1.0 );
        
        FREGetObjectAsDouble( argv[ 2 ], &y );
        assert( 0.0 <= y && y <= 1.0 );
    }
    
    [ cameraDelegate setFocusMode: focusMode focusX:x focusY:x ];
    
    return NULL;
}


FREObject ASSetWhiteBalanceMode( FREContext cts, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    int32_t whiteBalanceMode = 0;
    FREGetObjectAsInt32( argv[ 0 ], &whiteBalanceMode );
    
    assert( AVCaptureWhiteBalanceModeLocked <= whiteBalanceMode && whiteBalanceMode <= AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance );
    
    
    [ cameraDelegate setWhiteBalanceMode: whiteBalanceMode ];
    
    return NULL;
}



FREObject ASGetFrameBuffer( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    FREObject    objectByteArray = argv[ 0 ]; 
    
    int32_t lastFrameConsumed = 0;
    FREGetObjectAsInt32( argv[ 1 ], &lastFrameConsumed );
    
    FREObject lastFrameConsumedUpdate = nil;
    
    @synchronized( g_ctx )
    {
        if ( lastFrameConsumed != [ cameraDelegate frameIndex ] )
        {
            FREObject    length;
            FRENewObjectFromUint32( [ cameraDelegate readBuffer ].length, &length );

            FRESetObjectProperty( objectByteArray, ( const uint8_t* ) "length", length, NULL );
        
            FREByteArray byteArray;
            FREAcquireByteArray( objectByteArray, &byteArray );
                memcpy( byteArray.bytes, [ cameraDelegate readBuffer ].bytes, [ cameraDelegate readBuffer ].length );
            FREReleaseByteArray( objectByteArray );
        }

        FRENewObjectFromInt32( [ cameraDelegate frameIndex ], &lastFrameConsumedUpdate );
    }
    
    return lastFrameConsumedUpdate;
}


FREObject ASSetRotationAngle( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    double angleDegrees = 0.0;
    FREGetObjectAsDouble( argv[ 0 ], &angleDegrees );
    
    double angleRadians = ( angleDegrees * M_PI ) / 180.0;
    [ cameraDelegate setRotationRadians: angleRadians ];
    
    return NULL;
}


FREObject ASSetTranslationPoint( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    int32_t x = 0;
    FREGetObjectAsInt32( argv[ 0 ], &x ); 
    
    int32_t y = 0;
    FREGetObjectAsInt32( argv[ 1 ], &y );
    
    CGPoint translationPoint = CGPointMake( x, y );
    
    [ cameraDelegate setTranslationPixels: translationPoint ];
    
    return NULL;
}


FREObject ASSetCropRectanglePixels( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    double x = 0;
    FREGetObjectAsDouble( argv[ 0 ], &x ); 
    
    double y = 0;
    FREGetObjectAsDouble( argv[ 1 ], &y );
    
    double w = 0;
    FREGetObjectAsDouble( argv[ 2 ], &w );
    
    double h = 0;
    FREGetObjectAsDouble( argv[ 3 ], &h );
    
    CGRect cropRect = CGRectMake( x, y, w, h );
    
    [ cameraDelegate setCropRectangle: cropRect ];
    
    return NULL;
}


//------------------------------------
//
// Context initialization and finalization
//
//------------------------------------
void CameraExtensionContextInitializer( void * extData, 
                                        const uint8_t* ctxType, 
                                        FREContext ctx, 
                                        uint32_t* numFunctionsToTest, 
                                        const FRENamedFunction** functionsToSet )
{
    typedef enum 
    {
        AS_START_VIDEO_CAMERA       = 0,
        AS_STOP_VIDEO_CAMERA        = 1,
        AS_SET_AUTO_EXPOSE          = 2,
        AS_SET_AUTO_FOCUS           = 3,
        AS_SET_AUTO_WHITE_BALANCE   = 4,
        AS_GET_FRAME_BUFFER         = 5,
        AS_SET_ROTATION_ANGLE       = 6,
        AS_SET_TRANSLATION_PIXELS   = 7,
        AS_SET_CROP_RECTANGLE       = 8,
        
        AS_METHOD_COUNT
    } ASMethods;
    

	*numFunctionsToTest = AS_METHOD_COUNT;
    
	FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * (*numFunctionsToTest));
	func[ AS_START_VIDEO_CAMERA ].name = (const uint8_t*) "as_startVideoCamera";
	func[ AS_START_VIDEO_CAMERA ].functionData = NULL;
    func[ AS_START_VIDEO_CAMERA ].function = &ASStartVideoCamera;
    
    func[ AS_STOP_VIDEO_CAMERA ].name = (const uint8_t*) "as_stopVideoCamera";
	func[ AS_STOP_VIDEO_CAMERA ].functionData = NULL;
    func[ AS_STOP_VIDEO_CAMERA ].function = &ASStopVideoCamera;
    
    func[ AS_SET_AUTO_EXPOSE ].name = (const uint8_t*) "as_setExposureMode";
	func[ AS_SET_AUTO_EXPOSE ].functionData = NULL;
    func[ AS_SET_AUTO_EXPOSE ].function = &ASSetExposureMode;
    
    func[ AS_SET_AUTO_FOCUS ].name = (const uint8_t*) "as_setFocusMode";
	func[ AS_SET_AUTO_FOCUS ].functionData = NULL;
    func[ AS_SET_AUTO_FOCUS ].function = &ASSetFocusMode;
    
    func[ AS_SET_AUTO_WHITE_BALANCE ].name = (const uint8_t*) "as_setWhiteBalance";
	func[ AS_SET_AUTO_WHITE_BALANCE ].functionData = NULL;
    func[ AS_SET_AUTO_WHITE_BALANCE ].function = &ASSetWhiteBalanceMode;
    
    func[ AS_GET_FRAME_BUFFER ].name = (const uint8_t*) "as_getFrameBuffer";
	func[ AS_GET_FRAME_BUFFER ].functionData = NULL;
    func[ AS_GET_FRAME_BUFFER ].function = &ASGetFrameBuffer;
    
    func[ AS_SET_ROTATION_ANGLE ].name = (const uint8_t*) "as_setRotationAngle";
	func[ AS_SET_ROTATION_ANGLE ].functionData = NULL;
    func[ AS_SET_ROTATION_ANGLE ].function = &ASSetRotationAngle;
    
    func[ AS_SET_TRANSLATION_PIXELS ].name = (const uint8_t*) "as_setTranslationPoint";
	func[ AS_SET_TRANSLATION_PIXELS ].functionData = NULL;
    func[ AS_SET_TRANSLATION_PIXELS ].function = &ASSetTranslationPoint;
    
    func[ AS_SET_CROP_RECTANGLE ].name = (const uint8_t*) "as_setCropRectanglePixels";
	func[ AS_SET_CROP_RECTANGLE ].functionData = NULL;
    func[ AS_SET_CROP_RECTANGLE ].function = &ASSetCropRectanglePixels;
    
	*functionsToSet = func;
	
	g_ctx = ctx;
}


void CameraExtensionContextFinalizer( FREContext ctx )
{
    return;
}


//------------------------------------
//
// Extension initialization and finalization
//
//------------------------------------
void CameraExtensionInitializer( void** extDataToSet, 
                                 FREContextInitializer* ctxInitializerToSet, 
                                 FREContextFinalizer* ctxFinalizerToSet )
{
    *extDataToSet = NULL;
    *ctxInitializerToSet = &CameraExtensionContextInitializer;
    *ctxFinalizerToSet = &CameraExtensionContextFinalizer;
}


void CameraExtensionFinalizer( void* extData )
{
    [ cameraDelegate release ];
    return;
}


//@end
