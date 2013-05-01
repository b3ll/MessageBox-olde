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
CHDeclareClass(UIApplication);
CHDeclareClass(UIWindow);
CHDeclareClass(UITextEffectsWindow);
CHDeclareClass(MessageCell);
CHDeclareClass(FBTabBar);

@class FBChatHeadView;

static UIView *fbStackView;
static UIView *fbSplitView;
static FBChatHeadSurfaceView *fbChatView;
static FBDimmingView *fbDimmingView;
static FBChatHeadViewController *fbChatHeadViewController;
static FBTabBar *fbTabBar;
static NSTimeInterval refreshInterval = 15;
static BOOL usePushNotifications = YES;
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

// Needed hack because 3.5" devices

CHDeclareMethod0(void, FBChatHeadViewController, dismissPopoverInstantly)
{
    [fbChatHeadViewController dismissPopoverAnimated:NO];
    [(UIView *)[[fbChatHeadViewController valueForKey:@"_popover"] valueForKey:@"_popoverView"] setAlpha:1.0];
    
    // Some users reporting that orientation events mess up after a video is played
    
    UIInterfaceOrientation orientation = [UIDevice currentDevice].orientation;
    //[fbChatHeadViewController forceRotationToInterfaceOrientation:orientation];
}

//Convenience functions to show and hide chat heads (with and without animation)

static void ThrowChatHeadsOffscreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    // If there's a modal controller, dismiss it immediately 
    
    [fbChatHeadViewController dismissViewControllerAnimated:NO completion:nil];

    [(UIView *)[[fbChatHeadViewController valueForKey:@"_popover"] valueForKey:@"_popoverView"] setAlpha:0.0];
    
    if (fbChatView.chatHeadViews.count > 0)
    {
        FBChatHeadView *firstChatHeadView = fbChatView.chatHeadViews[0];
        CGPoint newPoint = [fbChatView nearestMagnetLocationForPoint:firstChatHeadView.frame.origin];
        newPoint.x += newPoint.x > fbChatView.center.x ? 100 : -100;
        
        for (FBChatHeadView *chatHeadView in fbChatView.chatHeadViews)
        {
            [chatHeadView animateToPoint:newPoint velocity:CGPointMake(1.0, 1.0) completion:nil];
        }
    }
    
    [fbChatHeadViewController dismissPopoverAnimated:NO];
    
    // Hack needed for 3.5" devices, no idea why it doesn't actually dismiss the popover sometimes...
    
    [fbChatHeadViewController performSelector:NSSelectorFromString(@"dismissPopoverInstantly") withObject:nil afterDelay:0.0];
}

static void PushChatHeadsOnscreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [fbChatView moveChatHeadsToStackedLayout];
    [fbChatView moveStackToHomeLocation];
}

static void PushChatHeadsOnscreenInstant(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if (fbChatView.chatHeadViews.count > 0)
    {
        for (FBChatHeadView *chatHeadView in fbChatView.chatHeadViews)
        {
            CGPoint newPoint = [fbChatView pointForChatHeadViewInStackMode:chatHeadView];
            [chatHeadView setCenter:newPoint];
        }
    }
}

CHOptimizedMethod2(self, void, AppDelegate, application, UIApplication *, application, didFinishLaunchingWithOptions, NSDictionary *, options)
{
    CHSuper2(AppDelegate, application, application, didFinishLaunchingWithOptions, options);
    
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"com.adambell.MessageBox.FBMessageCenter"];
    [center runServerOnCurrentThread];
    [center registerForMessageName:@"DismissChatHeadsIfNeeded" target:self selector:@selector(dismissChatHeadsIfNeeded)];
}

CHDeclareMethod0(NSDictionary *, AppDelegate, dismissChatHeadsIfNeeded) {
    
    BOOL wasNeeded = NO;
    
    //layoutMode: 0 = chat heads closed, 1 = chat heads open
    if (fbChatView.layoutMode == 1) {
        [fbChatView tappedCaptureView:nil];
        wasNeeded = YES;
    }
    
    return @{@"DismissWasNeeded": @(wasNeeded)};
}

CHOptimizedMethod1(self, void, AppDelegate, applicationDidEnterBackground, UIApplication *, app)
{
    notify_post("ca.adambell.MessageBox.fbQuitting");
    
    DebugLog(@"FACEBOOK ENTERED BACKGROUND");
    
    [UIWindow setAllWindowsKeepContextInBackground:YES];
    
    // Nicer way to get the chat heads out of the app
    // Throw them offscreen, and bring them back when the app is suspended
    
    ThrowChatHeadsOffscreen(nil, nil, nil, nil, nil);
    
    double delayInSeconds = 0.6;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        PushChatHeadsOnscreen(nil, nil, nil, nil, nil);
    });
    
    [self setChatHeadsAreIsolated:YES];
    
    CHSuper1(AppDelegate, applicationDidEnterBackground, app);
}

CHOptimizedMethod1(self, void, AppDelegate, applicationWillEnterForeground, UIApplication *, app)
{
    notify_post("ca.adambell.MessageBox.fbLaunching");
    
    DebugLog(@"FACEBOOK BECOMING ACTIVE");
    
    [self setChatHeadsAreIsolated:NO];
    
    CHSuper1(AppDelegate, applicationWillEnterForeground, app);
}

static BOOL chatHeadsAreIsolated = NO;
CHDeclareMethod1(void, AppDelegate, setChatHeadsAreIsolated, BOOL, isolated) {
    
    if (isolated == chatHeadsAreIsolated)
        return;
    
    chatHeadsAreIsolated = isolated;
    
    UIView *mainView = [[[UIApplication sharedApplication] delegate] window].subviews[0];
    [mainView setBackgroundColor:[UIColor clearColor]];
    
    [[[[UIApplication sharedApplication] delegate] window] setBackgroundColor:[UIColor clearColor]];
    [[[UIApplication sharedApplication] valueForKey:@"_statusBarWindow"] setAlpha:(chatHeadsAreIsolated ? 0.0f : 1.0f)];
    
    if (mainView.subviews.count > 1)
        [mainView.subviews[0] setHidden:chatHeadsAreIsolated];
    if (mainView.subviews.count > 2)
        [mainView.subviews[2] setHidden:chatHeadsAreIsolated];
    UIView *v = mainView.subviews[0];
    [v setBackgroundColor:[UIColor clearColor]];
    
    //fbStackView.hidden = NO;
    fbSplitView.hidden = chatHeadsAreIsolated;
    
    if (fbTabBar)
        fbTabBar.hidden = chatHeadsAreIsolated;
    
    //fbStackView.backgroundColor = [UIColor clearColor];
    //fbSplitView.backgroundColor = [UIColor clearColor];
    
    /*for (UIView *view in fbSplitView.subviews)
    {
        view.hidden = chatHeadsAreIsolated;
    }*/
}

CHOptimizedMethod1(self, void, UIApplication, _saveSnapshotWithName, NSString *, name) {
    
    if (chatHeadsAreIsolated == NO)
        return CHSuper1(UIApplication, _saveSnapshotWithName, name);
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [delegate setChatHeadsAreIsolated:NO];
    CHSuper1(UIApplication, _saveSnapshotWithName, name);
    [delegate setChatHeadsAreIsolated:YES];
}

// Open links in Safari, instead of the Facebook application if Chat Heads are outside the application

CHOptimizedMethod3(self, void, MessageCell, textView, id, view, linkTapped, id, tapped, text, id, text)
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        CHSuper3(MessageCell, textView, view, linkTapped, tapped, text, text);
    }
    else
    {
        [fbChatHeadViewController dismissPopoverAnimated:YES];
        CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"com.adambell.MessageBox.SBMessageCenter"];
        [center sendMessageName:@"openURL" userInfo:@{@"url": text}];
    }
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

// For users with the tab bar a/b testing

CHOptimizedMethod1(self, id, FBTabBar, initWithFrame, CGRect, frame)
{
    DebugLog(@"GOT TAB BAR");
    
    id hax = CHSuper1(FBTabBar, initWithFrame, frame);
    fbTabBar = hax;
    return hax;
}

CHDeclareMethod0(void, FBChatHeadViewController, createRefreshTimer)
{
    [self performSelector:@selector(stopRefreshTimer)];
    if (refreshInterval > 0)
    {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval
                                                        target:self
                                                      selector:@selector(enteredForeground)
                                                      userInfo:nil
                                                       repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:refreshTimer
                                     forMode:NSDefaultRunLoopMode];
    }
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


// If any windows are added, make sure their contexts still stay rendered when suspended

CHOptimizedMethod0(self, void, UIWindow, makeKeyAndVisible)
{
    CHSuper0(UIWindow, makeKeyAndVisible);
    
    DebugLog(@"FACEBOOK LAUNCH HOOKED");
    
    [UIWindow setAllWindowsKeepContextInBackground:YES];
}

// Tell SpringBoard when we tap a chat head

CHOptimizedMethod1(self, void, FBChatHeadSurfaceView, didTapChatHead, id, chatHead)
{
    CHSuper1(FBChatHeadSurfaceView, didTapChatHead, chatHead);
    notify_post("ca.adambell.MessageBox-didTapChatHeadNotification");
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
    [[[UIApplication sharedApplication] windows][1] setWindowLevel:10000];
}

static void messageBoxPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/ca.adambell.MessageBox.plist"];
    
    if (prefs != nil && prefs[@"refreshInterval"])
    {
        refreshInterval = [prefs[@"refreshInterval"] doubleValue];
    }
    
    if (prefs != nil && prefs[@"refreshInterval"])
    {
        usePushNotifications = [prefs[@"pushNotificationsEnabled"] boolValue];
    }
    
    refreshInterval *= usePushNotifications ? -1 : 1;

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
        CFNotificationCenterAddObserver(darwin, NULL, ThrowChatHeadsOffscreen, CFSTR("ca.adambell.MessageBox-throwChatHeadsOffscreen"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(darwin, NULL, PushChatHeadsOnscreen, CFSTR("ca.adambell.MessageBox-pushChatHeadsOnscreen"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(darwin, NULL, PushChatHeadsOnscreenInstant, CFSTR("ca.adambell.MessageBox-pushChatHeadsOnscreenInstant"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        
        // Load preferences
        messageBoxPrefsChanged(nil, nil, nil, nil, nil);
        
        CHLoadLateClass(FBStackView);
        CHLoadLateClass(FBCoveringSplitView);
        CHLoadLateClass(FBDimmingView);
        CHLoadLateClass(FBChatHeadSurfaceView);
        CHLoadLateClass(AppDelegate);
        CHLoadLateClass(UIApplication);
        CHLoadLateClass(UIViewController);
        CHLoadLateClass(FBChatHeadViewController);
        CHLoadLateClass(FBMThreadDetailContactHeaderView);
        CHLoadLateClass(SPFilterBarView);
        CHLoadLateClass(FBMediaGalleryBottomBar);
        CHLoadLateClass(MessageCell);
        CHLoadLateClass(FBTabBar);
        
        CHHook1(FBStackView, initWithFrame);
        CHHook1(FBCoveringSplitView, initWithFrame);
        CHHook1(FBDimmingView, initWithFrame);
        CHHook1(FBTabBar, initWithFrame);
        CHHook7(FBChatHeadSurfaceView, initWithFrame, chatHeadProvider, threadUserMap, participantFilter, threadSet, gatingChecker, appProperties);
        CHHook2(AppDelegate, application, didFinishLaunchingWithOptions);
        CHHook1(AppDelegate, applicationDidEnterBackground);
        CHHook1(AppDelegate, applicationWillEnterForeground);
        CHHook1(UIApplication, _saveSnapshotWithName);
        CHHook4(FBChatHeadViewController, initWithThreadViewControllerProvider, surfaceViewProvider, threadListControllerProvider, navigator);
        CHHook0(UIWindow, makeKeyAndVisible);
        CHHook1(FBChatHeadSurfaceView, didTapChatHead);
        CHHook3(MessageCell, textView, linkTapped, text);
    }
}
