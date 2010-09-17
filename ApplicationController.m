//
//  ApplicationController.m
//  that eet
//

#import "ApplicationController.h"
#import "RegexKitLite.h"

@implementation NSString (Empty)
    - (BOOL) empty{
        return ([[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]length] == 0);
    }
@end

@implementation ApplicationController

@synthesize currentCount;
@synthesize totalCount;
@synthesize isDownloading;
@synthesize board;

NSString* const DownloadDirectory = @"/Users/gavin/Desktop/images";
NSString* const ImageRegexp = @"(http://images.4chan.org/[a-z0-9]+/src/(?:[0-9]*).(?:jpg|png|gif))";
NSString* const BoardRegexp = @"^http://boards.4chan.org/";

- (void)awakeFromNib {

    urls = [NSArray arrayWithObjects:@"Jazz", @"Acid", @"Funk", @"Classic Rock", @"Rock", @"Pop", @"R&B", @"Hip Hop",
         @"Trip Hop", @"Classical", @"Swing", @"Metal", @"Country", @"Folk", @"Grunge", @"Alternative", nil];
    urls = [[urls sortedArrayUsingSelector:@selector(compare:)] retain];

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];
    if (type != nil) {
        NSString *contents = [pasteboard stringForType:type];
        if ((contents != nil) && [contents isMatchedByRegex:BoardRegexp]) {

            /* Set initial combo value if it looks like a proper URL */
            [comboBox setObjectValue: contents];
        }
    }

    [self registerMyApp];
}

- (void)registerMyApp {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

    url = [url stringByReplacingOccurrencesOfString:@"boxy" withString:@"http"];
    NSLog(@"Passed %@", url);

    if ((url != nil) && [url isMatchedByRegex:BoardRegexp]) {

        /* Set initial combo value if it looks like a proper URL */
        [comboBox setObjectValue: url];
        [self fetch:nil];
    }
}

- (IBAction)fetch:(id)sender {
	
	NSLog(@"%@", [[viewButton selectedItem] title]);
	//return;
    if (!self.isDownloading) {
        [comboBox setEnabled: NO];
        [fetchButton setImage:nil];
        [comboBox setHidden:YES];
        [determinateProgressIndicator setHidden:NO];
        [progressIndicator setHidden: NO];
        [progressIndicator startAnimation: self];

        self.totalCount = 0;
        self.currentCount = 0;
        self.isDownloading = true;

        if (![self findImages]) {
            [self finished];
        }
    } else {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"Stop"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Cancel fetch?"];
        [alert setInformativeText:@"Are you sure you want to stop fetching?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [self finished];
        }
    }
}

- (void)processImages:(NSArray *)imageURLs {
    if (imageURLs && ([imageURLs count] > 0)) {

        /* Download all the URLs to the above directory */
        [self downloadURL:imageURLs];
    } else {
        NSLog(@"TODO: Return this to a sane state");
        [self finished];
    }
}

- (NSString *)createTemporaryDirectory {
    NSString *name = self.board;

    if (name == nil) {
        name = [NSString stringWithFormat:@"%0.0f", [[NSDate date] timeIntervalSince1970]];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = [DownloadDirectory stringByAppendingPathComponent: name];
    if ([fileManager fileExistsAtPath: folder] == NO) {
       [fileManager createDirectoryAtPath: folder withIntermediateDirectories: NO attributes: nil error: nil];
    }

    return name;
}

- (BOOL)findImages {

    NSString *urlString = [comboBox stringValue];
    NSURL *url;

    if (![urlString empty]) {

        /* Fetch the index page of the board we want */
        url = [NSURL URLWithString:urlString];

        if (!url) {
            NSLog(@"A valid URL was not given");
            NSBeep();
            return NO;
        }
    } else {
        NSLog(@"You must provide an URL");
        NSBeep();
        return NO;
    }

    NSLog(@"Hitting thread: %@", url);

    /* Update the name of our board */
    self.board = [url lastPathComponent];

    [NSThread detachNewThreadSelector:@selector(performAsyncLoadWithURL:) toTarget:self withObject:url];

    return YES;
}

- (void) performAsyncLoadWithURL:(NSURL*)url {
    NSAutoreleasePool * pool =[[NSAutoreleasePool alloc] init];
    NSData* boardData = [NSData dataWithContentsOfURL:url options:NSMappedRead error:nil];
    NSString *contents = [[NSString alloc] initWithData:boardData encoding:NSASCIIStringEncoding];

    if (contents) {

        /* Rip out all the potential image links and filter out duplicates */
        NSSet *set = [[NSSet alloc] initWithArray: [contents componentsMatchedByRegex:ImageRegexp]];
        NSArray *matches =  [[NSArray alloc] initWithArray:[set allObjects]];
        [self performSelectorOnMainThread:@selector(processImages:) withObject:matches waitUntilDone:YES];
    } else {
        NSLog(@"Error getting the contents of the page");
    }

    [pool release];
}

- (void)loadDidFinishWithData:(NSData*)boardData {
    /* Stub */
}

- (void)downloadURL:(NSArray *)urls {

    /* Create a temporary directory to store the images */
    NSString* folder = [self createTemporaryDirectory];
    if (!folder) {
        return;
    }

    /* Alias this to the most recent directory for the apple script */
    NSString *destPath = [DownloadDirectory stringByAppendingPathComponent:folder];
    NSString *aliasPath = [DownloadDirectory stringByAppendingPathComponent: @"recent"];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error = nil;
    if ([[[fileManager attributesOfItemAtPath:aliasPath error:NULL] fileType] isEqualToString:NSFileTypeSymbolicLink]) {
        if (![fileManager removeItemAtPath:aliasPath error:&error]) {
            NSLog(@"Error deleting: %@ for %@", [error localizedDescription], aliasPath);
        }
    }

    error = nil;
    if (![fileManager createSymbolicLinkAtPath:aliasPath withDestinationPath:destPath error:&error]) {
       NSLog(@"Error creating symlink: %@ for %@ => %@", [error localizedDescription], aliasPath, destPath);
    }

    for (NSString *url in urls) {

        NSURL *matchedURL = [NSURL URLWithString:url];
        NSString *matchedFilename = [matchedURL lastPathComponent];
        NSString *matchedDest = [destPath stringByAppendingPathComponent: matchedFilename];

        if (![fileManager fileExistsAtPath:matchedDest]) {
            NSLog(@"Fetching %@", url);

            NSURLRequest *request = [NSURLRequest requestWithURL:matchedURL];
            NSURLDownload  *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
            self.totalCount = self.totalCount + 1;

            if (download) {
                [download setDestination:matchedDest allowOverwrite:NO];
            } else {
                NSLog(@"An error occurred trying to download %@", url);
            }
        } else {
            NSLog(@"Skipping %@ (already exists)", matchedDest);
        }
    }

    if (self.totalCount == 0) {
        [self finished];
        NSLog(@"Nothing new to download");
    }
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    [download release];
    NSLog(@"Download failed! Error - %@ %@",
            [error localizedDescription],
            [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    [download release];

    self.currentCount = self.currentCount + 1;
    float floatVal = (float) (((float)self.currentCount / (float)self.totalCount)*100.0);
    [determinateProgressIndicator setDoubleValue:floatVal];
    if (self.currentCount >= self.totalCount) {
        self.currentCount = 0;
        [self finished];

        if (self.totalCount > 0) {

            /* Actually appeared to have downloaded something */
            [self openViewMethod];
        }
    }
}

- (void)finished {
    self.isDownloading = false;
    [comboBox setEnabled: YES];
    [comboBox setHidden:NO];
    [determinateProgressIndicator setHidden:YES];
    [determinateProgressIndicator setDoubleValue:0.0];
    [fetchButton setImage:[NSImage imageNamed:@"NSActionTemplate"]];
    [progressIndicator stopAnimation: self];
    [progressIndicator setHidden: YES];
}

- (void)openViewMethod {
    switch ([[viewButton selectedItem] tag]) {
        case 0:
            break;
        case 1:{
            NSString *path = [[NSBundle mainBundle] pathForResource:@"OpenIndexSheetForDirectory" ofType:@"scpt"];

            if (path) {
                NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil]autorelease];
                [script executeAndReturnError:nil];
            }
            break;
		}
        case 2:{
            NSString *folder = [DownloadDirectory stringByAppendingPathComponent: self.board];
            if (folder != nil) {
                [[NSWorkspace sharedWorkspace] openFile:folder];
            }
            break;
		}
        default:
            break;
    }
}

- (NSInteger) numberOfItemsInComboBox: (NSComboBox *) aComboBox {
#pragma unused (aComboBox)
    return ([urls count]);
}
- (id) comboBox: (NSComboBox *) aComboBox objectValueForItemAtIndex: (NSInteger) index {
#pragma unused (aComboBox)
    return ([urls objectAtIndex:index]);
}
- (NSUInteger) comboBox: (NSComboBox *) aComboBox indexOfItemWithStringValue: (NSString *) string {
#pragma unused (aComboBox)
    return ([urls indexOfObject:string]);
}

- (NSString *) firstGenreMatchingPrefix: (NSString *) prefix {
    NSString *string = nil;
    NSString *lowercasePrefix = [prefix lowercaseString];
    NSEnumerator *stringEnum = [urls objectEnumerator];

    while ( (string = [stringEnum nextObject]) )
        if ([[string lowercaseString] hasPrefix:lowercasePrefix] ) {
            return (string) ;
        }

    return (nil);
} // firstGenreMatchingPrefix

- (NSString *) comboBox: (NSComboBox *) aComboBox completedString: (NSString *) inputString {
#pragma unused (aComboBox)
    // This method is received after each character typed by the user, because we have checked the "completes" flag for
    // genreComboBox in IB.
    // Given the inputString the user has typed, see if we can find a genre with the prefix, and return it as the suggested complete
    // string.
    NSString *candidate = [self firstGenreMatchingPrefix:inputString];
    return (candidate ? candidate : inputString);
} // urls

@end
