//
//  ImageBrowserController.m
//  4sho
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@interface ImageBrowserController : NSWindowController
{
    IBOutlet id _imageBrowser;
    IBOutlet id _status;

    NSMutableArray *_images;
    NSMutableArray *_importedImages;
}

- (IBAction) zoomSliderDidChange:(id)sender;
- (IBAction) addImageButtonClicked:(id) sender;

@end
