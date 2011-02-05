//
//  AppPrefsWindowController.h
//  4sho
//
//  Created by Gavin Gilmour on 18/10/2009.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"

@interface PreferencesController : DBPrefsWindowController {
    IBOutlet NSView *generalPreferenceView;
    IBOutlet NSPopUpButton *destFolder;

    NSUserDefaults *fDefaults;
}

- (void) incompleteFolderSheetShow: (id) sender;

@end
