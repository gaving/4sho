//
//  AppPrefsWindowController.h
//  4sho
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
