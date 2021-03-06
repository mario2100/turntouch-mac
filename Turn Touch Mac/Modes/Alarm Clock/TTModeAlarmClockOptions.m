//
//  TTModeAlarmClockOptionsView.m
//  Turn Touch Remote
//
//  Created by Samuel Clay on 5/13/14.
//  Copyright (c) 2014 Turn Touch. All rights reserved.
//

#import "TTModeAlarmClockOptions.h"
#import "iTunes.h"
#import "TTModeAlarmClock.h"
#import "NSDate+Extras.h"

@implementation TTModeAlarmClockOptions

@synthesize boxOnetimeOptions;
@synthesize boxRepeatOptions;
@synthesize boxOnetimeConstraint;
@synthesize boxRepeatConstraint;
@synthesize segOnetimeControl;
@synthesize segRepeatControl;

@synthesize segRepeatDays;
@synthesize sliderRepeatTime;
@synthesize textRepeatTime;

@synthesize datePicker;
@synthesize sliderOnetimeTime;
@synthesize textOnetimeLabel;

@synthesize sliderAlarmDuration;
@synthesize sliderAlarmVolume;
@synthesize textAlarmDuration;
@synthesize textAlarmVolume;
@synthesize dropdowniTunesSources;
@synthesize checkboxShuffle;
@synthesize textTracksCount;
@synthesize previewAlarmButton;

NSUInteger const kRepeatHeight = 88;
NSUInteger const kOnetimeHeight = 68;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    BOOL repeatAlarmEnabled = [[NSAppDelegate.modeMap mode:self.mode optionValue:kRepeatAlarmEnabled] boolValue];
    NSInteger repeatAlarmTime = [[NSAppDelegate.modeMap mode:self.mode optionValue:kRepeatAlarmTime] integerValue];
    NSArray *repeatDays = [NSAppDelegate.modeMap mode:self.mode optionValue:kRepeatAlarmDays];
    BOOL onetimeAlarmEnabled = [[NSAppDelegate.modeMap mode:self.mode optionValue:kOnetimeAlarmEnabled] boolValue];
    NSDate *oneTimeAlarmDate = [NSAppDelegate.modeMap mode:self.mode optionValue:kOnetimeAlarmDate];
    NSInteger onetimeAlarmTime = [[NSAppDelegate.modeMap mode:self.mode optionValue:kOnetimeAlarmTime] integerValue];
    NSInteger alarmDuration = [[NSAppDelegate.modeMap mode:self.mode optionValue:kAlarmDuration] integerValue];
    NSInteger alarmVolume = [[NSAppDelegate.modeMap mode:self.mode optionValue:kAlarmVolume] integerValue];
    BOOL playlistShuffle = [[NSAppDelegate.modeMap mode:self.mode optionValue:kAlarmShuffle] boolValue];
    
    // Expand and size boxes for alarms
    [boxOnetimeConstraint     setConstant:onetimeAlarmEnabled ? kOnetimeHeight : 0];
    [boxOnetimeOptions      setAlphaValue:onetimeAlarmEnabled ? 1 : 0];
    [segOnetimeControl setSelectedSegment:onetimeAlarmEnabled ? 0 : 1];

    [boxRepeatConstraint     setConstant:repeatAlarmEnabled ? kRepeatHeight : 0];
    [boxRepeatOptions      setAlphaValue:repeatAlarmEnabled ? 1 : 0];
    [segRepeatControl setSelectedSegment:repeatAlarmEnabled ? 0 : 1];
    
    // Set repeat alarm days and time
    int i = 0;
    for (NSNumber *dayNumber in repeatDays) {
        BOOL dayOn = [dayNumber boolValue];
        [segRepeatDays setSelected:dayOn forSegment:i];
        i++;
    }
    [sliderRepeatTime setIntegerValue:repeatAlarmTime];
    
    // Set onetime alarm date and time
    datePicker.delegate = self;
    [datePicker sendActionOn:NSEventMaskLeftMouseDown];
    [datePicker setDateValue:oneTimeAlarmDate];
    [sliderOnetimeTime setIntegerValue:onetimeAlarmTime];
    
    // Set music/sounds options
    [sliderAlarmVolume setIntegerValue:alarmVolume];
    [sliderAlarmDuration setIntegerValue:alarmDuration];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, (unsigned long)NULL), ^{
        [self populateiTunesSources];
    });
    [checkboxShuffle setState:playlistShuffle];
    
    
    // Update all labels
    [self updateRepeatAlarmLabel];
    [self updateOnetimeAlarmLabel];
    [self updateAlarmSoundsLabels];
}

#pragma mark - Drawing controls

- (IBAction)changeSegOnetimeControl:(id)sender {
    [self animateBlock:^{
        if (segOnetimeControl.selectedSegment == 1) {
            [boxOnetimeConstraint animator].constant = 0;
            [boxOnetimeOptions animator].alphaValue = 0;
            [NSAppDelegate.modeMap changeMode:self.mode option:kOnetimeAlarmEnabled to:[NSNumber numberWithBool:NO]];
        } else {
            [boxOnetimeConstraint animator].constant = kOnetimeHeight;
            [boxOnetimeOptions animator].alphaValue = 1;
            [NSAppDelegate.modeMap changeMode:self.mode option:kOnetimeAlarmEnabled to:[NSNumber numberWithBool:YES]];
            [self setOneTimeDate];
        }
        [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
    }];

}

- (IBAction)changeSegRepeatControl:(id)sender {
    [self animateBlock:^{
        if (segRepeatControl.selectedSegment == 1) {
            [boxRepeatConstraint animator].constant = 0;
            [boxRepeatOptions animator].alphaValue = 0;
            [NSAppDelegate.modeMap changeMode:self.mode option:kRepeatAlarmEnabled to:[NSNumber numberWithBool:NO]];
        } else {
            [boxRepeatConstraint animator].constant = kRepeatHeight;
            [boxRepeatOptions animator].alphaValue = 1;
            [NSAppDelegate.modeMap changeMode:self.mode option:kRepeatAlarmEnabled to:[NSNumber numberWithBool:YES]];
        }
        [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
    }];
}

#pragma mark - Repeat alarm

- (IBAction)changeRepeatDays:(id)sender {
    NSUInteger i = 0;
    NSMutableArray *selectedDays = [[NSMutableArray alloc] init];
    while (i < segRepeatDays.segmentCount) {
        [selectedDays addObject:[NSNumber numberWithBool:[segRepeatDays isSelectedForSegment:i]]];
        i++;
    }
    [NSAppDelegate.modeMap changeMode:self.mode option:kRepeatAlarmDays to:selectedDays];
    [self updateRepeatAlarmLabel];
    [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
}

- (IBAction)changeRepeatTime:(id)sender {
    NSInteger alarmTime = MIN(287, [sliderRepeatTime integerValue]);
    [NSAppDelegate.modeMap changeMode:self.mode option:kRepeatAlarmTime to:[NSNumber numberWithInteger:alarmTime]];
    [self updateRepeatAlarmLabel];
    [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
}

- (void)updateRepeatAlarmLabel {
    NSInteger repeatAlarmTime = [[NSAppDelegate.modeMap mode:self.mode optionValue:kRepeatAlarmTime] integerValue];
    NSArray *repeatDays = [NSAppDelegate.modeMap mode:self.mode optionValue:kRepeatAlarmDays];
    NSInteger selectedDays = 0;
    NSInteger i = 0;
    while (i < [repeatDays count]) {
        if ([[repeatDays objectAtIndex:i] boolValue]) {
            selectedDays++;
        }
        i++;
    }
    
    NSDate *midnightToday = [NSDate midnightToday];
    NSTimeInterval timeInterval = repeatAlarmTime * 5 * 60;
    NSDate *time = [[NSDate alloc] initWithTimeInterval:timeInterval sinceDate:midnightToday];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSString *label = [NSString stringWithFormat:@"%@, %ld %@ a week", [dateFormatter stringFromDate:time], (long)selectedDays, selectedDays == 1 ? @"day" : @"days"];
    [textRepeatTime setStringValue:label];
}

#pragma mark - One Time alarm

- (void)setOneTimeDate {
    NSDate *midnightToday = [NSDate midnightToday];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *todayComponents = [gregorian components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:midnightToday];
    NSInteger theDay = [todayComponents day];
    NSInteger theMonth = [todayComponents month];
    NSInteger theYear = [todayComponents year];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:theDay];
    [components setMonth:theMonth];
    [components setYear:theYear];
    NSDate *thisDate = [gregorian dateFromComponents:components];
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    NSDate *nextDate = [gregorian dateByAddingComponents:offsetComponents toDate:thisDate options:0];
    
    [datePicker setDateValue:nextDate];

    [NSAppDelegate.modeMap changeMode:self.mode option:kOnetimeAlarmDate to:nextDate];
    [self updateOnetimeAlarmLabel];
    [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
}

- (IBAction)changeOnetimeDate:(id)sender {
    NSDate *onetimeDate = [datePicker dateValue];
    
    [NSAppDelegate.modeMap changeMode:self.mode option:kOnetimeAlarmDate to:onetimeDate];
    [self updateOnetimeAlarmLabel];
    [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
}

- (void)didSelectDate:(NSDate *)selectedDate {
    [self.datePicker.calendarPopover close];
    [datePicker setDateValue:selectedDate];
    [NSAppDelegate.modeMap changeMode:self.mode option:kOnetimeAlarmDate to:selectedDate];
    [self updateOnetimeAlarmLabel];
    [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
}

- (IBAction)changeOnetimeTime:(id)sender {
    NSInteger alarmTime = MIN(287, [sliderOnetimeTime integerValue]);
    
    [NSAppDelegate.modeMap changeMode:self.mode option:kOnetimeAlarmTime to:[NSNumber numberWithInteger:alarmTime]];
    [self updateOnetimeAlarmLabel];
    [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode activateTimers];
}

- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate *__autoreleasing *)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval {
    NSLog(@"proposed date: %@", aDatePickerCell);
}
- (void)updateOnetimeAlarmLabel {
    NSInteger onetimeAlarmTime = [[NSAppDelegate.modeMap mode:self.mode optionValue:kOnetimeAlarmTime] integerValue];
    NSDate *onetimeAlarmDate = [NSAppDelegate.modeMap mode:self.mode optionValue:kOnetimeAlarmDate];
    
    NSTimeInterval timeInterval = onetimeAlarmTime * 5 * 60;
    NSDate *alarmDate = [[NSDate alloc] initWithTimeInterval:timeInterval sinceDate:onetimeAlarmDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSTimeInterval diff = [alarmDate timeIntervalSinceDate:[NSDate date]];
    if (diff <= 59) {
        [textOnetimeLabel setStringValue:@"Alarm is in the past!"];
        return;
    }
    unsigned int unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay;
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags
                                                     fromDate:[NSDate date]
                                                       toDate:alarmDate options:0];
    NSString *relativeTimeUntilAlarm = @"";
    NSInteger days = [breakdownInfo day];
    NSInteger hours = [breakdownInfo hour];
    NSInteger minutes = [breakdownInfo minute];
    if (days) {
        relativeTimeUntilAlarm = [NSString stringWithFormat:@"%ld %@", days, days == 1 ? @"day" : @"days"];
    }
    if (hours) {
        relativeTimeUntilAlarm =  [relativeTimeUntilAlarm stringByAppendingString:
                                   [NSString stringWithFormat:@"%@%ld %@", days ? @", " : @"", hours, hours == 1 ? @"hour" : @"hours"]];
    }
    if (minutes) {
        relativeTimeUntilAlarm =  [relativeTimeUntilAlarm stringByAppendingString:
                                   [NSString stringWithFormat:@"%@%ld %@", hours || days ? @", " : @"", minutes, minutes == 1 ? @"minute" : @"minutes"]];
    }

    NSString *label = [NSString stringWithFormat:@"%@, in %@", [dateFormatter stringFromDate:alarmDate], relativeTimeUntilAlarm];
    [textOnetimeLabel setStringValue:label];
}

#pragma mark - Alarm sounds

- (void)updateAlarmSoundsLabels {
    NSInteger alarmDuration = MAX(1, [[NSAppDelegate.modeMap mode:self.mode optionValue:kAlarmDuration] integerValue]);
    NSInteger alarmVolume = [[NSAppDelegate.modeMap mode:self.mode optionValue:kAlarmVolume] integerValue];
    
    [textAlarmVolume setStringValue:[NSString stringWithFormat:@"%ld%%", alarmVolume]];
    [textAlarmDuration setStringValue:[NSString stringWithFormat:@"%ld min", alarmDuration]];
}

- (IBAction)changeAlarmDuration:(id)sender {
    [NSAppDelegate.modeMap changeMode:self.mode option:kAlarmDuration to:[NSNumber numberWithInteger:MAX(1, sliderAlarmDuration.integerValue)]];
    
    [self updateAlarmSoundsLabels];
}

- (IBAction)changeAlarmVolume:(id)sender {
    [NSAppDelegate.modeMap changeMode:self.mode option:kAlarmVolume to:[NSNumber numberWithInteger:sliderAlarmVolume.integerValue]];
    
    [self updateAlarmSoundsLabels];
}

- (iTunesLibraryPlaylist *)iTunesPlaylist:(NSString *)persistentId {
    SBElementArray *playlists = [TTModeAlarmClock userPlaylists];
    for (iTunesLibraryPlaylist *playlist in playlists) {
        if ([playlist.persistentID isEqualToString:persistentId]) {
            return playlist;
        }
    }
    return nil;
}

- (IBAction)changeiTunesSource:(id)sender {
    SBElementArray *playlists = [TTModeAlarmClock userPlaylists];
    NSInteger tag = dropdowniTunesSources.selectedItem.tag;
    NSInteger i = 0;
    iTunesUserPlaylist *selectedPlaylist;
    for (iTunesUserPlaylist *playlist in playlists) {
        i++;
        if (i == tag) {
            selectedPlaylist = playlist;
            break;
        }
    }
    
    [NSAppDelegate.modeMap changeMode:self.mode option:kAlarmPlaylist
                                            to:selectedPlaylist.persistentID];
    
    [self updateTracksCount:selectedPlaylist];
}

- (void)updateTracksCount:(iTunesPlaylist *)selectedPlaylist {
    if (!selectedPlaylist) {
        NSString *playlistPersistentId = [NSAppDelegate.modeMap mode:self.mode optionValue:kAlarmPlaylist];
        selectedPlaylist = [self iTunesPlaylist:playlistPersistentId];
    }
    NSInteger tracks = selectedPlaylist.tracks.count;
    [textTracksCount setStringValue:[NSString stringWithFormat:@"%ld %@",
                                     (long)tracks, tracks == 1 ? @"track" : @"tracks"]];
}

- (IBAction)changeShuffle:(id)sender {
    [NSAppDelegate.modeMap changeMode:self.mode option:kAlarmShuffle
                                            to:[NSNumber numberWithBool:checkboxShuffle.state]];
}

- (void)populateiTunesSources {
    NSString *selectedPlaylistId = (NSString *)[NSAppDelegate.modeMap mode:self.mode optionValue:kAlarmPlaylist];
    NSMenuItem *selectedMenuItem;
    SBElementArray *playlists = [TTModeAlarmClock userPlaylists];
    NSInteger tag = 0;
    iTunesUserPlaylist *selectedPlaylist;
    iTunesUserPlaylist *libraryPlaylist;
    NSMenuItem *libraryMenuItem;
    NSImage *image;
    NSMutableArray *menuItems = [NSMutableArray array];
    
    for (iTunesUserPlaylist *playlist in playlists) {
        tag++;
        if (!playlist.size) continue;
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        switch (playlist.specialKind) {
            case iTunesESpKLibrary:
                image = [NSImage imageNamed:@"itunes_library_icon"];
                break;
                
            case iTunesESpKMusic:
                image = [NSImage imageNamed:@"itunes_music_icon"];
                libraryPlaylist = playlist;
                libraryMenuItem = menuItem;
                break;
                
            case iTunesESpKGenius:
                image = [NSImage imageNamed:@"itunes_genius_icon"];
                break;
                
            case iTunesESpKBooks:
                image = [NSImage imageNamed:@"itunes_audiobook_icon"];
                break;
                
            case iTunesESpKPodcasts:
                image = [NSImage imageNamed:@"itunes_podcast_icon"];
                break;
                
            case iTunesESpKITunesU:
                image = [NSImage imageNamed:@"itunes_itunesu_icon"];
                break;
                
            case iTunesESpKMovies:
                image = [NSImage imageNamed:@"itunes_movies_icon"];
                break;
                
            case iTunesESpKTVShows:
                image = [NSImage imageNamed:@"itunes_tv_icon"];
                break;
            
            default:
//                NSLog(@"playlist.specialKind: %@", playlist.properties);
                if ([playlist smart]) {
                    image = [NSImage imageNamed:@"itunes_playlist_icon"];
                } else {
                    image = [NSImage imageNamed:@"itunes_library_icon"];
                }
                break;
        }
        [image setSize:NSMakeSize(16, 16)];
        menuItem.image = image;
        menuItem.title = playlist.name;
        menuItem.tag = tag;
        [menuItems addObject:menuItem];
        if ([playlist.persistentID isEqualToString:selectedPlaylistId]) {
            selectedMenuItem = menuItem;
            selectedPlaylist = playlist;
        }
    }
    
    if (!selectedPlaylistId) {
        selectedMenuItem = libraryMenuItem;
    }
    dispatch_async(dispatch_get_main_queue(), ^(void){
        for (NSMenuItem *menuItem in menuItems) {
            [dropdowniTunesSources.menu addItem:menuItem];
        }

        if (!selectedPlaylistId) {
            [NSAppDelegate.modeMap changeMode:self.mode option:kAlarmPlaylist to:libraryPlaylist.persistentID];
            [self updateTracksCount:libraryPlaylist];
        } else {
            [self updateTracksCount:selectedPlaylist];
        }

        [dropdowniTunesSources selectItem:selectedMenuItem];
        [dropdowniTunesSources setNeedsDisplay:YES];
    });
}

- (IBAction)previewAlarm:(id)sender {
    [(TTModeAlarmClock *)appDelegate.modeMap.selectedMode runAlarm];
}

@end
