//
//  TTPeripheralList.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 4/28/15.
//  Copyright (c) 2015 Turn Touch. All rights reserved.
//

#import "TTDeviceList.h"

@implementation TTDeviceList

@synthesize devices;

- (instancetype)init {
    if (self = [super init]) {
        devices = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSString *)description {
    NSMutableArray *peripheralIds = [NSMutableArray array];
    for (TTDevice *device in devices) {
        [peripheralIds addObject:[device.peripheral.identifier.UUIDString substringToIndex:8]];
    }
    return [NSString stringWithFormat:@"<%@>", [peripheralIds componentsJoinedByString:@", "]];
}

- (TTDevice *)deviceForPeripheral:(CBPeripheral *)peripheral {
    for (TTDevice *device in devices) {
        if (device.peripheral == peripheral) return device;
    }
    
    return nil;
}

- (TTDevice *)objectAtIndex:(NSUInteger)index {
    return [devices objectAtIndex:index];

    // Uncomment below to only use paired devices
//    for (int i=0; i < index; ) {
//        TTDevice *device = [devices objectAtIndex:i];
//        if (device.isPaired) {
//            if (i == index) return device;
//            i++;
//        }
//    }
//    
//    return nil;
}

#pragma mark - Devices

- (TTDevice *)addPeripheral:(CBPeripheral *)peripheral {
    TTDevice *device = [[TTDevice alloc] initWithPeripheral:peripheral];
    [self addDevice:device];
    
    return device;
}


- (void)addDevice:(TTDevice *)addDevice {
    for (TTDevice *device in devices) {
        if ([device.peripheral.identifier.UUIDString
             isEqualToString:addDevice.peripheral.identifier.UUIDString]) {
            NSLog(@"Already added device: %@ / %@ ... whatever", device, addDevice);
            addDevice = device;
//            [self removeDevice:device];
//            return;
        }
    }

    if (![devices containsObject:addDevice]) {
        [devices addObject:addDevice];
    } else {
        NSLog(@"Already added device and not adding again: %@", addDevice);
    }
    addDevice.isPaired = [self isDevicePaired:addDevice];
    addDevice.state = TTDeviceStateSearching;
}

- (void)removePeripheral:(CBPeripheral *)peripheral {
    TTDevice *device = [self deviceForPeripheral:peripheral];
    [self removeDevice:device];
}

- (void)removeDevice:(TTDevice *)removeDevice {
    NSMutableArray *updatedDevices = [[NSMutableArray alloc] init];
    for (TTDevice *device in devices) {
        if (device != removeDevice) {
            [updatedDevices addObject:device];
        } else if (device == removeDevice) {
            [device.peripheral setDelegate:nil];
            device.peripheral = nil;
            device.state = TTDeviceStateDisconnected;
        }
    }
    devices = updatedDevices;
    removeDevice = nil;
}

- (void)ensureDevicesConnected {
    NSMutableArray *updatedConnectedDevices = [[NSMutableArray alloc] init];
    
    // Counting paired devices
    for (TTDevice *device in devices) {
        if (device.peripheral.state == CBPeripheralStateDisconnected &&
            (device.state == TTDeviceStateConnected)) {
            device.isPaired = [self isDevicePaired:device];
            [device.peripheral setDelegate:nil];
            device.peripheral = nil;
        } else {
            [updatedConnectedDevices addObject:device];
        }
    }

    devices = updatedConnectedDevices;
}

- (TTDevice *)connectedDeviceAtIndex:(NSInteger)index {
    NSInteger i = 0;
    for (TTDevice *device in devices) {
        if (device.peripheral.state != CBPeripheralStateDisconnected &&
            (device.state == TTDeviceStateConnected || device.state == TTDeviceStateConnecting)) {
            if (i == index) return device;
            i++;
        }
    }
    return nil;
}

#pragma mark - Paired

- (BOOL)isPeripheralPaired:(CBPeripheral *)peripheral {
    if (!peripheral) return false;
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *pairedDevices = [preferences objectForKey:@"TT:devices:paired"];
    return [pairedDevices containsObject:peripheral.identifier.UUIDString];
}

- (BOOL)isDevicePaired:(TTDevice *)device {
    return [self isPeripheralPaired:device.peripheral];
}

#pragma mark - Counts

- (NSInteger)count {
    NSInteger count = [devices count];
    if (!count) return 0;
    return count;
}

- (NSInteger)visibleCount {
    NSInteger count = 0;
    for (TTDevice *device in devices) {
        if (device.peripheral.state != CBPeripheralStateDisconnected &&
            device.state != TTDeviceStateDisconnected &&
            (device.isPaired || device.isPairing)) {
            count++;
        }
    }
    return count;
}

- (NSInteger)connectedCount {
    NSInteger count = 0;
    for (TTDevice *device in devices) {
        if (device.peripheral.state != CBPeripheralStateDisconnected &&
            device.state == TTDeviceStateConnected) {
            count++;
        }
    }
    return count;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [devices countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSUInteger)totalPairedCount {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *pairedDevices = [preferences objectForKey:@"TT:devices:paired"];
    
    return [pairedDevices count];
}

- (NSUInteger)pairedConnectedCount {
    NSUInteger count = 0;
    
    for (TTDevice *device in devices) {
        if ([self isPeripheralPaired:device.peripheral] && device.state == TTDeviceStateConnected) {
            count++;
        }
    }
    
    return count;
}

- (NSArray *)nicknamedConnected {
    NSMutableArray *connectedDevices = [NSMutableArray array];
    
    for (TTDevice *device in devices) {
        if ([self isPeripheralPaired:device.peripheral] && device.state == TTDeviceStateConnected && device.nickname) {
            [connectedDevices addObject:device];
        }
    }
    
    return connectedDevices;
}

- (NSUInteger)unpairedCount {
    NSUInteger count = 0;
    
    for (TTDevice *device in devices) {
        if (![self isPeripheralPaired:device.peripheral]) {
            count++;
        }
    }
    
    return count;
}

- (NSUInteger)unpairedConnectedCount {
    NSUInteger count = 0;
    
    for (TTDevice *device in devices) {
        if (![self isPeripheralPaired:device.peripheral] && device.isNotified) {
            count++;
        }
    }
    
    return count;
}

@end
