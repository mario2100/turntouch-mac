//
//  TTOptionsViewController.h
//  Turn Touch App
//
//  Created by Samuel Clay on 1/8/15.
//  Copyright (c) 2015 Turn Touch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TTAppDelegate.h"
#import "TTTabView.h"

@class TTAppDelegate;

@interface TTOptionsDetailViewController : NSViewController {
    TTAppDelegate *appDelegate;
}

@property (nonatomic) IBOutlet TTTabView *tabView;
@property (nonatomic) TTMenuType menuType;

@end
