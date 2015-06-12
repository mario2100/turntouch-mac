//
//  TTModeMenuCollectionView.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 5/6/14.
//  Copyright (c) 2014 Turn Touch. All rights reserved.
//

#import "TTModeMenuCollectionView.h"

@implementation TTModeMenuCollectionView

@synthesize menuType;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        appDelegate = (TTAppDelegate *)[NSApp delegate];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self setMaxNumberOfColumns:2];
    }
    
    return self;
}

- (void)setContent:(NSArray *)content withMenuType:(TTMenuType)_menuType {
    NSLog(@"Collection view: %d / %@", _menuType, content);
    menuType = _menuType;
    
    [super setContent:content];
}

@end
