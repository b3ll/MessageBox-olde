//
//  ABMessageBox.h
//  MessageBox
//
//  Created by Adam Bell on 2013-04-24.
//  Copyright (c) 2013 Adam Bell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#import "ABMessageBoxWindow.h"
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#import <sys/sysctl.h>

#define XPC_CONNECTION_MACH_SERVICE_LISTENER (1<<0)
#define XPC_CONNECTION_MACH_SERVICE_PRIVILEGED (1<<1)
#define XPC_CONNECTION_MACH_SERVICE_NOT_SURE (1<<2)
#define XPC_CONNECTION_MACH_SERVICE_SPRINGBOARD_HAX (1<<3)

typedef NS_ENUM(NSUInteger, BKSProcessAssertionReason)
{
    kProcessAssertionReasonAudio = 1,
    kProcessAssertionReasonLocation,
    kProcessAssertionReasonExternalAccessory,
    kProcessAssertionReasonFinishTask,
    kProcessAssertionReasonBluetooth,
    kProcessAssertionReasonNetworkAuthentication,
    kProcessAssertionReasonBackgroundUI,
    kProcessAssertionReasonInterAppAudioStreaming,
    kProcessAssertionReasonViewServices
};


@interface CPDistributedMessagingCenter : NSObject
+ (CPDistributedMessagingCenter *)centerNamed:(NSString *)centerName;
- (BOOL)doesServerExist;
- (void)registerForMessageName:(NSString *)messageName target:(id)target selector:(SEL)action;
- (void)runServerOnCurrentThread;
- (NSDictionary *)sendMessageAndReceiveReplyName:(NSString *)messageName userInfo:(NSDictionary *)userInfo;
- (BOOL)sendMessageName:(NSString *)messageName userInfo:(NSDictionary *)userInfo;
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
@property (nonatomic) BOOL isEditing;
@end

@interface SBApplicationController : NSObject
-(id)applicationWithDisplayIdentifier:(NSString *)ident;
+(SBApplicationController *)sharedInstance;
@end

@interface SBAppContextHostManager : NSObject
- (void)disableHostingForRequester:(NSString *)requester;
@end

@interface SBApplication : NSObject
- (UIView *)contextHostViewForRequester:(NSString *)str enableAndOrderFront:(BOOL)um;
- (SBAppContextHostManager *)contextHostManager;
- (NSString *)bundleIdentifier;
@end

@interface SpringBoard : UIApplication
- (SBApplication *)_accessibilityFrontMostApplication;
@end

@interface BKProcessAssertion : NSObject
- (id)initWithReason:(unsigned int)arg1 identifier:(id)arg2;
- (void)setWantsForegroundResourcePriority:(BOOL)arg1;
- (void)setPreventThrottleDownCPU:(BOOL)arg1;
- (void)setPreventThrottleDownUI:(BOOL)arg1;
- (void)setPreventSuspend:(BOOL)arg1;
- (void)setAllowIdleSleepOverrideEnabled:(BOOL)arg1;
- (void)setPreventIdleSleep:(BOOL)arg1;
- (void)setFlags:(unsigned int)arg1;
- (void)invalidate;
@end

@interface BKSProcessAssertion : NSObject
+ (id)NameForReason:(unsigned int)arg1;
- (void)queue_notifyAssertionAcquired:(BOOL)arg1;
- (void)queue_updateAssertion;
- (void)queue_acquireAssertion;
- (void)queue_registerWithServer;
- (void)queue_invalidate:(BOOL)arg1;
- (void)invalidate;
- (void)setReason:(unsigned int)arg1;
- (void)setValid:(BOOL)arg1;
- (void)setFlags:(unsigned int)arg1;
- (int)valid;
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (id)initWithBundleIdentifier:(id)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (id)init;
@end

@interface UIWindow(additions)
+(void)setAllWindowsKeepContextInBackground:(BOOL)stuff;
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (void)hookFacebook;
@end


@interface ABMessageBox : NSObject

@end
