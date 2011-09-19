//
//  AutoUpdater.m
//  support
//
//  Created by Anatol Pomozov on 6/12/11.
//  Copyright 2011 fuse4x.org. All rights reserved.
//

#include <stdio.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSNumberFormatter.h>
#include <Foundation/NSException.h>
#include <CoreFoundation/CFUserNotification.h>
#include <AppKit/NSWorkspace.h>
#include <fuse/fuse_version.h>

const CFStringRef APPLICATION_NAME = CFSTR("org.fuse4x.autoupdater");
NSString* FEED_URL = @"http://fuse4x.org/updates/fuse4x.stable";
NSString* DOWNLOAD_URL = @"https://github.com/downloads/fuse4x/fuse4x/Fuse4X-%@.dmg";

NSString *parseVersion(NSString *content) {
    content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    return content;
}

// Returns [str1 compare:str2]
NSComparisonResult compareVersions(NSString *str1, NSString *str2) {
    NSArray *version1 = [str1 componentsSeparatedByString: @"."];
    NSArray *version2 = [str2 componentsSeparatedByString: @"."];

    if ([version1 count] > 3)
        [NSException raise:@"Invalid version" format:@"version '%@' is invalid", str1];
    if ([version2 count] > 3)
        [NSException raise:@"Invalid version" format:@"version '%@' is invalid", str2];

    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    for (int i = 0; i < [version1 count]; i++) {
        NSNumber *part1 = [f numberFromString: [version1 objectAtIndex:i]];
        NSNumber *part2 = [NSNumber numberWithInt:0];
        if ([version2 objectAtIndex:i] != NULL)
            part2 = [f numberFromString: [version2 objectAtIndex:i]];

        if (part1 == NULL)
            [NSException raise:@"Invalid version"  format:@"version '%@' is invalid", str1];
        if (part2 == NULL)
            [NSException raise:@"Invalid version" format:@"version '%@' is invalid", str2];

        NSComparisonResult result = [part1 compare:part2];
        if (result != NSOrderedSame)
            return result;
    }

    return NSOrderedSame;
}

bool isValidVersion(NSString *version) {
    if (version == NULL)
        return false;

    NSArray *array = [version componentsSeparatedByString: @"."];
    if ([array count] > 3)
        return false;

    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];

    for (id element in array) {
        NSNumber *part = [f numberFromString: element];

        if (part == NULL)
            return false;
    }

    return true;
}

int main(void)
{
    // TODO Check that another instance of autoupdater is not running

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSURL *url = [NSURL URLWithString:FEED_URL];
    NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:NULL];

    newVersion = parseVersion(newVersion);
    if (newVersion == NULL)
        return 0; // response is not properly formatted

    NSString *currentVersion = (NSString*)CFPreferencesCopyAppValue(CFSTR("skipVersion"), APPLICATION_NAME);
    if (!isValidVersion(currentVersion)) {
        currentVersion = @FUSE4X_VERSION;
    }

    if (compareVersions(currentVersion, @FUSE4X_VERSION) != NSOrderedDescending) {
        // If we have already newer version that skipped - remove the pref
        CFPreferencesSetAppValue(CFSTR("skipVersion"), NULL, APPLICATION_NAME);
        CFPreferencesAppSynchronize(APPLICATION_NAME);

        currentVersion = @FUSE4X_VERSION;
    }

    if(compareVersions(newVersion, currentVersion) == NSOrderedDescending) {
        CFOptionFlags response;
        CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(dictionary, kCFUserNotificationAlertHeaderKey, @"A new version of Fuse4X available");
        CFDictionarySetValue(dictionary, kCFUserNotificationAlertMessageKey, @"Generally it is a good idea to update Fuse4X. The new version adds more features, fixes bugs and provides the best possible user experience.");
        CFDictionarySetValue(dictionary, kCFUserNotificationAlternateButtonTitleKey, @"Skip this version");
        CFDictionarySetValue(dictionary, kCFUserNotificationOtherButtonTitleKey, @"Notify me later");
        CFDictionarySetValue(dictionary, kCFUserNotificationDefaultButtonTitleKey, @"Download It");

        CFUserNotificationRef notification = CFUserNotificationCreate(NULL, 0, kCFUserNotificationNoteAlertLevel, NULL, dictionary);

        CFUserNotificationReceiveResponse(notification, 0, &response);

        if (response == kCFUserNotificationDefaultResponse) {
            NSString *url = [NSString stringWithFormat:DOWNLOAD_URL, newVersion];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
        } else if (response  == kCFUserNotificationAlternateResponse) {
            // save to prefs that we do not want to download this version
            CFPreferencesSetAppValue(CFSTR("skipVersion"), newVersion, APPLICATION_NAME);
            CFPreferencesAppSynchronize(APPLICATION_NAME);
        }
    }

    [pool release];
    return 0;
}
