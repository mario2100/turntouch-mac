//
//  TTModeNestSetTemperatureOptions.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 1/19/16.
//  Copyright © 2016 Turn Touch. All rights reserved.
//

#import "TTModeNestSetTempOptions.h"
#import "TTModeNest.h"
#import "NestThermostatManager.h"

@interface TTModeNestSetTempOptions ()

@end

@implementation TTModeNestSetTempOptions

@synthesize thermostatPopup;
@synthesize labelTemp;
@synthesize sliderTemp;
@synthesize heatControl;
@synthesize heatControlWidth;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSInteger temperature = [[self.action optionValue:kNestSetTemperature
                                          inDirection:appDelegate.modeMap.inspectingModeDirection] integerValue];
    NSString *temperatureMode = [self.action optionValue:kNestSetTemperatureMode
                                             inDirection:appDelegate.modeMap.inspectingModeDirection];
    
    if ([temperatureMode isEqualToString:@"cool"]) {
        [heatControl setSelectedSegment:1];
    } else {
        [heatControl setSelectedSegment:0];
    }
    
    [self updateScale];
    [self updateTempLabel];
    [self selectThermostat];

    [sliderTemp setIntegerValue:temperature];
}

- (void)updateScale {
    TTModeNest *nestMode = (TTModeNest *)self.action.mode;
    Thermostat *thermostat = [nestMode selectedThermostat];
    NSString *scale = [thermostat temperatureScale];

    if ([scale isEqualToString:@"C"]) {
        sliderTemp.minValue = 9;
        sliderTemp.maxValue = 32;
    } else {
        sliderTemp.minValue = 50;
        sliderTemp.maxValue = 90;
    }
}

- (void)updateTempLabel {
    NSInteger temperature = [[self.action optionValue:kNestSetTemperature
                                          inDirection:appDelegate.modeMap.inspectingModeDirection] integerValue];
    
    TTModeNest *nestMode = (TTModeNest *)self.action.mode;
    Thermostat *thermostat = [nestMode selectedThermostat];
    NSString *scale = [thermostat temperatureScale];
    if ([scale isKindOfClass:[NSNull class]] || !scale || !scale.length) {
        scale = @"";
    }
    [labelTemp setStringValue:[NSString stringWithFormat:@"%ld°%@",
                               temperature, scale]];
    
    if ([thermostat.hvacMode isEqualToString:@"heat-cool"]) {
        heatControl.hidden = NO;
        [heatControlWidth setActive:NO];
    } else {
        heatControl.hidden = YES;
        [heatControlWidth setActive:YES];
    }
}

- (IBAction)changeTempSlider:(id)sender {
    [self.action changeActionOption:kNestSetTemperature
                                 to:[NSNumber numberWithInteger:sliderTemp.integerValue]];
    [self updateTempLabel];
}

- (IBAction)changeHeatControl:(id)sender {
    [self.action changeActionOption:kNestSetTemperatureMode to:(heatControl.selectedSegment == 1 ? @"cool" : @"heat")];
}

- (void)selectThermostat {
    NSString *thermostatSelectedIdentifier = [appDelegate.modeMap mode:self.action.mode
                                                     actionOptionValue:kNestThermostat
                                                           inDirection:appDelegate.modeMap.inspectingModeDirection];
    NSString *thermostatSelected;
    NSMutableArray *thermostats = [NSMutableArray array];
    [thermostatPopup removeAllItems];
    TTModeNest *modeNest = (TTModeNest *)self.action.mode;
    for (Thermostat *thermostat in [modeNest.currentStructure objectForKey:@"thermostats"]) {
        if (!thermostat.thermostatId || !thermostat.nameLong) return; // Thermostats not yet loaded, wait for delegate call
        [thermostats addObject:@{@"name": thermostat.nameLong, @"identifier": thermostat.thermostatId}];
    }
    
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [thermostats sortUsingDescriptors:@[sd]];
    
    for (NSDictionary *thermostatData in thermostats) {
        [thermostatPopup addItemWithTitle:thermostatData[@"name"]];
        if ([thermostatData[@"identifier"] isEqualToString:thermostatSelectedIdentifier]) {
            thermostatSelected = thermostatData[@"name"];
        }
    }
    if (thermostatSelected) {
        [thermostatPopup selectItemWithTitle:thermostatSelected];
    }
}

- (void)didChangeThermostat:(id)sender {
    
}

@end
