//
//  ApplicationController.h
//  4sheet
//

#import <Cocoa/Cocoa.h>


@interface ApplicationController : NSObject {
    IBOutlet NSTextField *textField;
    IBOutlet NSButton *fetchButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    int currentCount;
    int totalCount;
}

@property int currentCount;
@property int totalCount;

- (void)processFetch;
- (IBAction)fetch:(id)sender;
- (NSArray *)getImageURLs;
- (void)downloadURL:(NSArray *)urls;
- (BOOL)openIndexSheet;

@end
