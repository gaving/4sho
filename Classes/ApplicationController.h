//
//  ApplicationController.h
//  4sho
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface NSString (Empty)
    - (BOOL) empty;
@end

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
    NSString *_outputPath;
    NSMutableDictionary *downloadURLsToLocalPaths;
}

@property int currentCount;
@property int totalCount;
@property bool isDownloading;
@property (retain) NSString *board;

- (IBAction)fetch:(id)sender;
- (IBAction)preferences:(id)sender;

- (BOOL)startFetching;

- (NSString *)createTemporaryDirectory;
- (void)processImages:(NSArray *)imageURLs;
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

- (void)registerApp;
- (void)openViewMethod;
- (void)performAsyncLoadWithURL:(NSURL*)url;
- (void)downloadURL:(NSArray *)urls;
- (void)finished;

- (void)openIndexSheet;
- (void)openDownloadDirectory;
- (void)openViewMethod;

+ (void)showError:(NSString *)title withMessage:(NSString *)info;

@end
