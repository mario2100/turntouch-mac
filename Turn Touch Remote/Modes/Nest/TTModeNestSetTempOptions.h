//
//  TTModeNestSetTemperatureOptions.h
//  Turn Touch Remote
//
//  Created by Samuel Clay on 1/19/16.
//  Copyright © 2016 Turn Touch. All rights reserved.
//

#import "TTOptionsDetailViewController.h"

@interface TTModeNestSetTempOptions : TTOptionsDetailViewController

@property (nonatomic) IBOutlet NSPopUpButton *thermostatPopup;
@property (nonatomic) IBOutlet NSTextField *labelTemp;
@property (nonatomic) IBOutlet NSSlider *sliderTemp;

- (IBAction)didChangeThermostat:(id)sender;

@end