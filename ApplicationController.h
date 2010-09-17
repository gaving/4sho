//
//  ApplicationController.h
//  4sheet
//

#import <Cocoa/Cocoa.h>

@interface ApplicationController : NSObject {
    IBOutlet NSComboBox *comboBox;
    IBOutlet NSButton *fetchButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSProgressIndicator *determinateProgressIndicator;
    IBOutlet NSPopUpButton *viewButton;
    int currentCount;
    int totalCount;
    bool isDownloading;
    NSString *board;
    NSMutableArray *urls;
}

@property int currentCount;
@property int totalCount;
@property bool isDownloading;
@property (retain) NSString *board;

- (void)registerMyApp;
- (void)openViewMethod;
- (IBAction)fetch:(id)sender;
- (BOOL)findImages;
- (void)downloadURL:(NSArray *)urls;
- (void)finished;

@end
