//
//  NativeCameraExtensioniOS.h
//  NativeCameraExtensioniOS
//
//  Created by Radoslava Leseva on 07/07/2012.
//  Copyright (c) 2012 DiaDraw. All rights reserved.
//


#import "FlashRuntimeExtensions.h"


//------------------------------------
//
// ActionScript interface
//
//------------------------------------
FREObject ASStartVideoCamera( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASStopVideoCamera( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASSetExposureMode( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASSetFocusMode( FREContext cts, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASSetWhiteBalanceMode( FREContext cts, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASGetFrameBuffer( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASSetRotationAngle( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASSetTranslationPoint( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] );
FREObject ASSetCropRectanglePixels( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] );


//------------------------------------
//
// Context initialization and finalization
//
//------------------------------------
void CameraExtensionContextInitializer( void * extData, 
                                       const uint8_t* ctxType, 
                                       FREContext ctx, 
                                       uint32_t* numFunctionsToTest, 
                                       const FRENamedFunction** functionsToSet );

void CameraExtensionContextFinalizer( FREContext ctx );


//------------------------------------
//
// Extension initialization and finalization
//
//------------------------------------
void CameraExtensionInitializer( void** extDataToSet, 
                                FREContextInitializer* ctxInitializerToSet, 
                                FREContextFinalizer* ctxFinalizerToSet );

void CameraExtensionFinalizer( void* extData );

