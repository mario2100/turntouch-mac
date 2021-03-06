//
//  TTButtonTimer.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 11/1/13.
//  Copyright (c) 2013 Turn Touch. All rights reserved.
//

#import "TTButtonTimer.h"
#import "TTModeMap.h"

#define DEBUG_BUTTON_STATE 1

@implementation TTButtonTimer

@synthesize pairingActivatedCount;
@synthesize previousButtonState;
@synthesize skipButtonActions;
@synthesize menuState;

- (id)init {
    if (self = [super init]) {
        appDelegate = (TTAppDelegate *)[NSApp delegate];
        previousButtonState = [[TTButtonState alloc] init];
        pairingActivatedCount = [[NSNumber alloc] init];
        menuHysteresis = NO;
    }
    
    return self;
}

- (uint8_t)buttonDownStateFromData:(NSData *)data {
    return ~(*(int *)[[data subdataWithRange:NSMakeRange(0, 1)] bytes]) & 0x0F;
}

- (uint8_t)doubleStateFromData:(NSData *)data {
    uint8_t state = ~(*(int *)[[data subdataWithRange:NSMakeRange(0, 1)] bytes]);
    return state >> 4;
}

- (int)heldStateFromData:(NSData *)data {
    return *(int *)[[data subdataWithRange:NSMakeRange(1, 1)] bytes];
}

- (void)readBluetoothData:(NSData *)data {
    uint8_t state = [self buttonDownStateFromData:data];
    uint8_t doubleState = [self doubleStateFromData:data];
    BOOL heldState = [self heldStateFromData:data] == 0xFF;
    NSInteger buttonLifted = -1;
    
    TTButtonState *latestButtonState = [[TTButtonState alloc] init];
    latestButtonState.north = !!(state & (1 << 0));
    latestButtonState.east = !!(state & (1 << 1));
    latestButtonState.west = !!(state & (1 << 2));
    latestButtonState.south = !!(state & (1 << 3));

#if DEBUG_BUTTON_STATE
    NSLog(@" ---> Bluetooth data: %@ (%d/%d/%d) was:%@ is:%@", data, doubleState, state, heldState, previousButtonState, latestButtonState);
#endif
    
    // Figure out which buttons are held and lifted
    NSInteger i = latestButtonState.count;
    while (i--) {
        if (![previousButtonState state:i] && [latestButtonState state:i]) {
            // Press button down

        } else if ([previousButtonState state:i] && ![latestButtonState state:i]) {
            // Lift button
            buttonLifted = i;
        } else {
            // Button remains pressed down

        }
    }
    
    BOOL anyButtonHeld = !latestButtonState.inMultitouch && !menuHysteresis && heldState;
    BOOL anyButtonPressed = !menuHysteresis && latestButtonState.anyPressedDown;
    BOOL anyButtonLifted = !previousButtonState.inMultitouch && !menuHysteresis && buttonLifted >= 0;
    
    if (anyButtonHeld) {
        // Hold button
#if DEBUG_BUTTON_STATE
        NSLog(@" ---> Hold button");
#endif
        previousButtonState = latestButtonState;
        menuState = TTHUDMenuStateHidden;
        
        if (state == 0x01) {
            // Don't fire action on button release
            previousButtonState.north = NO;
            [self activateMode:NORTH];
        } else if (state == 0x02) {
            previousButtonState.east = NO;
            [self activateMode:EAST];
        } else if (state == 0x04) {
            previousButtonState.west = NO;
            [self activateMode:WEST];
        } else if (state == 0x08) {
            previousButtonState.south = NO;
            [self activateMode:SOUTH];
        }
        [self activateButton:NO_DIRECTION];
    } else if (anyButtonPressed) {
        // Press down button
#if DEBUG_BUTTON_STATE
        NSLog(@" ---> Button down%@", previousButtonState.inMultitouch ? @" (multi-touch)" : @"");
#endif
        previousButtonState = latestButtonState;

        if (latestButtonState.inMultitouch) {
            if (!holdToastStart && !menuHysteresis && menuState == TTHUDMenuStateHidden) {
                holdToastStart = [NSDate date];
                menuHysteresis = YES;
                menuState = TTHUDMenuStateActive;
                [appDelegate.hudController activateHudMenu];
            } else if (menuState == TTHUDMenuStateActive && !menuHysteresis) {
                menuHysteresis = YES;
                menuState = TTHUDMenuStateHidden;
                [self releaseToastActiveMode];
            }
            [self activateButton:NO_DIRECTION];
        } else if (menuState == TTHUDMenuStateActive) {
            if ((state & 0x01) == 0x01) {
                [self fireMenuButton:NORTH];
            } else if ((state & 0x02) == 0x02) {
                // Not on button down, wait for button up
//                [self fireMenuButton:EAST];
            } else if ((state & 0x04) == 0x04) {
//                [self fireMenuButton:WEST];
            } else if ((state & 0x08) == 0x08) {
                [self fireMenuButton:SOUTH];
            } else if (state == 0x00) {
                [self activateButton:NO_DIRECTION];
            }
        } else {
            if ((state & 0x01) == 0x01) {
                [self activateButton:NORTH];
            } else if ((state & 0x02) == 0x02) {
                [self activateButton:EAST];
            } else if ((state & 0x04) == 0x04) {
                [self activateButton:WEST];
            } else if ((state & 0x08) == 0x08) {
                [self activateButton:SOUTH];
            } else if (state == 0x00) {
                [self activateButton:NO_DIRECTION];
            }
        }
    } else if (anyButtonLifted) {
        // Press up button
#if DEBUG_BUTTON_STATE
        NSLog(@" ---> Button up%@: %ld", previousButtonState.inMultitouch ? @" (multi-touch)" : @"", (long)buttonLifted);
#endif
        previousButtonState = latestButtonState;

        TTModeDirection buttonPressedDirection;
        switch (buttonLifted) {
            case 0:
                buttonPressedDirection = NORTH;
                break;
            case 1:
                buttonPressedDirection = EAST;
                break;
            case 2:
                buttonPressedDirection = WEST;
                break;
            case 3:
                buttonPressedDirection = SOUTH;
                break;
                
            default:
                buttonPressedDirection = NO_DIRECTION;
                break;
        }
        
        if (menuState == TTHUDMenuStateActive) {
            if (buttonPressedDirection == NORTH) {
//                [self fireMenuButton:NORTH];
            } else if (buttonPressedDirection == EAST) {
                [self fireMenuButton:EAST];
            } else if (buttonPressedDirection == WEST) {
                [self fireMenuButton:WEST];
            } else if (buttonPressedDirection == SOUTH) {
//                [self fireMenuButton:SOUTH];
            } else if (state == 0x00) {
                [self activateButton:NO_DIRECTION];
            }
        } else if (doubleState == 0xF &&
            lastButtonPressedDirection != NO_DIRECTION &&
            buttonPressedDirection == lastButtonPressedDirection &&
            [[NSDate date] timeIntervalSinceDate:lastButtonPressStart] < DOUBLE_CLICK_ACTION_DURATION) {
            // Check for double click and setup double click timer
            // Double click detected
            [self fireDoubleButton:buttonPressedDirection];
            lastButtonPressedDirection = NO_DIRECTION;
            lastButtonPressStart = nil;
        } else if (doubleState != 0xF && doubleState != 0x0) {
            // Firmware v3+ has hardware support for double-click
            [self fireDoubleButton:buttonPressedDirection];
        } else {
            lastButtonPressedDirection = buttonPressedDirection;
            lastButtonPressStart = [NSDate date];
            
            [self fireButton:buttonPressedDirection];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DOUBLE_CLICK_ACTION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                lastButtonPressedDirection = NO_DIRECTION;
                lastButtonPressStart = nil;
            });
        }
    } else if (!latestButtonState.anyPressedDown) {
#if DEBUG_BUTTON_STATE
        NSLog(@" ---> Nothing pressed%@: %d (lifted: %ld)", latestButtonState.inMultitouch ? @" (multi-touch)" : @"", state, buttonLifted);
#endif
        BOOL inMultitouch = previousButtonState.inMultitouch;
        previousButtonState = latestButtonState;

        if (!inMultitouch && buttonLifted >= 0 && menuHysteresis) {
            [self releaseToastActiveMode];
        } else if (menuState == TTHUDMenuStateHidden) {
            [self releaseToastActiveMode];
        }
        [self activateButton:NO_DIRECTION];
        menuHysteresis = NO;
        holdToastStart = nil;
    }
    
#if DEBUG_BUTTON_STATE
    NSLog(@"Buttons: %d: %@", state, previousButtonState);
#endif
}

- (void)releaseToastActiveMode {
    [appDelegate.hudController releaseToastActiveMode];

    holdToastStart = nil;
}

- (void)activateMode:(TTModeDirection)direction {
//    NSLog(@"Selecting mode: %d", activeModeDirection);
    [appDelegate.modeMap switchMode:direction modeName:nil];
    
    [appDelegate.hudController holdToastActiveMode:YES];

    NSString *soundFile = [[NSBundle mainBundle]
                           pathForResource:[NSString stringWithFormat:@"%@ tone",
                                            direction == NORTH ? @"north" :
                                            direction == EAST ? @"east" :
                                            direction == WEST ? @"west" :
                                            @"south"] ofType:@"wav"];
    NSSound *sound = [[NSSound alloc]
                      initWithContentsOfFile:soundFile
                      byReference: YES];
    
//    [sound setDelegate:self];
    [sound play];
}

- (void)activateButton:(TTModeDirection)direction {
//    NSLog(@"Activating button: %d", activeModeDirection);
    NSString *actionName = [appDelegate.modeMap.selectedMode actionNameInDirection:direction];
    [appDelegate.modeMap setActiveModeDirection:direction];
    [appDelegate.hudController holdToastActiveAction:actionName inDirection:direction];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    CGFloat deviceInterval = [[preferences objectForKey:@"TT:firmware:interval_max"] integerValue] / 1000.f;
    CGFloat modeChangeDuration = [[preferences objectForKey:@"TT:firmware:mode_duration"] floatValue] / 1000.f;
    CGFloat buttonHoldTimeInterval = MAX(MIN(.15f, modeChangeDuration*0.3f), deviceInterval * 1.05f);
//    NSLog(@"Mode change duration (%f): %f -- %f", buttonHoldTimeInterval, modeChangeDuration*.3f, deviceInterval*1.05f);
    if (direction != NO_DIRECTION) {
#ifndef SKIP_BUTTON_ACTIONS
        if (!skipButtonActions) {
            [appDelegate.modeMap maybeFireActiveButton];
        }
#endif
        NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:buttonHoldTimeInterval];
        activeModeTimer = [[NSTimer alloc]
                           initWithFireDate:fireDate
                           interval:0
                           target:self
                           selector:@selector(activeModeTimerFire:)
                           userInfo:@{@"activeModeDirection": [NSNumber numberWithInt:direction]}
                           repeats:NO];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:activeModeTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)fireMenuButton:(TTModeDirection)direction {
    [appDelegate.hudController.modeHUDController runDirection:direction];
}

- (void)fireButton:(TTModeDirection)direction {
#ifndef SKIP_BUTTON_ACTIONS
    if (!skipButtonActions) {
        [appDelegate.modeMap runActiveButton];
    }
#endif
    [appDelegate.modeMap setActiveModeDirection:NO_DIRECTION];

    NSString *actionName = [appDelegate.modeMap.selectedMode actionNameInDirection:direction];
    [appDelegate.hudController toastActiveAction:actionName inDirection:direction];

    [self cancelModeTimer];
//    NSLog(@"Firing button: %@", [appDelegate.modeMap directionName:direction]);
}

- (void)fireDoubleButton:(TTModeDirection)direction {
    if (direction == NO_DIRECTION) return;

#ifndef SKIP_BUTTON_ACTIONS
    if (!skipButtonActions) {
        [appDelegate.modeMap runDoubleButton:direction];
    }
#endif

    [appDelegate.modeMap setActiveModeDirection:NO_DIRECTION];
    
    NSString *actionName = [appDelegate.modeMap.selectedMode actionNameInDirection:direction];
    [appDelegate.hudController toastDoubleAction:actionName inDirection:direction];

    [self cancelModeTimer];
}

- (void)cancelModeTimer {
    [activeModeTimer invalidate];
    activeModeTimer = nil;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [appDelegate.hudController hideModeTease];
    });
}

- (void)activeModeTimerFire:(NSTimer *)timer {
//    NSLog(@"Firing active mode timer: %d", appDelegate.modeMap.activeModeDirection);
    activeModeTimer = nil;
    TTModeDirection timerDirection = (TTModeDirection)[[timer.userInfo objectForKey:@"activeModeDirection"]
                                      integerValue];
//    NSLog(@" --> Teasing direction: %@ (%@)", [appDelegate.modeMap directionName:timerDirection], [appDelegate.modeMap directionName:appDelegate.modeMap.activeModeDirection]);
    if (appDelegate.modeMap.activeModeDirection == timerDirection) {
//        [appDelegate.hudController teaseMode:timerDirection];
    }
}

#pragma mark - HUD Menu

- (void)closeMenu {
    if (menuState != TTHUDMenuStateHidden) {
        menuState = TTHUDMenuStateHidden;
        [previousButtonState clearState];
    }
}

#pragma mark - Pairing

- (void)resetPairingState {
    pairingButtonState = [[TTButtonState alloc] init];
}

- (void)readBluetoothDataDuringPairing:(NSData *)data {
    uint8_t state = [self buttonDownStateFromData:data];
    pairingButtonState.north |= !!(state & (1 << 0));
    pairingButtonState.east |= !!(state & (1 << 1));
    pairingButtonState.west |= !!(state & (1 << 2));
    pairingButtonState.south |= !!(state & (1 << 3));
    [self setValue:@([pairingButtonState activatedCount]) forKey:@"pairingActivatedCount"];
    
    if ((state & (1 << 0)) == (1 << 0)) {
        [appDelegate.modeMap setActiveModeDirection:NORTH];
    } else if ((state & (1 << 1)) == (1 << 1)) {
        [appDelegate.modeMap setActiveModeDirection:EAST];
    } else if ((state & (1 << 2)) == (1 << 2)) {
        [appDelegate.modeMap setActiveModeDirection:WEST];
    } else if ((state & (1 << 3)) == (1 << 3)) {
        [appDelegate.modeMap setActiveModeDirection:SOUTH];
    } else {
        [appDelegate.modeMap setActiveModeDirection:NO_DIRECTION];
    }
}

- (BOOL)isDevicePaired {
    return pairingActivatedCount.integerValue == pairingButtonState.count;
}

- (BOOL)isDirectionPaired:(TTModeDirection)direction {
    switch (direction) {
        case NORTH:
            return pairingButtonState.north;
            
        case EAST:
            return pairingButtonState.east;
            
        case WEST:
            return pairingButtonState.west;
            
        case SOUTH:
            return pairingButtonState.south;
            
        default:
            break;
    }
    
    return NO;
}

@end
