//
//  ABMessageBox_Facebook.mm
//  MessageBox
//
//  Created by Adam Bell on 2013-04-24.
//  Copyright (c) 2013 Adam Bell. All rights reserved.
//

#import "ABMessageBox_Facebook.h"

CHDeclareClass(FBCoveringSplitView);
CHDeclareClass(FBChatHeadSurfaceView);
CHDeclareClass(FBStackView);
CHDeclareClass(FBMediaGalleryBottomBar);
CHDeclareClass(SPFilterBarView);
CHDeclareClass(FBDimmingView);
CHDeclareClass(UIViewController);
CHDeclareClass(FBChatHeadViewController);
CHDeclareClass(FBMThreadDetailContactHeaderView);
CHDeclareClass(AppDelegate);
CHDeclareClass(UIWindow);
CHDeclareClass(UITextEffectsWindow);

@class FBChatHeadView;

static UIView *fbStackView;
static UIView *fbSplitView;
static FBChatHeadSurfaceView *fbChatView;
static FBDimmingView *fbDimmingView;
static FBChatHeadViewController *fbChatHeadViewController;
static NSTimeInterval refreshInterval = 15;
static NSTimer *refreshTimer = nil;

@implementation ABMessageBox_Facebook

// Convenience methods for debugging purposes

+ (UIView *)stackView
{
    return fbStackView;
}

+ (FBChatHeadSurfaceView *)chatView
{
    return fbChatView;
}

+ (UIView *)splitView
{
    return fbSplitView;
}

+ (FBChatHeadViewController *)chatHeadViewController
{
    return fbChatHeadViewController;
}

+ (FBDimmingView *)dimmingView
{
    return fbDimmingView;
}

@end

CHOptimizedMethod1(self, void, AppDelegate, applicationDidBecomeActive, UIApplication *, app)
{
    DebugLog(@"FACEBOOK DID BECOME ACTIVE");
    
    //Convenience hack
    
    [[[UIApplication sharedApplication] delegate] applicationWillEnterForeground:app];
    
    CHSuper1(AppDelegate, applicationDidBecomeActive, app);
}

// Needed hack because 3.5" devices

CHDeclareMethod0(void, FBChatHeadViewController, dismissPopoverInstantly)
{
    [fbChatHeadViewController dismissPopoverAnimated:NO];
}

CHOptimizedMethod1(self, void, AppDelegate, applicationDidEnterBackground, UIApplication *, app)
{
    notify_post("ca.adambell.MessageBox.fbQuitting");
    
    DebugLog(@"FACEBOOK RESIGNING ACTIVE");

    [UIWindow setAllWindowsKeepContextInBackground:YES];
    
    // Nicer way to get the chat heads out of the app
    // Throw them offscreen, and bring them back when the app is suspended
    
    if (fbChatView.chatHeadViews != nil && fbChatView.chatHeadViews.count > 0)
    {
        FBChatHeadView *firstChatHeadView = fbChatView.chatHeadViews[0];
        CGPoint newPoint = [fbChatView nearestMagnetLocationForPoint:firstChatHeadView.frame.origin];
        newPoint.x += newPoint.x > fbChatView.center.x ? 100 : -100;
        
        for (FBChatHeadView *chatHeadView in fbChatView.chatHeadViews)
        {
            [chatHeadView animateToPoint:newPoint velocity:CGPointMake(1.0, 1.0) completion:nil];
        }
    }
    
    [fbChatView performSelector:@selector(moveChatHeadsToStackedLayout) withObject:nil afterDelay:0.8];
    [fbChatView performSelector:@selector(moveStackToHomeLocation) withObject:nil afterDelay:0.8];
    
    [fbChatHeadViewController dismissPopoverAnimated:NO];
    
    // Hack needed for 3.5" devices, no idea why it doesn't actually dismiss the popover sometimes...
    
    [fbChatHeadViewController performSelector:NSSelectorFromString(@"dismissPopoverInstantly") withObject:nil afterDelay:1.0];
    
    UIView *mainView = [[[UIApplication sharedApplication] delegate] window].subviews[0];
    [mainView setBackgroundColor:[UIColor clearColor]];
    [[[[UIApplication sharedApplication] delegate] window] setBackgroundColor:[UIColor clearColor]];
    
    [[[UIApplication sharedApplication] valueForKey:@"_statusBarWindow"] setAlpha:0.0];
        
    if (mainView.subviews.count > 1)
        [mainView.subviews[0] setHidden:YES];
    if (mainView.subviews.count > 2)
        [mainView.subviews[2] setHidden:YES];
    
    UIView *v = mainView.subviews[0];
    [v setBackgroundColor:[UIColor clearColor]];
    
    fbStackView.hidden = NO;
    fbSplitView.hidden = NO;
    
    fbStackView.backgroundColor = [UIColor clearColor];
    fbSplitView.backgroundColor = [UIColor clearColor];
        
    for (UIView *view in fbSplitView.subviews)
    {
        view.hidden = YES;
    }
    
    CHSuper1(AppDelegate, applicationDidEnterBackground, app);
}

CHOptimizedMethod1(self, void, AppDelegate, applicationWillEnterForeground, UIApplication *, app)
{
    notify_post("ca.adambell.MessageBox.fbLaunching");
    
    DebugLog(@"FACEBOOK BECOMING ACTIVE");
    
    UIView *mainView = [[[UIApplication sharedApplication] delegate] window].subviews[0];
    [mainView setBackgroundColor:[UIColor clearColor]];
    
    [[[[UIApplication sharedApplication] delegate] window] setBackgroundColor:[UIColor clearColor]];
    [[[UIApplication sharedApplication] valueForKey:@"_statusBarWindow"] setAlpha:1.0];
    
    if (mainView.subviews.count > 1)
        [mainView.subviews[0] setHidden:NO];
    if (mainView.subviews.count > 2)
        [mainView.subviews[2] setHidden:NO];
    UIView *v = mainView.subviews[0];
    [v setBackgroundColor:[UIColor clearColor]];
    
    fbStackView.hidden = NO;
    fbSplitView.hidden = NO;
    
    fbStackView.backgroundColor = [UIColor clearColor];
    fbSplitView.backgroundColor = [UIColor clearColor];
    
    for (UIView *view in fbSplitView.subviews)
    {
        view.hidden = NO;
    }
    
    CHSuper1(AppDelegate, applicationWillEnterForeground, app);
}

// Easiest way to hide/restore these later on by grabbing their ivars

CHOptimizedMethod7(self, id, FBChatHeadSurfaceView, initWithFrame, CGRect, frame, chatHeadProvider, id, provider, threadUserMap, id, map, participantFilter, id, filter, threadSet, id, set, gatingChecker, id, checker, appProperties, id, properties)
{
    DebugLog(@"GOT CHAT HEAD SURFACE VIEW");
    
    id hax = CHSuper7(FBChatHeadSurfaceView, initWithFrame, frame, chatHeadProvider, provider, threadUserMap, map, participantFilter, filter, threadSet, set, gatingChecker, checker, appProperties, properties);
    fbChatView = hax;
    return hax;
}

CHOptimizedMethod1(self, id, FBCoveringSplitView, initWithFrame, CGRect, frame)
{
    DebugLog(@"GOT COVERING SPLIT VIEW");
    
    id hax = CHSuper1(FBCoveringSplitView, initWithFrame, frame);
    fbSplitView = hax;
    return hax;
}

CHOptimizedMethod1(self, id, FBStackView, initWithFrame, CGRect, frame)
{
    DebugLog(@"GOT STACK VIEW");
    
    id hax = CHSuper1(FBStackView, initWithFrame, frame);
    fbStackView = hax;
    return hax;
}

CHOptimizedMethod1(self, id, FBDimmingView, initWithFrame, CGRect, frame)
{
    DebugLog(@"GOT DIMMING VIEW");
    
    id hax = CHSuper1(FBDimmingView, initWithFrame, frame);
    fbDimmingView = hax;
    return hax;
}

CHOptimizedMethod1(self, id, FBMediaGalleryBottomBar, initWithFrame, CGRect, frame)
{
    DebugLog(@"GOT FBMediaGalleryBottomBar");
    
    id hax = CHSuper1(FBMediaGalleryBottomBar, initWithFrame, frame);
    
    // Can't allow filters when suspended, because that's GL based :(
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        [[hax valueForKey:@"_filterButton"] setHidden:YES];
        [[hax valueForKey:@"_cropButton"] setHidden:YES];
        [[hax valueForKey:@"_luxButton"] setHidden:YES];
    }
    else
    {
        [[hax valueForKey:@"_filterButton"] setHidden:NO];
        [[hax valueForKey:@"_cropButton"] setHidden:NO];
        [[hax valueForKey:@"_luxButton"] setHidden:NO];
    }
    return hax;
}

CHOptimizedMethod1(self, id, SPFilterBarView, initWithFrame, CGRect, frame)
{
    DebugLog(@"GOT SPFILTERBARVIEW");
    
    // OpenGL crashes application if called from suspension
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        return nil;
    }
    
    id hax = CHSuper1(SPFilterBarView, initWithFrame, frame);
    return hax;
}

CHDeclareMethod0(void, FBChatHeadViewController, createRefreshTimer)
{
    [self performSelector:@selector(stopRefreshTimer)];
    /*refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval
                                                    target:self
                                                  selector:@selector(enteredForeground)
                                                  userInfo:nil
                                                   repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:refreshTimer
                                 forMode:NSDefaultRunLoopMode];*/
}

CHDeclareMethod0(void, FBChatHeadViewController, stopRefreshTimer)
{
    if (refreshTimer != nil)
    {
        [refreshTimer invalidate];
        refreshTimer = nil;
    }
}

CHDeclareMethod1(void, FBChatHeadViewController, forceRotationToInterfaceOrientation, UIInterfaceOrientation, orientation)
{
    DebugLog(@"NEXT ORIENTATION: %d", orientation);
    
    // Popover blows up when rotated
    
    [fbChatHeadViewController dismissPopoverAnimated:NO];
        
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation];
    
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        [window _setRotatableViewOrientation:orientation
                                    duration:0.0
                                       force:YES];
    }
    
    /*
     Some crazy UIKeyboard hacks because for some reason UIKeyboard has a seizure when a suspended app tries to rotate...
     
     if orientation == 1
        revert to identity matrix
     if orientation == 2
        flip keyboard PI
     if orientation == 3
        flip keyboard PI/2 RAD
        set frame & bounds to screen size
     if orientation == 4
        flip keyboard -PI/2 RAD
        set frame & bounds to screen size
     */
    
    UITextEffectsWindow *keyboardWindow = [UITextEffectsWindow sharedTextEffectsWindow];

    switch (orientation)
    {
            
        case UIInterfaceOrientationPortrait:
        {
            keyboardWindow.transform = CGAffineTransformIdentity;
            break;
        }
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            keyboardWindow.transform = CGAffineTransformMakeRotation(M_PI);
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        {
            UITextEffectsWindow *keyboardWindow = [UITextEffectsWindow sharedTextEffectsWindow];
            keyboardWindow.transform = CGAffineTransformMakeRotation(-M_PI / 2);
            keyboardWindow.bounds = [[UIScreen mainScreen] bounds];
            keyboardWindow.frame = keyboardWindow.bounds;
            break;
        }
        case UIInterfaceOrientationLandscapeRight:
        {
            UITextEffectsWindow *keyboardWindow = [UITextEffectsWindow sharedTextEffectsWindow];
            keyboardWindow.transform = CGAffineTransformMakeRotation(M_PI / 2);
            keyboardWindow.bounds = [[UIScreen mainScreen] bounds];
            keyboardWindow.frame = keyboardWindow.bounds;
            break;
        }
        default:
            break;
    }
    
    [fbChatView updateChatHeadsLocationForRotation];
}

// For now, manually refresh Chat Heads in background, doesn't seem to be super power intensive

CHOptimizedMethod4(self, id, FBChatHeadViewController, initWithThreadViewControllerProvider, id, threadViewControllerProvider, surfaceViewProvider, id, provider, threadListControllerProvider, id, provider3, navigator, id, navigator)
{
    id hax = CHSuper4(FBChatHeadViewController, initWithThreadViewControllerProvider, threadViewControllerProvider, surfaceViewProvider, provider, threadListControllerProvider, provider3, navigator, navigator);
    fbChatHeadViewController = hax;
    
    [self performSelector:@selector(createRefreshTimer) withObject:nil afterDelay:30];
    return hax;
}

// Both these methods use OpenGL for the blurred profile picture on the contact page, so disable if the app is suspended

CHOptimizedMethod3(self, void, FBMThreadDetailContactHeaderView, _setCoverPhotoTo, id, to, animated, BOOL, animated, fadeGradient, BOOL, gradient)
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        CHSuper3(FBMThreadDetailContactHeaderView, _setCoverPhotoTo, to, animated, animated, fadeGradient, gradient);
    }
}

CHOptimizedMethod2(self, void, FBMThreadDetailContactHeaderView, _setCoverPhotoToBlurred, id, blurred, animated, BOOL, animated)
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        CHSuper2(FBMThreadDetailContactHeaderView, _setCoverPhotoToBlurred, blurred, animated, animated);
    }
}


// If any windows are added, make sure their contexts still stay rendered when suspended

CHOptimizedMethod0(self, void, UIWindow, makeKeyAndVisible)
{
    CHSuper0(UIWindow, makeKeyAndVisible);
    
    DebugLog(@"FACEBOOK LAUNCH HOOKED");
    
    [UIWindow setAllWindowsKeepContextInBackground:YES];
}

static void fbShouldRotate(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationPortrait;
    
    DebugLog(@"FACEBOOK SHOULD ACTUALLY ROTATE");
    
    if ([(__bridge NSString *)name isEqualToString:@ROTATION_PORTRAIT_UPSIDEDOWN_NOTIFICATION])
    {
        newOrientation = UIInterfaceOrientationPortraitUpsideDown;
    }
    else if ([(__bridge NSString *)name isEqualToString:@ROTATION_LANDSCAPE_LEFT_NOTIFICATION])
    {
        newOrientation = UIInterfaceOrientationLandscapeLeft;
    }
    else if ([(__bridge NSString *)name isEqualToString:@ROTATION_LANDSCAPE_RIGHT_NOTIFICATION])
    {
        newOrientation = UIInterfaceOrientationLandscapeRight;
    }
    
    [fbChatHeadViewController forceRotationToInterfaceOrientation:newOrientation];
}

static void fbChatNotificationReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [fbChatHeadViewController enteredForeground];
}

static void messageBoxPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/ca.adambell.MessageBox.plist"];
    
    if (prefs != nil && prefs[@"refreshInterval"])
        refreshInterval = [prefs[@"refreshInterval"] doubleValue];

    DebugLog(@"PREFERENCES LOADED: %f, %@", refreshInterval, prefs);
    
    if (fbChatHeadViewController)
    {
        [fbChatHeadViewController performSelector:@selector(createRefreshTimer)];
    }
}

CHConstructor
{
    @autoreleasepool
    {
        // Don't want anything else (but Facebook) trying to use this
        
        if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.facebook.Facebook"])
            return;
        
        // <3 system wide notifications 
        CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(darwin, NULL, fbShouldRotate, CFSTR(ROTATION_PORTRAIT_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(darwin, NULL, fbShouldRotate, CFSTR(ROTATION_PORTRAIT_UPSIDEDOWN_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(darwin, NULL, fbShouldRotate, CFSTR(ROTATION_LANDSCAPE_LEFT_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(darwin, NULL, fbShouldRotate, CFSTR(ROTATION_LANDSCAPE_RIGHT_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(darwin, NULL, messageBoxPrefsChanged, CFSTR("ca.adambell.MessageBox-preferencesChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(darwin, NULL, fbChatNotificationReceived, CFSTR(PUSH_NOTIFICATION_RECEIVED), NULL, CFNotificationSuspensionBehaviorCoalesce);
        
        // Load preferences
        messageBoxPrefsChanged(nil, nil, nil, nil, nil);
        
        CHLoadLateClass(FBStackView);
        CHLoadLateClass(FBCoveringSplitView);
        CHLoadLateClass(FBDimmingView);
        CHLoadLateClass(FBChatHeadSurfaceView);
        CHLoadLateClass(AppDelegate);
        CHLoadLateClass(UIViewController);
        CHLoadLateClass(FBChatHeadViewController);
        CHLoadLateClass(FBMThreadDetailContactHeaderView);
        CHLoadLateClass(SPFilterBarView);
        CHLoadLateClass(FBMediaGalleryBottomBar);
        
        CHHook1(FBStackView, initWithFrame);
        CHHook1(FBCoveringSplitView, initWithFrame);
        CHHook1(FBDimmingView, initWithFrame);
        CHHook7(FBChatHeadSurfaceView, initWithFrame, chatHeadProvider, threadUserMap, participantFilter, threadSet, gatingChecker, appProperties);
        CHHook1(AppDelegate, applicationDidEnterBackground);
        CHHook1(AppDelegate, applicationWillEnterForeground);
        CHHook1(AppDelegate, applicationDidBecomeActive);
        CHHook4(FBChatHeadViewController, initWithThreadViewControllerProvider, surfaceViewProvider, threadListControllerProvider, navigator);
        CHHook3(FBMThreadDetailContactHeaderView, _setCoverPhotoTo, animated, fadeGradient);
        CHHook2(FBMThreadDetailContactHeaderView, _setCoverPhotoToBlurred, animated);
        CHHook1(SPFilterBarView, initWithFrame);
        CHHook1(FBMediaGalleryBottomBar, initWithFrame);
        CHHook0(UIWindow, makeKeyAndVisible);
    }
}
