//
//  ApplicationController.m
//  4sho
//

#import "ApplicationController.h"
#import "RegexKitLite.h"
#import "PreferencesController.h"
#include <Carbon/Carbon.h>

@implementation NSString (Empty)
    - (BOOL) empty {
        return ([[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]length] == 0);
    }
@end

@interface NSObject (PtrValueUtils)
    - (NSValue *)ptrValue;
@end

@implementation NSObject (PtrValueUtils)
    - (NSValue *)ptrValue {
        return [NSValue valueWithPointer:self];
    }
@end

@implementation ApplicationController

@synthesize currentCount;
@synthesize totalCount;
@synthesize isDownloading;
@synthesize board;

NSString* const ImageRegexp = @"(http://images.4chan.org/[a-z0-9]+/src/(?:[0-9]*).(?:jpg|png|gif))";
NSString* const BoardRegexp = @"^http://boards.4chan.org/";

- (void)awakeFromNib {

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];
    if (type != nil) {
        NSString *contents = [pasteboard stringForType:type];
        if ((contents != nil) && [contents isMatchedByRegex:BoardRegexp]) {
            [comboBox setObjectValue: contents];
        }
    }

    [self registerApp];

    downloadURLsToLocalPaths = [NSMutableDictionary new];
}

- (void)registerApp {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

    url = [url stringByReplacingOccurrencesOfString:@"boxy" withString:@"http"];
    NSLog(@"Passed %@", url);

    if ((url != nil) && [url isMatchedByRegex:BoardRegexp]) {
        [comboBox setObjectValue: url];
        [self fetch:nil];
    }
}

- (IBAction)fetch:(id)sender {

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

        if (![self startFetching]) {
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
        [self downloadURL:imageURLs];
    } else {
        [self finished];
    }
}

- (NSString *)createTemporaryDirectory {
    NSString *name = self.board;

    if (name == nil) {
        name = [NSString stringWithFormat:@"%0.0f", [[NSDate date] timeIntervalSince1970]];
    }

    NSString *downloadDestination = [[NSUserDefaults standardUserDefaults] stringForKey:@"downloadDestination"];
    if (downloadDestination) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *folder = [[downloadDestination stringByExpandingTildeInPath] stringByAppendingPathComponent: name];
        if ([fileManager fileExistsAtPath: folder] == NO) {
           [fileManager createDirectoryAtPath: folder withIntermediateDirectories: NO attributes: nil error: nil];
        }
    }

    return name;
}

- (BOOL)startFetching {

    NSString *urlString = [comboBox stringValue];
    NSURL *url;

    if (![urlString empty]) {
        url = [NSURL URLWithString:urlString];
        if (!url) {
            [ApplicationController showError:@"An error occurred" withMessage:@"Please enter a valid URL."];
            NSBeep();
            return NO;
        }
    } else {
        [ApplicationController showError:@"An error occurred" withMessage:@"Please enter a URL."];
        NSBeep();
        return NO;
    }

    NSLog(@"Hitting thread: %@", url);

    /* Update the name of our board */
    self.board = [url lastPathComponent];

    [NSThread detachNewThreadSelector:@selector(performAsyncLoadWithURL:) toTarget:self withObject:url];

    return YES;
}

- (void)performAsyncLoadWithURL:(NSURL*)url {
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
}

- (void)downloadURL:(NSArray *)urls {
    NSString* folder = [self createTemporaryDirectory];
    if (!folder) {
        return;
    }

    NSString *downloadDestination = [[NSUserDefaults standardUserDefaults] stringForKey:@"downloadDestination"];
    if (!downloadDestination) {
        return;
    }

    /* Alias this to the most recent directory for the apple script */
    NSString *destPath =  [[downloadDestination stringByExpandingTildeInPath] stringByAppendingPathComponent:folder];
    NSString *aliasPath = [[downloadDestination stringByExpandingTildeInPath] stringByAppendingPathComponent:@"recent"];

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
            NSMutableArray *fileNames = [NSMutableArray array];
            [fileNames addObject:matchedDest];
            [[NSNotificationCenter defaultCenter] postNotificationName: @"ImageAdded" object: fileNames];
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

-(void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
        [downloadURLsToLocalPaths setObject:path forKey:[download ptrValue]];
}

- (void)downloadDidFinish:(NSURLDownload *)download {

    [download release];

    NSMutableArray *fileNames = [NSMutableArray array];
    [fileNames addObject:[downloadURLsToLocalPaths objectForKey:[download ptrValue]]];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"ImageAdded" object: fileNames];

    self.currentCount = self.currentCount + 1;
    float floatVal = (float) (((float)self.currentCount / (float)self.totalCount)*100.0);
    [determinateProgressIndicator setDoubleValue:floatVal];
    if (self.currentCount >= self.totalCount) {
        self.currentCount = 0;
        [self finished];
        if (self.totalCount > 0) {
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

- (IBAction)preferences:(id)sender {
    [[PreferencesController sharedPrefsWindowController] showWindow:nil];
    (void)sender;
}

- (void)openIndexSheet {
    NSLog(@"Launching index sheet");
    NSDictionary *errors = [NSDictionary dictionary];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"OpenIndexSheetForDirectory" ofType:@"scpt"];
    if (path) {
        NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&errors]autorelease];
        NSString *downloadDestination = [[NSUserDefaults standardUserDefaults] stringForKey:@"downloadDestination"];
        NSString *aliasPath = [[downloadDestination stringByExpandingTildeInPath] stringByAppendingPathComponent:@"recent"];
        NSAppleEventDescriptor *firstParameter = [NSAppleEventDescriptor descriptorWithString:aliasPath];
        NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
        [parameters insertDescriptor:firstParameter atIndex:1];
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
                                                                                        bytes:&psn
                                                                                       length:sizeof(ProcessSerialNumber)];
        NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString:[@"show_index_sheet" lowercaseString]];
        NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
                                                                                 eventID:kASSubroutineEvent
                                                                        targetDescriptor:target
                                                                                returnID:kAutoGenerateReturnID
                                                                           transactionID:kAnyTransactionID];
        [event setParamDescriptor:handler forKeyword:keyASSubroutineName];
        [event setParamDescriptor:parameters forKeyword:keyDirectObject];
        if (![script executeAppleEvent:event error:&errors]) {
            NSLog(@"%@", errors);
        }

        [script release];
    }
}

- (void)openDownloadDirectory {
    NSString *downloadDestination = [[NSUserDefaults standardUserDefaults] stringForKey:@"downloadDestination"];
    if (downloadDestination) {
        NSString *folder = [[downloadDestination stringByExpandingTildeInPath] stringByAppendingPathComponent: self.board];
        if (folder != nil) {
            [[NSWorkspace sharedWorkspace] openFile:folder];
        }
    }
}

- (void)openViewMethod {
    switch ([[viewButton selectedItem] tag]) {
        case 1:
            NSLog(@"Do nothing");
            break;
        case 2:
            [self openIndexSheet];
            break;
        case 3:
            [self openDownloadDirectory];
            break;
        default:
            break;
    }
}

+ (void)showError:(NSString *)title withMessage:(NSString *)info {
    NSAlert* alert = [NSAlert new];
    [alert setMessageText: title];
    [alert setInformativeText: info];
    [alert setAlertStyle: NSCriticalAlertStyle];
    [alert runModal];
    [alert release];
}

@end
