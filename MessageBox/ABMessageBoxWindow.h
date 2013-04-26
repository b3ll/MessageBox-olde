//
//  ABViewController.h
//  MessageBox
//
//  Created by Adam Bell on 2013-04-13.
//  Copyright (c) 2013 Adam Bell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABMessageBoxWindow : UIWindow
{

}

+ (id)sharedInstance;

@property (nonatomic, assign) UIWindow *subWindow;

@end
