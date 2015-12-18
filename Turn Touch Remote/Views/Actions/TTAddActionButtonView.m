//
//  TTActionAddView.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 12/17/15.
//  Copyright © 2015 Turn Touch. All rights reserved.
//

#import "TTAddActionButtonView.h"
#import "TTChangeButtonView.h"

#define ADD_BUTTON_WIDTH 120

@implementation TTAddActionButtonView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        appDelegate = (TTAppDelegate *)[NSApp delegate];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        addButton = [[TTChangeButtonView alloc] init];
        [addButton setBorderRadius:12.f];
        [self setChangeButtonTitle:@"Add New"];
        [addButton setAction:@selector(showAddActionMenu:)];
        [addButton setTarget:self];
        NSString *imageFile = [NSString stringWithFormat:@"%@/icons/button_plus.png", [[NSBundle mainBundle] resourcePath]];
        NSImage *icon = [[NSImage alloc] initWithContentsOfFile:imageFile];
        [icon setSize:NSMakeSize(15, 10)];
        [addButton setImage:icon];
        [addButton setImagePosition:NSImageRight];
        [self addSubview:addButton];
        
        [self registerAsObserver];
    }
    
    return self;
}


#pragma mark - KVO

- (void)registerAsObserver {
    [appDelegate.modeMap addObserver:self forKeyPath:@"inspectingModeDirection"
                             options:0 context:nil];
}

- (void) observeValueForKeyPath:(NSString*)keyPath
                       ofObject:(id)object
                         change:(NSDictionary*)change
                        context:(void*)context {
    if ([keyPath isEqual:NSStringFromSelector(@selector(inspectingModeDirection))]) {
        if (appDelegate.modeMap.inspectingModeDirection == NO_DIRECTION) {
            // Only hide when switching modes (or closing actions), not when switching actions
            [self hideAddActionMenu:nil];
        }
    }
}

- (void)dealloc {
    [appDelegate.modeMap removeObserver:self forKeyPath:@"inspectingModeDirection"];
}

#pragma mark - Drawing

//- (void)adjustHeight {
//    [appDelegate.panelController.backgroundView toggleAddButtonView];
//}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [self drawBackground];
    [self drawAddButton];
}

- (void)drawBackground {
    [NSColorFromRGB(0xFFFFFF) set];
    NSRectFill(self.bounds);
}

- (void)drawAddButton {
    NSRect buttonFrame = NSMakeRect(NSWidth(self.frame)/2 - ADD_BUTTON_WIDTH/2,
                                    (NSHeight(self.frame)/2) - (24.f/2) - (8.f/2),
                                    ADD_BUTTON_WIDTH, 24.f);
    addButton.frame = buttonFrame;
}

- (void)setChangeButtonTitle:(NSString *)title {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]
                                                   initWithString:title attributes:nil];
    [addButton setAttributedTitle:attributedString];
}

- (IBAction)showAddActionMenu:(id)sender {
    [self setChangeButtonTitle:@"Cancel"];
    [addButton setAction:@selector(hideAddActionMenu:)];
    NSString *imageFile = [NSString stringWithFormat:@"%@/icons/button_x.png", [[NSBundle mainBundle] resourcePath]];
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:imageFile];
    [icon setSize:NSMakeSize(15, 10)];
    [addButton setImage:icon];
    [addButton setImagePosition:NSImageLeft];
    
    [appDelegate.modeMap setOpenedAddActionChangeMenu:YES];
}

- (IBAction)hideAddActionMenu:(id)sender {
    [self setChangeButtonTitle:@"Add New"];
    [addButton setAction:@selector(showAddActionMenu:)];
    NSString *imageFile = [NSString stringWithFormat:@"%@/icons/button_plus.png", [[NSBundle mainBundle] resourcePath]];
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:imageFile];
    [icon setSize:NSMakeSize(15, 10)];
    [addButton setImage:icon];
    [addButton setImagePosition:NSImageRight];

    [appDelegate.modeMap setOpenedAddActionChangeMenu:NO];
}

@end