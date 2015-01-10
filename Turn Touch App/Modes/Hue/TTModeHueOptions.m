//
//  TTModeHueOptions.m
//  Turn Touch App
//
//  Created by Samuel Clay on 1/8/15.
//  Copyright (c) 2015 Turn Touch. All rights reserved.
//

#import "TTModeHueOptions.h"
#import "TTModeHueConnect.h"
#import "TTModeHueConnecting.h"
#import "TTModeHueConnected.h"

@interface TTModeHueOptions ()

@property (nonatomic, strong) PHBridgePushLinkViewController *pushLinkViewController;
@property (nonatomic, strong) PHBridgeSearching *bridgeSearch;
@property (nonatomic, strong) TTModeHueConnect *connectViewController;
@property (nonatomic, strong) TTModeHueConnecting *connectingViewController;
@property (nonatomic, strong) TTModeHueConnected *connectedViewController;
@property (nonatomic, strong) TTModeHuePushlink *pushlinkViewController;

@end

@implementation TTModeHueOptions

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.phHueSDK = [[PHHueSDK alloc] init];
    [self.phHueSDK startUpSDK];
    [self.phHueSDK enableLogging:YES];
    
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    
    /***************************************************
     The SDK will send the following notifications in response to events:
     
     - LOCAL_CONNECTION_NOTIFICATION
     This notification will notify that the bridge heartbeat occurred and the bridge resources cache data has been updated
     
     - NO_LOCAL_CONNECTION_NOTIFICATION
     This notification will notify that there is no connection with the bridge
     
     - NO_LOCAL_AUTHENTICATION_NOTIFICATION
     This notification will notify that there is no authentication against the bridge
     *****************************************************/
    
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(notAuthenticated) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];

    // No Hue found, show connection button
    [self showStoppedViewWithText:NSLocalizedString(@"Connect to your Hue...", @"Searching for bridges text")];
}


- (void)showStoppedViewWithText:(NSString*)message {
    [self drawConnectViewController];
    
    [self.connectViewController setStoppedWithMessage:message];
}

- (void)showLoadingViewWithText:(NSString*)message {
    [self drawConnectViewController];
    
    NSLog(@"Connect frame: %@", NSStringFromRect(self.connectViewController.view.frame));
    [self.connectViewController setLoadingWithMessage:message];
}

- (void)clearViewConnectrollers {
    if (self.connectViewController) {
        [self.connectViewController.view removeFromSuperview];
        self.connectViewController = nil;
    }
    if (self.connectingViewController) {
        [self.connectingViewController.view removeFromSuperview];
        self.connectingViewController = nil;
    }
    if (self.connectedViewController) {
        [self.connectedViewController.view removeFromSuperview];
        self.connectedViewController = nil;
    }
    if (self.pushLinkViewController) {
        [self.pushLinkViewController.view removeFromSuperview];
        self.pushLinkViewController = nil;
    }
}

- (void)drawViewController:(TTOptionsDetailViewController *)viewController {
    [self.view addSubview:viewController.view];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:viewController.view
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:viewController.view
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:viewController.view
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:viewController.view
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0 constant:0]];
}

- (void)drawConnectViewController {
    [self clearViewConnectrollers];
    self.connectViewController = [[TTModeHueConnect alloc]
                                  initWithNibName:@"TTModeHueConnect"
                                  bundle:[NSBundle mainBundle]];
    [self drawViewController:self.connectViewController];
}

- (void)drawConnectingViewController {
    [self clearViewConnectrollers];
    self.connectingViewController = [[TTModeHueConnecting alloc]
                                     initWithNibName:@"TTModeHueConnecting"
                                     bundle:[NSBundle mainBundle]];
    [self drawViewController:self.connectingViewController];
}

- (void)drawConnectedViewController {
    [self clearViewConnectrollers];
    self.connectedViewController = [[TTModeHueConnected alloc]
                                    initWithNibName:@"TTModeHueConnected"
                                    bundle:[NSBundle mainBundle]];
    [self drawViewController:self.connectedViewController];
}

- (void)drawPushlinkViewController {
    [self clearViewConnectrollers];
    self.pushlinkViewController = [[TTModeHuePushlink alloc]
                                    initWithNibName:@"TTModeHuePushlink"
                                    bundle:[NSBundle mainBundle]];
    [self drawViewController:self.pushlinkViewController];
}

#pragma mark - HueSDK

/**
 Notification receiver for successful local connection
 */
- (void)localConnection {
    // Check current connection state
    [self checkConnectionState];
}

/**
 Notification receiver for failed local connection
 */
- (void)noLocalConnection {
    // Check current connection state
    [self checkConnectionState];
}

/**
 Notification receiver for failed local authentication
 */
- (void)notAuthenticated {
    /***************************************************
     We are not authenticated so we start the authentication process
     *****************************************************/
    
    /***************************************************
     doAuthentication will start the push linking
     *****************************************************/
    
    // Start local authenticion process
    [self performSelector:@selector(doAuthentication) withObject:nil afterDelay:0.5];
}

/**
 Checks if we are currently connected to the bridge locally and if not, it will show an error when the error is not already shown.
 */
- (void)checkConnectionState {
    if (!self.phHueSDK.localConnected) {
        //        if (self.noConnectionAlert == nil) {
        // Show popup
        [self showNoConnectionDialog];
        //        }
    }
    else {
        // One of the connections is made, remove popups and loading views
        //        [self hideCurrentSheetWindow];
    }
}

/**
 Shows the first no connection alert
 */
- (void)showNoConnectionDialog {
    NSLog(@"Connection to bridge lost!");
}

/**
 Shows the no bridges found alert
 */
- (void)showNoBridgesFoundDialog {
    NSLog(@"Could not find bridge!");
    [self drawConnectViewController];
    [self.connectViewController setStoppedWithMessage:NSLocalizedString(@"Could not find any Hue bridges", @"Connecting text")];
}

/**
 Shows the not authenticated alert
 */
- (void)showNotAuthenticatedDialog{
    NSLog(@"Pushlink button not pressed within 30 sec!");
}

#pragma mark - Bridge searching and selection

/**
 Search for bridges using UPnP and portal discovery, shows results to user or gives error when none found.
 */
- (void)searchForBridgeLocal {
    // Stop heartbeats
    [self disableLocalHeartbeat];
    
    // Remove currently showing popups, loading sheets or other screens
    //    [self hideCurrentSheetWindow];
    
    // Show search screen
    //    [self showLoadingViewWithText:NSLocalizedString(@"Searching for bridges...", @"Searching for bridges text")];
    /***************************************************
     A bridge search is started using UPnP to find local bridges
     *****************************************************/
    
    // Start search
    [self drawConnectingViewController];    
    
    self.bridgeSearch = [[PHBridgeSearching alloc] initWithUpnpSearch:YES andPortalSearch:YES andIpAdressSearch:NO];
    [self.bridgeSearch startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
        
        // Done with search, remove loading sheet view
        //        [self hideCurrentSheetWindow];
        
        /***************************************************
         The search is complete, check whether we found a bridge
         *****************************************************/
        
        // Check for results
        if (bridgesFound.count > 0) {
            [self drawPushlinkViewController];
            NSString *macAddress = [[bridgesFound allKeys] objectAtIndex:0];
            NSString *ipAddress = [bridgesFound objectForKey:macAddress];
            [self.phHueSDK setBridgeToUseWithIpAddress:ipAddress macAddress:macAddress];
        }
        else {
            /***************************************************
             No bridge was found was found. Tell the user and offer to retry..
             *****************************************************/
            
            // No bridges were found, show this to the user
            [self showNoBridgesFoundDialog];
        }
    }];
    
}

/**
 Delegate method for PHbridgeSelectionViewController which is invoked when a bridge is selected
 */
- (void)bridgeSelectedWithIpAddress:(NSString *)ipAddress andMacAddress:(NSString *)macAddress {
    /***************************************************
     Removing the selection view controller takes us to
     the 'normal' UI view
     *****************************************************/
    //    [self hideCurrentSheetWindow];
    
    // Show a connecting loading sheet while we try to connect to the bridge
    [self drawConnectingViewController];
    
    // Set SDK to use bridge and our default username (which should be the same across all apps, so pushlinking is only required once)
    
    /***************************************************
     Set the username, ipaddress and mac address,
     as the bridge properties that the SDK framework will use
     *****************************************************/
    
    [self.phHueSDK setBridgeToUseWithIpAddress:ipAddress macAddress:macAddress];
    
    /***************************************************
     Setting the hearbeat running will cause the SDK
     to regularly update the cache with the status of the
     bridge resources
     *****************************************************/
    
    // Start local heartbeat again
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}

#pragma mark - Heartbeat control

/**
 Starts the local heartbeat with a 10 second interval
 */
- (void)enableLocalHeartbeat {
    /***************************************************
     The heartbeat processing collects data from the bridge
     so now try to see if we have a bridge already connected
     *****************************************************/
    
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil) {
        // Hide sheet if there is any
        //        [self hideCurrentSheetWindow];
        
        // Show a connecting sheet while we try to connect to the bridge
        [((TTModeHueOptions *)appDelegate.panelController.backgroundView.optionsView.modeOptionsViewController) showLoadingViewWithText:NSLocalizedString(@"Connecting...", @"Connecting text")];
        
        // Enable heartbeat with interval of 10 seconds
        [self.phHueSDK enableLocalConnection];
    } else {
        // Automaticly start searching for bridges
        [self searchForBridgeLocal];
    }
}

/**
 Stops the local heartbeat
 */
- (void)disableLocalHeartbeat {
    [self.phHueSDK disableLocalConnection];
}

#pragma mark - Bridge authentication

/**
 Start the local authentication process
 */
- (void)doAuthentication {
    // Disable heartbeats
    [self disableLocalHeartbeat];
    
    // Remove loading sheet view
    //    [self hideCurrentSheetWindow];
    
    /***************************************************
     To be certain that we own this bridge we must manually
     push link it. Here we display the view to do this.
     *****************************************************/
    
    // Create an interface for the pushlinking
    self.pushLinkViewController = [[PHBridgePushLinkViewController alloc] initWithNibName:@"PHBridgePushLinkViewController" bundle:[NSBundle mainBundle] delegate:self];
    
    [self.view addSubview:self.pushLinkViewController.view];
    
    /***************************************************
     Start the push linking process.
     *****************************************************/
    
    // Start pushlinking when the interface is shown
    [self.pushLinkViewController startPushLinking];
}

/**
 Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was successfull
 */
- (void)pushlinkSuccess {
    /***************************************************
     Push linking succeeded we are authenticated against
     the chosen bridge.
     *****************************************************/
    
    // Remove pushlink view controller
    //    [self hideCurrentSheetWindow];
    
    // Start local heartbeat
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}

/**
 Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was not successfull
 */
- (void)pushlinkFailed:(PHError *)error {
    // Remove pushlink view controller
    //    [self hideCurrentSheetWindow];
    
    // Check which error occured
    if (error.code == PUSHLINK_NO_CONNECTION) {
        // No local connection to bridge
        [self noLocalConnection];
        
        // Start local heartbeat (to see when connection comes back)
        [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
    }
    else {
        // Bridge button not pressed in time
        [self showNotAuthenticatedDialog];
    }
}

@end
