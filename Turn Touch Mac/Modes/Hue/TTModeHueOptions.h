//
//  TTModeHueOptions.h
//  Turn Touch Remote
//
//  Created by Samuel Clay on 1/8/15.
//  Copyright (c) 2015 Turn Touch. All rights reserved.
//

#import "TTModeHue.h"
#import "TTOptionsDetailViewController.h"
#import "TTModeHueConnecting.h"
#import "TTModeHueConnected.h"
#import "TTModeHuePushlink.h"
#import "TTModeHueBridge.h"

@interface TTModeHueOptions : TTOptionsDetailViewController
<TTModeHueDelegate>

@property (nonatomic, strong) TTModeHue *modeHue;

@end
