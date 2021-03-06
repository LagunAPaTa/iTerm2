//
//  ProfilesTerminalPreferencesViewController.m
//  iTerm
//
//  Created by George Nachman on 4/17/14.
//
//

#import "ProfilesTerminalPreferencesViewController.h"

#import "ITAddressBookMgr.h"
#import "iTermController.h"
#import "iTermShellHistoryController.h"

@implementation ProfilesTerminalPreferencesViewController {
    IBOutlet NSTextField *_numScrollbackLines;
    IBOutlet NSButton *_unlimitedScrollback;
    IBOutlet NSButton *_scrollbackWithStatusBar;
    IBOutlet NSButton *_scrollbackInAlternateScreen;
    IBOutlet NSPopUpButton *_characterEncoding;
    IBOutlet NSComboBox *_terminalType;
    IBOutlet NSTextField *_answerBackString;
    IBOutlet NSButton *_xtermMouseReporting;
    IBOutlet NSButton *_xtermMouseReportingAllowMouseWheel;
    IBOutlet NSButton *_allowTitleReporting;
    IBOutlet NSButton *_allowTitleSetting;
    IBOutlet NSButton *_disablePrinting;
    IBOutlet NSButton *_disableAltScreen;
    IBOutlet NSButton *_disableWindowResizing;
    IBOutlet NSButton *_silenceBell;
    IBOutlet NSButton *_postNotifications;
    IBOutlet NSButton *_filterAlertsButton;
    IBOutlet NSButton *_flashingBell;
    IBOutlet NSButton *_bellIconInTabs;
    IBOutlet NSButton *_setLocaleVars;
    IBOutlet NSButton *_forceCommandPromptToFirstColumn;
    IBOutlet NSButton *_showMarkIndicators;

    IBOutlet NSPanel *_filterAlertsPanel;
    IBOutlet NSButton *_bellAlert;
    IBOutlet NSButton *_idleAlert;
    IBOutlet NSButton *_newOutputAlert;
    IBOutlet NSButton *_sessionEndedAlert;
    IBOutlet NSButton *_terminalGeneratedAlerts;
}

- (void)awakeFromNib {
    PreferenceInfo *info;
    __weak __typeof(self) weakSelf = self;
    info = [self defineControl:_numScrollbackLines
                           key:KEY_SCROLLBACK_LINES
                          type:kPreferenceInfoTypeIntegerTextField];
    info.range = NSMakeRange(0, 10 * 1000 * 1000);
    info.deferUpdate = YES;
    
    info = [self defineControl:_unlimitedScrollback
                           key:KEY_UNLIMITED_SCROLLBACK
                          type:kPreferenceInfoTypeCheckbox];
    info.observer = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        BOOL unlimited = [strongSelf boolForKey:KEY_UNLIMITED_SCROLLBACK];
        strongSelf->_numScrollbackLines.enabled = !unlimited;
        if (unlimited) {
            strongSelf->_numScrollbackLines.stringValue = @"";
        } else {
            strongSelf->_numScrollbackLines.intValue = [strongSelf intForKey:KEY_SCROLLBACK_LINES];
        }
    };

    [self defineControl:_scrollbackWithStatusBar
                    key:KEY_SCROLLBACK_WITH_STATUS_BAR
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_scrollbackInAlternateScreen
                    key:KEY_SCROLLBACK_IN_ALTERNATE_SCREEN
                   type:kPreferenceInfoTypeCheckbox];

    [self populateEncodings];
    info = [self defineControl:_characterEncoding
                           key:KEY_CHARACTER_ENCODING
                          type:kPreferenceInfoTypeUnsignedIntegerPopup];
    __weak __typeof(info) weakInfo = info;
    info.onUpdate = ^BOOL() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return NO;
        }
        assert(weakInfo);
        NSUInteger tag = [self unsignedIntegerForKey:weakInfo.key];
        [strongSelf->_characterEncoding selectItemWithTag:tag];
        return YES;
    };

    // It's a combobox, but we can safely treat it as a string text field.
    [self defineControl:_terminalType
                    key:KEY_TERMINAL_TYPE
                   type:kPreferenceInfoTypeStringTextField];

    [self defineControl:_answerBackString
                    key:KEY_ANSWERBACK_STRING
                   type:kPreferenceInfoTypeStringTextField];

    info = [self defineControl:_xtermMouseReporting
                           key:KEY_XTERM_MOUSE_REPORTING
                          type:kPreferenceInfoTypeCheckbox];
    info.observer = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf->_xtermMouseReportingAllowMouseWheel setEnabled:[strongSelf boolForKey:KEY_XTERM_MOUSE_REPORTING]];
    };

    [self defineControl:_xtermMouseReportingAllowMouseWheel
                    key:KEY_XTERM_MOUSE_REPORTING_ALLOW_MOUSE_WHEEL
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_allowTitleReporting
                    key:KEY_ALLOW_TITLE_REPORTING
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_allowTitleSetting
                    key:KEY_ALLOW_TITLE_SETTING
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_disablePrinting
                    key:KEY_DISABLE_PRINTING
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_disableAltScreen
                    key:KEY_DISABLE_SMCUP_RMCUP
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_disableWindowResizing
                    key:KEY_DISABLE_WINDOW_RESIZING
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_silenceBell
                    key:KEY_SILENCE_BELL
                   type:kPreferenceInfoTypeCheckbox];

    info = [self defineControl:_postNotifications
                           key:KEY_BOOKMARK_USER_NOTIFICATIONS
                          type:kPreferenceInfoTypeCheckbox];
    info.observer = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        BOOL sendNotifications = [self boolForKey:KEY_BOOKMARK_USER_NOTIFICATIONS];
        [strongSelf->_filterAlertsButton setEnabled:sendNotifications];
    };

    [self defineControl:_bellAlert
                    key:KEY_SEND_BELL_ALERT
                   type:kPreferenceInfoTypeCheckbox];
    [self defineControl:_idleAlert
                    key:KEY_SEND_IDLE_ALERT
                   type:kPreferenceInfoTypeCheckbox];
    [self defineControl:_newOutputAlert
                    key:KEY_SEND_NEW_OUTPUT_ALERT
                   type:kPreferenceInfoTypeCheckbox];
    [self defineControl:_sessionEndedAlert
                    key:KEY_SEND_SESSION_ENDED_ALERT
                   type:kPreferenceInfoTypeCheckbox];
    [self defineControl:_terminalGeneratedAlerts
                    key:KEY_SEND_TERMINAL_GENERATED_ALERT
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_flashingBell
                    key:KEY_FLASHING_BELL
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_bellIconInTabs
                    key:KEY_VISUAL_BELL
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_setLocaleVars
                    key:KEY_SET_LOCALE_VARS
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_forceCommandPromptToFirstColumn
                    key:KEY_PLACE_PROMPT_AT_FIRST_COLUMN
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_showMarkIndicators
                    key:KEY_SHOW_MARK_INDICATORS
                   type:kPreferenceInfoTypeCheckbox];
}

#pragma mark - Character Encoding

- (void)populateEncodings {
    [_characterEncoding removeAllItems];
    for (NSNumber *anEncoding in [self sortedEncodings]) {
        NSString *theTitle = [NSString localizedNameOfStringEncoding:[anEncoding unsignedIntValue]];
        [_characterEncoding addItemWithTitle:theTitle];
        [[_characterEncoding lastItem] setTag:[anEncoding unsignedIntValue]];
    }
}

// Comparator for sorting encodings
static NSInteger CompareEncodingByLocalizedName(id a, id b, void *unused) {
    NSString *localizedA = [NSString localizedNameOfStringEncoding:[a unsignedIntValue]];
    NSString *localizedB = [NSString localizedNameOfStringEncoding:[b unsignedIntValue]];
    return [localizedA caseInsensitiveCompare:localizedB];
}

- (NSArray *)sortedEncodings {
    NSStringEncoding const *encodingPtr;
    NSMutableArray *encodings = [NSMutableArray array];

    for (encodingPtr = [NSString availableStringEncodings]; *encodingPtr; ++encodingPtr) {
        [encodings addObject:@(*encodingPtr)];
    }
    [encodings sortUsingFunction:CompareEncodingByLocalizedName context:NULL];

    return encodings;
}


#pragma mark - Action

- (IBAction)help:(id)sender {
    [iTermShellHistoryController showInformationalMessage];
}

- (IBAction)showFilterAlertsPanel:(id)sender {
    __weak __typeof(self) weakSelf = self;
    [self.view.window beginSheet:_filterAlertsPanel completionHandler:^(NSModalResponse returnCode) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf->_filterAlertsPanel close];
        }
    }];
}

- (IBAction)closeFilterAlertsPanel:(id)sender {
    [_filterAlertsPanel.sheetParent endSheet:_filterAlertsPanel];
}

@end
