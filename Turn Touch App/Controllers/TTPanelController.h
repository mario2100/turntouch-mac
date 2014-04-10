//
//  TTPanelController.h
//  Turn Touch App
//
//  Created by Samuel Clay on 8/20/13.
//  Copyright (c) 2013 Turn Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTBackgroundView.h"
#import "TTStatusItemView.h"
#import "TTPanelDelegate.h"

#pragma mark -

@class TTBackgroundView;

@interface TTPanelController : NSWindowController <NSWindowDelegate> {
    BOOL _hasActivePanel;
    __unsafe_unretained TTBackgroundView *_backgroundView;
    __unsafe_unretained id<TTPanelControllerDelegate> _delegate;
}

@property (nonatomic, unsafe_unretained) IBOutlet TTBackgroundView *backgroundView;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<TTPanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<TTPanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
- (void)resize;

@end
