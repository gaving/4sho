//
//  AppPrefsWindowController.m
//  4sho
//
//  Created by Gavin Gilmour on 18/10/2009.
//  Copyright 2009. All rights reserved.
//

#import "PreferencesController.h"

#define DOWNLOAD_FOLDER     0
#define DOWNLOAD_TORRENT    2

@implementation PreferencesController

- (id) init {
    if ((self = [super init])) {
        fDefaults = [NSUserDefaults standardUserDefaults];
    }

    return self;
}

- (void) awakeFromNib {
}

- (void)setupToolbar {
    [self addView:generalPreferenceView label:@"General" image:[NSImage imageNamed:@"NSPreferencesGeneral"]];
}

- (void) incompleteFolderSheetShow: (id) sender {
    NSOpenPanel * panel = [NSOpenPanel openPanel];

    [panel setPrompt: @"Select"];
    [panel setAllowsMultipleSelection: NO];
    [panel setCanChooseFiles: NO];
    [panel setCanChooseDirectories: YES];
    [panel setCanCreateDirectories: YES];

    [panel beginSheetForDirectory: nil file: nil types: nil
                   modalForWindow: [self window] modalDelegate: self didEndSelector:
     @selector(incompleteFolderSheetClosed:returnCode:contextInfo:) contextInfo: nil];
}

- (void) incompleteFolderSheetClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info {
    if (code == NSOKButton) {
        NSString * folder = [[openPanel filenames] objectAtIndex: 0];
        NSLog(@"%@", folder);
        [fDefaults setObject:folder forKey:@"downloadDestination"];
        // [fDefaults synchronize];

        NSString *downloadDestination = [fDefaults stringForKey:@"downloadDestination"];
        NSLog(@"%@", downloadDestination);
        NSLog(@"______");

    }
    [destFolder selectItemAtIndex: 0];
}

@end
