//
//  ABMessageBox_Facebook.h
//  MessageBox
//
//  Created by Adam Bell on 2013-04-24.
//  Copyright (c) 2013 Adam Bell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABMessageBox.h"

@interface FBDimmingView : UIView
- (void)setBackgroundAlpha:(CGFloat)alpha;
@end

@interface FBChatHeadSurfaceView : UIView
- (void)animateStackToPoint:(id)point point:(CGPoint)point2;
- (void)moveChatHeadsToStackedLayout;
- (void)moveChatHeadsToLineLayout;
- (void)moveStackToHomeLocation;
- (CGPoint)nearestMagnetLocationForPoint:(CGPoint)point;
-(void)updateChatHeadsLocationForRotation;

@property(strong, nonatomic) NSMutableArray* chatHeadViews;
@end

@interface FBChatHeadView : UIView
-(void)animateToPoint:(CGPoint)point velocity:(CGPoint)velocity completion:(id)completion;
@end

@interface FBChatHeadViewController : UIViewController
- (void)refreshChatHeadThreadList;
- (void)dismissPopoverAnimated:(BOOL)animated;
- (void)createRefreshTimer;
- (void)stopRefreshTimer;
- (void)enteredForeground;
@end

@interface FBChatHeadViewController (forceRotation)
- (void)forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation;
@end

@interface FBMThreadDetailContactHeaderView : UIView
-(void)_setCoverPhotoTo:(id)to animated:(BOOL)animated fadeGradient:(BOOL)gradient;
-(void)_setCoverPhotoToBlurred:(id)blurred animated:(BOOL)animated;
@end

@interface UIDevice (forceOrientation)
- (void)setOrientation:(UIInterfaceOrientation)orientation;
@end

@interface UIWindow (forceRotation)
- (void)_setRotatableViewOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration force:(BOOL)force;
@end

@interface UITextEffectsWindow : UIWindow
+ (id)sharedTextEffectsWindow;
@end

@interface ABMessageBox_Facebook : NSObject

@end