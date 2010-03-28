//
//  ApplicationController.m
//  4sheet
//

#import "ApplicationController.h"
#import "RegexKitLite.h"

@implementation ApplicationController

@synthesize currentCount;
@synthesize totalCount;

NSString* const DownloadDirectory = @"/Users/gavin/Desktop/images";
NSString* const ImageRegexp = @"(http://images.4chan.org/[a-z0-9]+/src/(?:[0-9]*).(?:jpg|png|gif))";

- (void)awakeFromNib {
}

- (IBAction)fetch:(id)sender {

    NSArray *imageURLs = [self getImageURLs];
    if (imageURLs) {

        [textField setEnabled: NO];
        [fetchButton setImage:nil];
        [progressIndicator startAnimation: self];

        self.totalCount = [imageURLs count];
        self.currentCount = 0;

        /* Download all the URLs to the above directory */
        [self downloadURL:imageURLs];
    }
}

- (NSString *)createTemporaryDirectory {
    NSString *timestamp = [NSString stringWithFormat:@"%0.0f", [[NSDate date] timeIntervalSince1970]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = [DownloadDirectory stringByAppendingPathComponent: timestamp];
    if ([fileManager fileExistsAtPath: folder] == NO) {
       [fileManager createDirectoryAtPath: folder withIntermediateDirectories: NO attributes: nil error: nil];
    }

    return timestamp;
}

- (NSArray *)getImageURLs {

    /* Fetch the index page of the board we want */
    NSString *textValue = [textField stringValue];
    NSURL *url = [NSURL URLWithString:textValue];

    if (!url) {
        NSLog(@"%@", @"A valid URL was not given");
        return nil;
    }

    NSData *pageContents = [NSData dataWithContentsOfURL: url];
    NSString *contents = [[NSString alloc] initWithData:pageContents encoding:NSASCIIStringEncoding];

    if (contents) {

        /* Rip out all the potential image links and filter out duplicates */
        NSSet *set = [[NSSet alloc] initWithArray: [contents componentsMatchedByRegex:ImageRegexp]];
        return [[NSArray alloc] initWithArray:[set allObjects]];
    } else {
        NSLog(@"Error getting the contents of the page");
    }

    return nil;
}

- (void)downloadURL:(NSArray *)urls {

    /* Create a temporary directory to store the images */
    NSString* timestamp = [self createTemporaryDirectory];
    if (!timestamp) {
        return;
    }

    /* Alias this to the most recent directory for the apple script */
    NSString *path = [DownloadDirectory stringByAppendingPathComponent:timestamp];
    NSString *aliasPath = [DownloadDirectory stringByAppendingPathComponent: @"recent"];
    NSString *destPath = [DownloadDirectory stringByAppendingPathComponent:timestamp];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:aliasPath]) {
        [fileManager removeItemAtPath:aliasPath error:NULL];
    }
    [fileManager createSymbolicLinkAtPath:aliasPath withDestinationPath:destPath error:nil];

    for (NSString *url in urls) {
        NSLog(@"Fetching %@", url);

        NSURL *theURL = [NSURL URLWithString:url];
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:theURL];
        NSURLDownload  *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];

        if (theDownload) {
            NSString *fileName = [theURL lastPathComponent];
            [theDownload setDestination:[path stringByAppendingPathComponent: fileName] allowOverwrite:NO];
        } else {
            NSLog(@"An error occurred trying to download %@", url);
        }
    }
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    [download release];
    NSLog(@"Download failed! Error - %@ %@",
            [error localizedDescription],
            [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    [download release];
    NSLog(@"%@",@"downloadDidFinish");

    self.currentCount = self.currentCount + 1;
    if (self.currentCount >= self.totalCount) {
        self.currentCount = 0;
        [self openIndexSheet];
        [self allDone];
    }
}

- (void)allDone {
    [textField setEnabled: YES];
    [fetchButton setImage:[NSImage imageNamed:@"NSActionTemplate"]];
    [progressIndicator stopAnimation: self];
}

- (BOOL)openIndexSheet {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"OpenIndexSheetForDirectory" ofType:@"scpt"];

    if (path) {
        NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil]autorelease];
        [script executeAndReturnError:nil];
        return YES;
    }
    return NO;
}

@end
