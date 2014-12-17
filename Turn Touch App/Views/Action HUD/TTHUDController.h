//
//  TTHUDController.h
//  Turn Touch App
//
//  Created by Samuel Clay on 12/4/14.
//  Copyright (c) 2014 Turn Touch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TTModeHUDWindowController.h"
#import "TTActionHUDWindowController.h"
#import "TTAppDelegate.h"

@class TTModeHUDWindowController;
@class TTActionHUDWindowController;

@interface TTHUDController : NSObject {
    TTAppDelegate *appDelegate;
}

@property (nonatomic) IBOutlet TTModeHUDWindowController *modeHUDController;
@property (nonatomic) IBOutlet TTActionHUDWindowController *actionHUDController;

- (void)toastActiveMode;
- (void)toastActiveAction;

@end