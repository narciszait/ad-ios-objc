 // Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ADALBaseUITest.h"
#import "NSDictionary+ADALiOSUITests.h"
#import "MSIDTestAutomationConfigurationRequest.h"
#import "MSIDTestAccountsProvider.h"
#import "XCTestCase+TextFieldTap.h"
#import "NSDictionary+ADALiOSUITests.h"
#import "MSIDAADV1IdTokenClaims.h"
#import "XCUIElement+CrossPlat.h"

static MSIDTestAccountsProvider *s_accountsProvider;

@implementation ADALBaseUITest

+ (void)setUp
{
    [super setUp];
    NSString *confPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"conf" ofType:@"json"];
    self.class.accountsProvider = [[MSIDTestAccountsProvider alloc] initWithConfigurationPath:confPath];
}

- (void)setUp
{
    [super setUp];
    
    self.continueAfterFailure = NO;
    
    self.testApp = [XCUIApplication new];
    [self.testApp launch];

    [self clearKeychain];
    [self clearCookies];
}

- (void)tearDown
{
    [self.testApp terminate];
    [super tearDown];
}

+ (MSIDTestAccountsProvider *)accountsProvider
{
    return s_accountsProvider;
}

+ (void)setAccountsProvider:(MSIDTestAccountsProvider *)accountsProvider
{
    s_accountsProvider = accountsProvider;
}

#pragma mark - Asserts

- (void)assertRefreshTokenInvalidated
{
    NSDictionary *result = [self resultDictionary];
    
    XCTAssertTrue([result[@"invalidated_refresh_token_count"] intValue] == 1);
}

- (void)assertAccessTokenExpired
{
    NSDictionary *result = [self resultDictionary];
    
    XCTAssertTrue([result[@"expired_access_token_count"] intValue] == 1);
}

- (void)assertAuthUIAppear
{
    XCUIElement *webView = [self.testApp.webViews elementBoundByIndex:0];
    BOOL result = [webView waitForExistenceWithTimeout:2.0];
    
    XCTAssertTrue(result);
}

- (void)assertErrorCode:(NSString *)expectedErrorCode
{
    [self assertErrorContent:expectedErrorCode key:@"error_code"];
}

- (void)assertErrorDescription:(NSString *)errorDescription
{
    NSDictionary *result = [self resultDictionary];
    NSString *actualContent = result[@"error_description"];
    XCTAssertNotEqual([actualContent length], 0);
    XCTAssertTrue([actualContent containsString:errorDescription]);
}

- (void)assertErrorContent:(NSString *)expectedContent key:(NSString *)key
{
    NSDictionary *result = [self resultDictionary];
    NSString *actualContent = result[key];
    XCTAssertNotEqual([actualContent length], 0);
    XCTAssertEqualObjects(actualContent, expectedContent);
}

- (void)assertAccessTokenNotNil
{
    NSDictionary *result = [self resultDictionary];
    
    XCTAssertTrue([result[@"access_token"] length] > 0);
    XCTAssertEqual([result[@"error"] length], 0);
}

- (NSDictionary *)resultIDTokenClaims
{
    NSDictionary *result = [self resultDictionary];

    NSString *idToken = result[@"id_token"];
    XCTAssertTrue([idToken length] > 0);

    MSIDAADV1IdTokenClaims *idTokenWrapper = [[MSIDAADV1IdTokenClaims alloc] initWithRawIdToken:idToken error:nil];
    return [idTokenWrapper jsonDictionary];
}

- (void)assertRefreshTokenNotNil
{
    NSDictionary *result = [self resultDictionary];
    
    XCTAssertTrue([result[@"refresh_token"] length] > 0);
}

#pragma mark - API fetch

- (void)loadTestConfiguration:(MSIDTestAutomationConfigurationRequest *)request
{
    __block MSIDTestAutomationConfiguration *testConfig = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Get configuration"];

    [self.class.accountsProvider configurationWithRequest:request
                                        completionHandler:^(MSIDTestAutomationConfiguration *configuration) {

                                      testConfig = configuration;
                                      [expectation fulfill];
                                  }];

    [self waitForExpectationsWithTimeout:60 handler:nil];

    if (!testConfig || ![testConfig.accounts count])
    {
        XCTAssertTrue(NO);
    }

    [self loadPasswordForAccount:testConfig.accounts[0]];

    self.testConfiguration = testConfig;
    XCTAssertTrue([self.testConfiguration.accounts count] >= 1);
    self.primaryAccount = self.testConfiguration.accounts[0];
}

- (void)loadPasswordForAccount:(MSIDTestAccount *)account
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get password"];

    [self.class.accountsProvider passwordForAccount:account
                                  completionHandler:^(NSString *password) {
                                [expectation fulfill];
                            }];

    [self waitForExpectationsWithTimeout:60 handler:nil];

    if (!account.password)
    {
        XCTAssertTrue(NO);
    }
}

#pragma mark - Actions

/*
 There seems to be some flakiness around sovereign user with login hint provided,
 where ESTS sometimes shows the username page with next button and sometimes redirects to the password page correctly. This portion of code waits for the "Next" button for 10 seconds if it appears.
 */
- (void)blackForestWaitForNextButton:(XCUIApplication *)application
{
    XCUIElement *emailTextField = application.textFields[@"Enter your email, phone, or Skype."];

    for (int i = 0; i < 10; i++)
    {
        if (emailTextField.exists)
        {
            [application.buttons[@"Next"] msidTap];
            break;
        }
        else
        {
            sleep(1);
        }
    }
}

- (void)aadEnterEmail:(NSString *)email inApp:(XCUIApplication *)app
{
    XCUIElement *emailTextField = app.textFields[@"Enter your email, phone, or Skype."];
    [self waitForElement:emailTextField];
    if ([email isEqualToString:emailTextField.value])
    {
        return;
    }

    [self tapElementAndWaitForKeyboardToAppear:emailTextField app:app];
    [emailTextField selectTextWithApp:app];
    [emailTextField typeText:email];
}

- (void)aadEnterEmail:(NSString *)email
{
    [self aadEnterEmail:email inApp:self.testApp];
}

- (void)aadEnterEmail
{
    [self aadEnterEmail:[NSString stringWithFormat:@"%@\n", self.primaryAccount.account] inApp:self.testApp];
}

- (void)aadEnterEmailInApp:(XCUIApplication *)app
{
    [self aadEnterEmail:[NSString stringWithFormat:@"%@\n", self.primaryAccount.account] inApp:app];
}

- (void)aadEnterPassword
{
    [self aadEnterPassword:[NSString stringWithFormat:@"%@\n", self.primaryAccount.password]];
}

- (void)aadEnterPasswordInApp:(XCUIApplication *)app
{
    [self aadEnterPassword:[NSString stringWithFormat:@"%@\n", self.primaryAccount.password] testApp:app];
}

- (void)aadEnterPassword:(NSString *)password
{
    [self aadEnterPassword:password testApp:self.testApp];
}

- (void)aadEnterPassword:(NSString *)password testApp:(XCUIApplication *)testApp
{
    // Enter password
    XCUIElement *passwordTextField = testApp.secureTextFields.firstMatch;
    [self waitForElement:passwordTextField];
    [self tapElementAndWaitForKeyboardToAppear:passwordTextField app:testApp];
    [passwordTextField typeText:password];
}

- (void)adfsEnterPassword
{
    [self adfsEnterPassword:[NSString stringWithFormat:@"%@\n", self.primaryAccount.password]];
}

- (void)adfsEnterPasswordInApp:(XCUIApplication *)app
{
    [self adfsEnterPassword:[NSString stringWithFormat:@"%@\n", self.primaryAccount.password] testApp:app];
}

- (void)adfsEnterPassword:(NSString *)password
{
    [self adfsEnterPassword:password testApp:self.testApp];
}

- (void)adfsEnterPassword:(NSString *)password testApp:(XCUIApplication *)testApp
{
    XCUIElement *passwordTextField = testApp.secureTextFields[@"Password"];
    [self waitForElement:passwordTextField];
    [self tapElementAndWaitForKeyboardToAppear:passwordTextField app:testApp];
    [passwordTextField typeText:password];
}

- (void)closeAuthUI
{
#if TARGET_OS_IPHONE
    [[self.testApp.navigationBars elementBoundByIndex:0].buttons[@"Cancel"] msidTap];
#else
    [self.testApp.windows[@"MSID_SIGN_IN_WINDOW"].buttons[XCUIIdentifierCloseWindow] click];
#endif
}

- (void)closeResultView
{
    [self.testApp.buttons[@"Done"] msidTap];
}

- (void)invalidateRefreshToken:(NSDictionary *)config
{
    NSString *jsonString = [config toJsonString];
    [self.testApp.buttons[@"Invalidate Refresh Token"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidPasteText:jsonString application:self.testApp];
    sleep(1);
    [self.testApp.buttons[@"Go"] msidTap];
}

- (void)expireAccessToken:(NSDictionary *)config
{
    NSString *jsonString = [config toJsonString];
    [self.testApp.buttons[@"Expire Access Token"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidPasteText:jsonString application:self.testApp];
    sleep(1);
    [self.testApp.buttons[@"Go"] msidTap];
}

- (void)acquireToken:(NSDictionary *)config
{
    NSString *jsonString = [config toJsonString];
    [self waitForElement:self.testApp.buttons[@"Acquire Token"]];
    [self.testApp.buttons[@"Acquire Token"] msidTap];
    [self waitForElement:self.testApp.textViews[@"requestInfo"]];
    [self.testApp.textViews[@"requestInfo"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidPasteText:jsonString application:self.testApp];
    sleep(1);
    [self.testApp.buttons[@"Go"] msidTap];
}

- (void)acquireTokenWithRefreshToken:(NSDictionary *)config
{
    NSString *jsonString = [config toJsonString];
    [self.testApp.buttons[@"acquireTokenByRefreshToken"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidPasteText:jsonString application:self.testApp];
    sleep(1);
    [self.testApp.buttons[@"Go"] msidTap];
}

- (void)acquireTokenSilent:(NSDictionary *)config
{
    NSString *jsonString = [config toJsonString];
    [self waitForElement:self.testApp.buttons[@"Acquire Token Silent"]];
    [self.testApp.buttons[@"Acquire Token Silent"] msidTap];
    [self waitForElement:self.testApp.textViews[@"requestInfo"]];
    [self.testApp.textViews[@"requestInfo"] msidTap];
    [self.testApp.textViews[@"requestInfo"] msidPasteText:jsonString application:self.testApp];
    sleep(1);
    [self.testApp.buttons[@"Go"] msidTap];
}

- (void)clearCache
{
    [self.testApp.buttons[@"Clear Cache"] msidTap];
    [self.testApp.buttons[@"Done"] msidTap];
}

- (void)clearKeychain
{
    [self.testApp.buttons[@"Clear keychain"] msidTap];
    [self.testApp.buttons[@"Done"] msidTap];
}

- (void)clearCookies
{
    [self.testApp.buttons[@"Clear Cookies"] msidTap];
    [self.testApp.buttons[@"Done"] msidTap];
}

- (void)openURL:(NSDictionary *)config
{
    NSString *jsonString = [config toJsonString];

    XCUIElement *openURLButton = self.testApp.buttons[@"openUrlInSafari"];
    [self waitForElement:openURLButton];
    [openURLButton msidTap];

    XCUIElement *requestInfoView = self.testApp.textViews[@"requestInfo"];
    [self waitForElement:requestInfoView];

    [requestInfoView msidTap];
    [self.testApp.textViews[@"requestInfo"] msidPasteText:jsonString application:self.testApp];
    sleep(1);
    [self.testApp.buttons[@"Go"] msidTap];
}

#pragma mark - Helpers

- (NSDictionary *)resultDictionary
{
    XCUIElement *resultTextView = self.testApp.textViews[@"resultInfo"];
    [self waitForElement:resultTextView];
    
    return [NSJSONSerialization JSONObjectWithData:[resultTextView.value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

- (void)waitForElement:(id)object
{
    NSPredicate *existsPredicate = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:existsPredicate evaluatedWithObject:object handler:nil];
    [self waitForExpectationsWithTimeout:60.0f handler:nil];
}

@end
