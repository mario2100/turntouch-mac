//
//  TTModeAlarmSnooze.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 5/14/14.
//  Copyright (c) 2014 Turn Touch. All rights reserved.
//

#import "TTModeAlarmSnoozeOptions.h"
#import "TTModeAlarmClock.h"

@implementation TTModeAlarmSnoozeOptions

@synthesize durationSlider;
@synthesize durationLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSInteger snoozeDuration = [[self.action optionValue:kAlarmSnoozeDuration inDirection:appDelegate.modeMap.inspectingModeDirection] integerValue];
    
    [durationSlider setIntegerValue:snoozeDuration];
    [self updateSnoozeDurationLabel];
}

- (void)updateSnoozeDurationLabel {
    NSInteger snoozeDuration = [[self.action optionValue:kAlarmSnoozeDuration inDirection:appDelegate.modeMap.inspectingModeDirection] integerValue];
    
    [durationLabel setStringValue:[NSString stringWithFormat:@"%ld min", (long)snoozeDuration]];
}

- (IBAction)slideDuration:(id)sender {
    [self.action changeActionOption:kAlarmSnoozeDuration to:[NSNumber numberWithInteger:durationSlider.integerValue]];
    
    [self updateSnoozeDurationLabel];
}

@end
