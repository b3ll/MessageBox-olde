//
//  ABViewController.m
//  MessageBox
//
//  Created by Adam Bell on 2013-04-13.
//  Copyright (c) 2013 Adam Bell. All rights reserved.
//

#import "ABMessageBoxWindow.h"


@interface ABMessageBoxWindow ()

@end

@implementation ABMessageBoxWindow

- (id)init
{
    self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self)
    {
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
    }
    
    return self;
}

+ (id)sharedInstance
{
    static dispatch_once_t p = 0;
    
    __strong static id _sharedSelf = nil;
    
    dispatch_once(&p, ^{
        _sharedSelf = [[self alloc] init];
    });
    
    return _sharedSelf;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    //forward touches to everything beneath this window, unless a touch falls upon something within this windows subviews
    
    if (![[super hitTest:point withEvent:event] isKindOfClass:[ABMessageBoxWindow class]])
    {
        return [super hitTest:point withEvent:event];
    }
    else
    {
        return nil;
    }
}

@end
