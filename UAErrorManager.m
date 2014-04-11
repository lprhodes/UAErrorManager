//
//  UAErrorManager
//
//  Singelton class for the display of error messages. Requires BlocksKit
//
//  Copyright (c) 2014 Urban Appetite Ltd.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "UAErrorManager.h"


#define UAERRORMANAGER_MESSAGE_FILE_NAME @"ErrorMessages";

#define UAERRORMANAGER_DEFAULT_ALERT_TITLE @"Error";
#define UAERRORMANAGER_UNKOWN_ERROR_ALERT_MESSAGE @"An unkown error occurred.";
#define UAERRORMANAGER_HIDE_DETAILS_BUTTON NO


@implementation UAError

- (NSString *)errorTitle
{
    if (_errorTitle) {
        return _errorTitle;
    }
    
    NSString *errorTitle;
    
    NSString *customErrorTitle = [[UAErrorManager defaultManager] customErrorTitleForErrorCode:self.originalError.code];
    
    if (customErrorTitle) {
        errorTitle = customErrorTitle;
    } else {
        errorTitle = UAERRORMANAGER_DEFAULT_ALERT_TITLE;
    }
    
    _errorTitle =  errorTitle;
    
    return _errorTitle;
}

- (NSString *)errorMessage
{
    if (_errorMessage) {
        return _errorMessage;
    }
    
    NSString *errorMessage;
    
    NSString *customErrorDescription = [[UAErrorManager defaultManager] customErrorMessageForErrorCode:self.originalError.code];
    if (customErrorDescription) {
        errorMessage = customErrorDescription;
    } else {
        errorMessage = self.originalError.localizedDescription;
    }
    
    _errorMessage = errorMessage;
    return errorMessage;
}

@end



NSString *const UAErrorManagerErrorMessageDetailedDescriptionKey = @"UAErrorManagerErrorMessageDetailedDescriptionKey";

NSString *const UAErrorManagerErrorMessageCodeKey = @"code";
NSString *const UAErrorManagerErrorMessageTitleKey = @"title";
NSString *const UAErrorManagerErrorMessageDescriptionKey = @"description";


@interface UAErrorManager ()

@property (strong, nonatomic) NSArray *customErrorMessages;
@property (strong, nonatomic) NSMutableDictionary *displayedErrorAlertViews;

@end



@implementation UAErrorManager

+ (UAErrorManager *)defaultManager
{
    static UAErrorManager *defaultManager = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        defaultManager = [[self alloc] init];
    });
    return defaultManager;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    NSString *customErrorMessagePlistFileName = UAERRORMANAGER_MESSAGE_FILE_NAME;
    NSString *customErrorMessagePlistFilePath = [[NSBundle mainBundle] pathForResource:[customErrorMessagePlistFileName stringByDeletingPathExtension] ofType:@"plist"];
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:customErrorMessagePlistFilePath], @"The custom error message file doesn't exist in the app's bundle: %@", customErrorMessagePlistFileName);
    
    self.customErrorMessages = [NSArray arrayWithContentsOfFile:customErrorMessagePlistFilePath];
    self.displayedErrorAlertViews = [@{ } mutableCopy];
}

+ (UIAlertView *)showAlertViewForError:(NSError *)error
{
    UAError *customUAError = [UAErrorManager customUAErrorWithError:error];
    
    UIAlertView *existingAlertView = [[UAErrorManager defaultManager].displayedErrorAlertViews objectForKey:@(error.code)];
    if (existingAlertView) {
        return existingAlertView;
    }
    
    NSString *detailedErrorDescription = error.userInfo[UAErrorManagerErrorMessageDetailedDescriptionKey];
    
    UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:customUAError.errorTitle message:customUAError.errorMessage];
    [alertView bk_addButtonWithTitle:@"OK" handler:^{
        [[UAErrorManager defaultManager].displayedErrorAlertViews removeObjectForKey:@(error.code)];
    }];
    
    if (!UAERRORMANAGER_HIDE_DETAILS_BUTTON && detailedErrorDescription) {
        [alertView bk_addButtonWithTitle:@"Details" handler:^{
            NSString *message = [NSString stringWithFormat:@"%@\n\n%@", customUAError.errorMessage, detailedErrorDescription];
            [UIAlertView bk_showAlertViewWithTitle:customUAError.errorTitle message:message cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        }];
    }
    
    [alertView show];
    
    [UAErrorManager defaultManager].displayedErrorAlertViews[@(error.code)] = alertView;
    
    return alertView;
}

+ (UAError *)customUAErrorWithError:(NSError *)error
{
    UAError *customUAError = [UAError new];
    customUAError.originalError = error;
    
    if (!error) {
        customUAError.errorMessage = UAERRORMANAGER_UNKOWN_ERROR_ALERT_MESSAGE;
    }
    
    return customUAError;
}

#pragma mark - Error Message Modifications

- (NSString *)customErrorTitleForErrorCode:(NSInteger)errorCode
{
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %@", UAErrorManagerErrorMessageCodeKey, @(errorCode)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
    NSArray *filteredCustomErrorMessages = [self.customErrorMessages filteredArrayUsingPredicate:predicate];
    
    if ([filteredCustomErrorMessages count] == 0) {
        return nil;
    }
    
    NSString *customErrorTitle = filteredCustomErrorMessages[0][UAErrorManagerErrorMessageTitleKey];
    
    if ([customErrorTitle isEqualToString:@""]) {
        return nil;
    }
    
    return customErrorTitle;
}

- (NSString *)customErrorMessageForErrorCode:(NSInteger)errorCode
{
    
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %@", UAErrorManagerErrorMessageCodeKey, @(errorCode)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
    NSArray *filteredCustomErrorMessages = [self.customErrorMessages filteredArrayUsingPredicate:predicate];
    
    if ([filteredCustomErrorMessages count] == 0) {
        return nil;
    }
    
    NSString *customErrorMessage = filteredCustomErrorMessages[0][UAErrorManagerErrorMessageDescriptionKey];
    
    if ([customErrorMessage isEqualToString:@""]) {
        return nil;
    }
    
    return customErrorMessage;
}

@end
