//
//  NativeCameraExtensioniOS.m
//  NativeCameraExtensioniOS
//
//  Created by Radoslava Leseva on 07/07/2012.
//  Copyright (c) 2012 DiaDraw. All rights reserved.
//


#import "FlashRuntimeExtensions.h"
#import "CameraDelegate.h"


CameraDelegate * cameraDelegate;
FREContext g_ctx;


//------------------------------------
//
// Auxiliary functions
//
//------------------------------------
void sendMessage( const NSString * const messageType, const NSString * const message ) 
{
    assert( NULL != messageType );
    assert( NULL != g_ctx );
    
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
    enum
    {
        ARG_RESOLUTION_PRESET = 0,
        ARG_MIN_FPS,
        ARG_MAX_FPS,
        ARG_USE_FRONT_CAMERA,
        
        ARG_COUNT
    };
    
    assert( ARG_COUNT == argc );
    
    ensureCameraDelegate();
    
    NSString * preset = getNSStringFromCString( argv[ ARG_RESOLUTION_PRESET ] );
    
    uint32_t minFPS = 0;
    FREGetObjectAsUint32( argv[ ARG_MIN_FPS ], &minFPS );
    
    uint32_t maxFPS = 0;
    FREGetObjectAsUint32( argv[ ARG_MAX_FPS ], &maxFPS );
    
    uint32_t useFrontCamera = NO;
    FREGetObjectAsBool( argv[ ARG_USE_FRONT_CAMERA ], &useFrontCamera );
    
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


FREObject ASSetTorchMode( FREContext cts, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    int32_t torchMode = 0;
    FREGetObjectAsInt32( argv[ 0 ], &torchMode );
    
    assert( AVCaptureTorchModeOff <= torchMode && torchMode <= AVCaptureTorchModeAuto );
    
    [ cameraDelegate setTorchMode: torchMode ];
    
    return NULL;
}


FREObject ASHasTorch( FREContext cts, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    BOOL hasTorch = [ cameraDelegate isTorchAvailable ];
    
    FREObject hasTorchResult = nil;
    FRENewObjectFromBool( hasTorch, &hasTorchResult );
    
    return hasTorchResult;
}


FREObject ASGetFrameWidth( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    FREObject frameWidth = nil;
    FRENewObjectFromInt32( [ cameraDelegate frameWidth ], &frameWidth );
    
    return frameWidth;
}


FREObject ASGetFrameHeight( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    FREObject frameHeight = nil;
    FRENewObjectFromInt32( [cameraDelegate frameHeight ], &frameHeight );
    
    return frameHeight;
}


FREObject ASGetFrameBuffer( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
{
    ensureCameraDelegate();
    
    FREObject    objectByteArray = argv[ 0 ];
    
    int32_t lastFrameConsumed = 0;
    FREGetObjectAsInt32( argv[ 1 ], &lastFrameConsumed );
    
    FREObject lastFrameConsumedUpdate = nil;
    int32_t frameReceived = 0;
    
    BOOL isFrameCopied = [ cameraDelegate copyLastFrame: lastFrameConsumed
                                                 buffer: objectByteArray
                                           currentFrame: &frameReceived ];
    
    if ( !isFrameCopied )
    {
        //frameReceived = -1;
    }
    
    FRENewObjectFromInt32( frameReceived, &lastFrameConsumedUpdate );
    
    return lastFrameConsumedUpdate;
}


//FREObject ASGetFrameBuffer( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] )
//{
//    enum
//    {
//        ARG_FRAME_BUFFER = 0,
//        ARG_LAST_FRAME_CONSUMED,
//        
//        ARG_COUNT
//    };
//    
//    assert( ARG_COUNT == argc );
//    
//    ensureCameraDelegate();
//    
//    FREObject    objectByteArray = argv[ ARG_FRAME_BUFFER ];
//    
//    int32_t lastFrameConsumed = 0;
//    FREGetObjectAsInt32( argv[ ARG_LAST_FRAME_CONSUMED ], &lastFrameConsumed );
//    
//    FREObject lastFrameConsumedUpdate = nil;
//    
//    @synchronized( g_ctx )
//    {
//        if ( lastFrameConsumed != [ cameraDelegate frameIndex ] )
//        {
//            FREObject    length;
//            FRENewObjectFromUint32( [ cameraDelegate readBuffer ].length, &length );
//
//            FRESetObjectProperty( objectByteArray, ( const uint8_t* ) "length", length, NULL );
//        
//            FREByteArray byteArray;
//            FREAcquireByteArray( objectByteArray, &byteArray );
//                memcpy( byteArray.bytes, [ cameraDelegate readBuffer ].bytes, [ cameraDelegate readBuffer ].length );
//            FREReleaseByteArray( objectByteArray );
//        }
//
//        FRENewObjectFromInt32( [ cameraDelegate frameIndex ], &lastFrameConsumedUpdate );
//    }
//    
//    return lastFrameConsumedUpdate;
//}


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
                                        uint32_t* numFunctionsToSet, 
                                        const FRENamedFunction** functionsToSet )
{
    static FRENamedFunction extensionFunctions[] =
    {
        { (const uint8_t*) "as_startVideoCamera",        NULL, &ASStartVideoCamera },
        { (const uint8_t*) "as_stopVideoCamera",         NULL, &ASStopVideoCamera },
        { (const uint8_t*) "as_setExposureMode",         NULL, &ASSetExposureMode },
        { (const uint8_t*) "as_setFocusMode",            NULL, &ASSetFocusMode },
        { (const uint8_t*) "as_setWhiteBalance",         NULL, &ASSetWhiteBalanceMode },
        { (const uint8_t*) "as_getFrameBuffer",          NULL, &ASGetFrameBuffer },
        { (const uint8_t*) "as_getFrameWidth",           NULL, &ASGetFrameWidth },
        { (const uint8_t*) "as_getFrameHeight",          NULL, &ASGetFrameHeight },
        { (const uint8_t*) "as_setRotationAngle",        NULL, &ASSetRotationAngle },
        { (const uint8_t*) "as_setTranslationPoint",     NULL, &ASSetTranslationPoint },
        { (const uint8_t*) "as_setCropRectanglePixels",  NULL, &ASSetCropRectanglePixels },
        { (const uint8_t*) "as_setTorchMode",            NULL, &ASSetTorchMode },
        { (const uint8_t*) "as_hasTorch",                NULL, &ASHasTorch }
    };
    
    *numFunctionsToSet =
    sizeof( extensionFunctions ) / sizeof( FRENamedFunction );
    
    *functionsToSet = extensionFunctions;
    
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
    cameraDelegate = NULL;
    return;
}


//@end
