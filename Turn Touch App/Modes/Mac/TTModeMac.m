//
//  TTModeMac.m
//  Turn Touch App
//
//  Created by Samuel Clay on 12/23/13.
//  Copyright (c) 2013 Turn Touch. All rights reserved.
//
#import <AudioToolbox/AudioServices.h>
#include <ApplicationServices/ApplicationServices.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import "TTModeMac.h"
#include <sys/sysctl.h>

@implementation TTModeMac

@dynamic volume;

- (id)init {
    if (self = [super init]) {
        self->turnedOffMonitor = NO;
    }
    return self;
}

+ (NSString *)title {
    return @"Mac OS";
}

+ (NSString *)description {
    return @"System-level controls";
}

+ (NSString *)imageName {
    NSString *machineModel = [[self class] machineModel];
    
    if ([machineModel rangeOfString:@"MacBook"].location != NSNotFound) {
        return @"macbookpro.png";
    }

    return @"imac.png";
}

- (NSString *)titleNorth {
    return @"Volume Up";
}

- (NSString *)titleEast {
    return @"Turn off screen";
}

- (NSString *)titleWest {
    return @"Mute";
}

- (NSString *)titleSouth {
    return @"Volume Down";
}

- (void)runNorth {
    [self setVolume:[self volume] + 0.1];
}
- (void)runSouth {
    [self setVolume:[self volume] - 0.1];
}
- (void)runWest {
    BOOL v = [self isMuted];
    if (v) {
        [self setVolume:self.volume];
    } else {
        [self setVolume:0];
    }
}

- (void)runEast {
    if ([self isDisplayOff]) {
        [self switchDisplay:YES];
    } else {
        [self switchDisplay:NO];
    }
}

+(NSString *) machineModel
{
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    
    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    
    return @"Just an Apple Computer"; //incase model name can't be read
}

- (float)volume {
    Float32 outputVolume;
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    
    // Get the default device
    AudioDeviceID outputDeviceID = [self defaultOutputDeviceID];
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown default device");
        return 0.0f;
    }
    
    // See if the device has a virtual master
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0f;
    }
    
    // Read the volume
    propertySize = (UInt32) sizeof(Float32);
    status = AudioHardwareServiceGetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, &propertySize, &outputVolume);
    
    // Check success
    if (status) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0f;
    }
    
    // Clamp it to [0,1]
    if (outputVolume < 0.0f) return 0.0f;
    if (outputVolume > 1.0f) return 1.0f;
    
    return outputVolume;
}

- (void)setVolume:(float)newVolume {
    // Clamp it to [0,1]
    if (newVolume < 0.0f) newVolume = 0.0f;
    if (newVolume > 1.0f) newVolume = 1.0f;
    
    // Set up the change request
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    
    // If the new volume is very low, just mute
    if (newVolume < 0.001) {
        NSLog(@"Muting audio");
        propertyAOPA.mSelector = kAudioDevicePropertyMute;
    }	else {
        NSLog(@"Setting audio volume to %d%%", (int) (newVolume * 100.0));
        propertyAOPA.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
    }
    
    // Get the default audio device
    AudioDeviceID outputDeviceID = [self defaultOutputDeviceID];
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown default audio device");
        return;
    }
    
    // Check that the device has a virtual master volume
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"Device 0x%0x does not support volume control", outputDeviceID);
        return;
    }
    
    // Check that we can set the volume
    // TODO: If we're trying to mute and it's not supported, try just setting the volume
    Boolean canSetVolume = NO;
    status = AudioHardwareServiceIsPropertySettable(outputDeviceID, &propertyAOPA, &canSetVolume);
    
    if (status || canSetVolume == NO)	{
        NSLog(@"Device 0x%0x does not support volume control", outputDeviceID);
        return;
    }
    
    if (propertyAOPA.mSelector == kAudioDevicePropertyMute) {
        // Request setting the muted state
        propertySize = (UInt32) sizeof(UInt32);
        UInt32 mute = 1;
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &mute);
    } else {
        // Request setting the volume
        propertySize = (UInt32) sizeof(Float32);
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &newVolume);
        
        if (status) {
            NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
        }
        
        // make sure we're not muted
        propertyAOPA.mSelector = kAudioDevicePropertyMute;
        propertySize = (UInt32) sizeof(UInt32);
        UInt32 mute = 0;
        if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
            NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
            return;
        }
        
        // Check that we can set volume to non-muted
        Boolean canSetMute = NO;
        status = AudioHardwareServiceIsPropertySettable(outputDeviceID, &propertyAOPA, &canSetMute);
        if (status || !canSetMute) {
            NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
            return;
        }
        
        // Set device unmuted
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &mute);
	}
    
    if (status) {
        NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
    }
}

- (BOOL)isMuted {
    bool muted;
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mSelector = kAudioDevicePropertyMute;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    
    // Get the default device
    AudioDeviceID outputDeviceID = [self defaultOutputDeviceID];
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown default device");
        return 0.0f;
    }
    
    // See if the device has a virtual master
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0f;
    }
    
    // Read the volume
    propertySize = (UInt32) sizeof(bool);
    status = AudioHardwareServiceGetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, &propertySize, &muted);
    
    // Check success
    if (status) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0f;
    }
    
    return muted;
}

- (AudioDeviceID)defaultOutputDeviceID {
    AudioDeviceID	outputDeviceID = kAudioObjectUnknown;
    
    // Prepare the request
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    
    // Check that we can read the default output device
    if (!AudioHardwareServiceHasProperty(kAudioObjectSystemObject, &propertyAOPA)) {
        NSLog(@"Cannot find default output device!");
        return outputDeviceID;
    }
    
    // Send the request to get the default device
    propertySize = (UInt32) sizeof(AudioDeviceID);
    status = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject,
                                                 &propertyAOPA, 0, NULL, &propertySize, &outputDeviceID);
    if (status) {
        NSLog(@"Cannot find default output device!");
    }
    return outputDeviceID;
}

- (BOOL)isDisplayOff {
    boolean_t displayOff = CGDisplayIsAsleep(CGMainDisplayID());
    boolean_t displayActive = CGDisplayIsOnline(CGMainDisplayID());
    NSLog(@"display: %d/%d", displayOff, displayActive);
    return (BOOL)displayOff || self->turnedOffMonitor;
}

- (void)switchDisplay:(BOOL)turnOn {
    io_registry_entry_t r =
    IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (!r || r == MACH_PORT_NULL) return;

    CGDirectDisplayID display = CGMainDisplayID();
    const double kMyFadeTime = 1.0; /* fade time in seconds */
    const int kMyFadeSteps = 100;
    const double kMyFadeInterval = (kMyFadeTime / (double) kMyFadeSteps);
    const useconds_t kMySleepTime = (1000000 * kMyFadeInterval); /* delay in microseconds */
    int step;
    double fade;
    CGGammaValue redMin, redMax, redGamma,
    greenMin, greenMax, greenGamma,
    blueMin, blueMax, blueGamma;
    CGError err;
    err = CGGetDisplayTransferByFormula (display,
                                         &redMin, &redMax, &redGamma,
                                         &greenMin, &greenMax, &greenGamma,
                                         &blueMin, &blueMax, &blueGamma);
    
    if (turnOn) {
        NSLog(@"Turning on.");
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanFalse);
        UpdateSystemActivity(OverallAct);
        
        // Turn to black before fade in
        err = CGSetDisplayTransferByFormula (display,
                                             redMin, 0, redGamma,
                                             greenMin, 0, greenGamma,
                                             blueMin, 0, blueGamma);
        
        // Fade in
        for (step = 0; step < kMyFadeSteps*2; ++step) {
            fade = (step / ((double)kMyFadeSteps*2));
            err = CGSetDisplayTransferByFormula (display,
                                                 redMin, fade*redMax, redGamma,
                                                 greenMin, fade*greenMax, greenGamma,
                                                 blueMin, fade*blueMax, blueGamma);
            usleep (kMySleepTime);
        }
        self->turnedOffMonitor = NO;
    } else {
        NSLog(@"Turning off.");
        
        // Fade out before turning off screen
        for (step = 0; step < kMyFadeSteps; ++step) {
            fade = 1.0 - (step / (double)kMyFadeSteps);
            err = CGSetDisplayTransferByFormula (display,
                                                 redMin, fade*redMax, redGamma,
                                                 greenMin, fade*greenMax, greenGamma,
                                                 blueMin, fade*blueMax, blueGamma);
            usleep (kMySleepTime);
        }
        
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);

        self->turnedOffMonitor = YES;
    }
    
    IOObjectRelease(r);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        CGDisplayRestoreColorSyncSettings();
    });
}

@end
