//
//  TTDFUViewController.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 11/3/15.
//  Copyright © 2015 Turn Touch. All rights reserved.
//

#import "TTDFUViewController.h"
#import "SSZipArchive.h"
#import "UnzipFirmware.h"
#import "DFUHelper.h"
#include "DFUHelper.h"

@interface TTDFUViewController ()

/*!
 * This property is set when the device has been selected on the Scanner View Controller.
 */
@property (strong, nonatomic) CBPeripheral *selectedPeripheral;
@property (strong, nonatomic) DFUOperations *dfuOperations;
@property (strong, nonatomic) DFUHelper *dfuHelper;

@property BOOL isTransferring;
@property BOOL isTransfered;
@property BOOL isTransferCancelled;
@property BOOL isConnected;
@property BOOL isErrorKnown;

@end

@implementation TTDFUViewController

@synthesize selectedPeripheral;
@synthesize dfuOperations;

-(id)init {
    self = [super init];
    if (self) {
        PACKETS_NOTIFICATION_INTERVAL = [[[NSUserDefaults standardUserDefaults] valueForKey:@"dfu_number_of_packets"] intValue];
        NSLog(@"PACKETS_NOTIFICATION_INTERVAL %d",PACKETS_NOTIFICATION_INTERVAL);
        dfuOperations = [[DFUOperations alloc] initWithDelegate:self];
        self.dfuHelper = [[DFUHelper alloc] initWithData:dfuOperations];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    appDelegate = (TTAppDelegate *)[NSApp delegate];
}


-(void)performDFU {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self disableOtherButtons];
        //        uploadStatus.hidden = NO;
        //        progress.hidden = NO;
        //        progressLabel.hidden = NO;
        //        uploadButton.enabled = NO;
    });
    [self.dfuHelper checkAndPerformDFU];
}

- (void) clearUI {
    selectedPeripheral = nil;
}

-(void)disableOtherButtons {
    //    selectFileButton.enabled = NO;
    //    selectFileTypeButton.enabled = NO;
    //    connectButton.enabled = NO;
}

-(void)enableOtherButtons {
    //    selectFileButton.enabled = YES;
    //    selectFileTypeButton.enabled = YES;
    //    connectButton.enabled = YES;
}

-(void)enableUploadButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.dfuHelper.selectedFileSize > 0) {
            if ([self.dfuHelper isValidFileSelected]) {
                NSLog(@" valid file selected");
            } else {
                NSLog(@"Valid file not available in zip file");
                //                [Utility showAlert:[self.dfuHelper getFileValidationMessage]];
                return;
            }
        }
        if (self.dfuHelper.isDfuVersionExist) {
            if (selectedPeripheral && self.dfuHelper.selectedFileSize > 0 && self.isConnected && self.dfuHelper.dfuVersion > 1) {
                if ([self.dfuHelper isInitPacketFileExist]) {
                    //                    uploadButton.enabled = YES;
                }
                else {
                    //                    [Utility showAlert:[self.dfuHelper getInitPacketFileValidationMessage]];
                }
            }
            else {
                NSLog(@"cant enable Upload button");
            }
        }
        else {
            if (selectedPeripheral && self.dfuHelper.selectedFileSize > 0 && self.isConnected) {
                //                uploadButton.enabled = YES;
            }
            else {
                NSLog(@"cant enable Upload button");
            }
        }
        
    });
}

#pragma mark Device Selection Delegate

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral {
    selectedPeripheral = peripheral;
    [dfuOperations setCentralManager:manager];
    //    deviceName.text = peripheral.name;
    [dfuOperations connectDevice:peripheral];
}

#pragma mark File Selection Delegate

-(void)onFileSelected:(NSURL *)url {
    NSLog(@"onFileSelected");
    self.dfuHelper.selectedFileURL = url;
    if (self.dfuHelper.selectedFileURL) {
        NSLog(@"selectedFile URL %@",self.dfuHelper.selectedFileURL);
        NSString *selectedFileName = [[url path]lastPathComponent];
        NSData *fileData = [NSData dataWithContentsOfURL:url];
        self.dfuHelper.selectedFileSize = fileData.length;
        NSLog(@"fileSelected %@",selectedFileName);
        
        //get last three characters for file extension
        NSString *extension = [selectedFileName substringFromIndex: [selectedFileName length] - 3];
        NSLog(@"selected file extension is %@",extension);
        if ([extension isEqualToString:@"zip"]) {
            NSLog(@"this is zip file");
            self.dfuHelper.isSelectedFileZipped = YES;
            self.dfuHelper.isManifestExist = NO;
            [self.dfuHelper unzipFiles:self.dfuHelper.selectedFileURL];
        }
        else {
            self.dfuHelper.isSelectedFileZipped = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //            fileName.text = selectedFileName;
            //            fileSize.text = [NSString stringWithFormat:@"%lu bytes", (unsigned long)self.dfuHelper.selectedFileSize];
            [self enableUploadButton];
        });
    }
    else {
        //        [Utility showAlert:@"Selected file not exist!"];
    }
}


#pragma mark DFUOperations delegate methods

-(void)onDeviceConnected:(CBPeripheral *)peripheral {
    NSLog(@"onDeviceConnected %@",peripheral.name);
    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = NO;
    [self enableUploadButton];
}

-(void)onDeviceConnectedWithVersion:(CBPeripheral *)peripheral {
    NSLog(@"onDeviceConnectedWithVersion %@",peripheral.name);
    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = YES;
    [self enableUploadButton];
}

-(void)onDeviceDisconnected:(CBPeripheral *)peripheral {
    NSLog(@"device disconnected %@",peripheral.name);
    self.isTransferring = NO;
    self.isConnected = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.dfuHelper.dfuVersion != 1) {
            [self clearUI];
            
            self.isTransferCancelled = NO;
            self.isTransfered = NO;
            self.isErrorKnown = NO;
        }
        else {
            double delayInSeconds = 3.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [dfuOperations connectDevice:peripheral];
            });
            
        }
    });
}

-(void)onReadDFUVersion:(int)version {
    NSLog(@"onReadDFUVersion %d",version);
    self.dfuHelper.dfuVersion = version;
    NSLog(@"DFU Version: %d",self.dfuHelper.dfuVersion);
    if (self.dfuHelper.dfuVersion == 1) {
        [dfuOperations setAppToBootloaderMode];
    }
    [self enableUploadButton];
}

-(void)onDFUStarted {
    NSLog(@"onDFUStarted");
    self.isTransferring = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        //        uploadButton.enabled = YES;
        //        [uploadButton setTitle:@"Cancel" forState:UIControlStateNormal];
        //        NSString *uploadStatusMessage = [self.dfuHelper getUploadStatusMessage];
        //        if ([Utility isApplicationStateInactiveORBackground]) {
        //            [Utility showBackgroundNotification:uploadStatusMessage];
        //        } else {
        //            uploadStatus.text = uploadStatusMessage;
        //        }
    });
}

-(void)onDFUCancelled {
    NSLog(@"onDFUCancelled");
    self.isTransferring = NO;
    self.isTransferCancelled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enableOtherButtons];
    });
}

-(void)onSoftDeviceUploadStarted {
    NSLog(@"onSoftDeviceUploadStarted");
}

-(void)onSoftDeviceUploadCompleted {
    NSLog(@"onSoftDeviceUploadCompleted");
}

-(void)onBootloaderUploadStarted {
    NSLog(@"onBootloaderUploadStarted");
    dispatch_async(dispatch_get_main_queue(), ^{
        //        if ([Utility isApplicationStateInactiveORBackground]) {
        //            [Utility showBackgroundNotification:@"uploading bootloader ..."];
        //        }
        //        else {
        //            uploadStatus.text = @"uploading bootloader ...";
        //        }
    });
    
}

-(void)onBootloaderUploadCompleted {
    NSLog(@"onBootloaderUploadCompleted");
}

-(void)onTransferPercentage:(int)percentage {
    NSLog(@"onTransferPercentage %d",percentage);
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        //        progressLabel.text = [NSString stringWithFormat:@"%d %%", percentage];
        //        [progress setProgress:((float)percentage/100.0) animated:YES];
    });
}

-(void)onSuccessfulFileTranferred {
    NSLog(@"OnSuccessfulFileTransferred");
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isTransferring = NO;
        self.isTransfered = YES;
        //        NSString* message = [NSString stringWithFormat:@"%lu bytes transfered in %lu seconds", (unsigned long)dfuOperations.binFileSize, (unsigned long)dfuOperations.uploadTimeInSeconds];
        //        if ([Utility isApplicationStateInactiveORBackground]) {
        //            [Utility showBackgroundNotification:message];
        //        }
        //        else {
        //            [Utility showAlert:message];
        //        }
        
    });
}

-(void)onError:(NSString *)errorMessage {
    NSLog(@"OnError %@",errorMessage);
    self.isErrorKnown = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        //        [Utility showAlert:errorMessage];
        [self clearUI];
    });
}


@end