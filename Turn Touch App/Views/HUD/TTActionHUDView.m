//
//  TTHUDView.m
//  Turn Touch App
//
//  Created by Samuel Clay on 12/4/14.
//  Copyright (c) 2014 Turn Touch. All rights reserved.
//

#import "TTActionHUDView.h"

@implementation TTActionHUDView

const CGFloat kMarginPct = .6f;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [self drawBackground];
}

- (void)drawBackground {
    NSScreen *screen = [[NSScreen screens] objectAtIndex:0];
    CGFloat margin = (screen.frame.size.width * kMarginPct) / 2;
    CGFloat width = screen.frame.size.width - margin*2;
    NSBezierPath *ellipse = [NSBezierPath bezierPath];
    [ellipse moveToPoint:NSMakePoint(margin, 0)];
    [ellipse lineToPoint:NSMakePoint(width/2 + margin, 200)];
    [ellipse lineToPoint:NSMakePoint(width + margin, 0)];
//    [ellipse moveToPoint:NSMakePoint(margin, -50)];
//    [ellipse curveToPoint:NSMakePoint(width, -50)
//            controlPoint1:NSMakePoint(margin, 250)
//            controlPoint2:NSMakePoint(width, 250)];
    [ellipse closePath];
    CGFloat alpha = 0.9f;
    [NSColorFromRGBAlpha(0xC0BCCF, alpha) setStroke];
    [ellipse stroke];
    NSGradient *borderGradient = [[NSGradient alloc]
                                  initWithStartingColor:NSColorFromRGBAlpha(0xffffff, alpha)
                                  endingColor:NSColorFromRGB(0xa7a7a7)];
    [borderGradient drawInBezierPath:ellipse angle:-90];
}

@end