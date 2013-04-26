//
// Prefix header for all source files of the 'MessageBox' target in the 'MessageBox' project
//

#ifndef DEBUG
    #define DebugLog(str, ...) NSLog(str, ##__VA_ARGS__)
#else
    #define DebugLog(str, ...)
#endif

#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <QuartzCore/QuartzCore.h>
    #import <UIKit/UIKit.h>
    #import "CaptainHook/CaptainHook.h"
    #import <CoreGraphics/CoreGraphics.h>
    #include <notify.h>
    #include "substrate.h"
#endif

#define ROTATION_PORTRAIT_NOTIFICATION "ca.adambell.MessageBox.fbShouldRotatePortrait"
#define ROTATION_PORTRAIT_UPSIDEDOWN_NOTIFICATION "ca.adambell.MessageBox.fbShouldRotatePortraitUpsideDown"
#define ROTATION_LANDSCAPE_LEFT_NOTIFICATION "ca.adambell.MessageBox.fbShouldRotateLandscapeLeft"
#define ROTATION_LANDSCAPE_RIGHT_NOTIFICATION "ca.adambell.MessageBox.fbShouldRotateLandscapeRight"
#define DEVICE_ORIENTATION_CHANGED_NOTIFICATION "ca.adambell.MessageBox.fbShouldRotateToDeviceOrientation"