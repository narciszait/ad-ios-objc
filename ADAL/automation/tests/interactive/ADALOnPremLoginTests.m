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
#import "XCTestCase+TextFieldTap.h"

@interface ADALOnPremLoginTests : ADALBaseUITest

@end

@implementation ADALOnPremLoginTests

- (void)testInteractiveOnPremLogin_withPromptAlways_ValidateAuthorityFalse_loginHint_ADALWebView_ADFSv3
{
    MSIDTestAutomationConfigurationRequest *configurationRequest = [MSIDTestAutomationConfigurationRequest new];
    configurationRequest.appVersion = MSIDAppVersionOnPrem;
    configurationRequest.accountProvider = MSIDTestAccountProviderADfsv3;
    configurationRequest.accountFeatures = @[];
    [self loadTestConfiguration:configurationRequest];

    NSDictionary *params = @{
                             @"prompt_behavior" : @"always",
                             @"user_identifier": self.primaryAccount.account,
                             @"validate_authority" : @NO
                             };

    NSDictionary *config = [self.testConfiguration configWithAdditionalConfiguration:params];

    [self acquireToken:config];
    [self enterADFSPassword];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now do silent #296725
    config = [self.testConfiguration configWithAdditionalConfiguration:@{@"validate_authority":@NO}];
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now do silent with user identifier
    NSDictionary *silentConfig = [self.testConfiguration configWithAdditionalConfiguration:@{@"validate_authority":@NO,@"user_identifier": self.primaryAccount.account}];
    [self acquireTokenSilent:silentConfig];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now expire access token
    [self expireAccessToken:config];
    [self assertAccessTokenExpired];
    [self closeResultView];

    // Now do access token refresh
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now expire access token again
    [self expireAccessToken:config];
    [self assertAccessTokenExpired];
    [self closeResultView];

    // Now do access token refresh again, verifying that refresh token wasn't deleted as a result of the first operation
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    [self closeResultView];
}

- (void)testInteractiveOnpremLogin_withPromptAuto_ValidateAuthorityFalse_loginHint_ADALInWebView_ADFSv3
{
    MSIDTestAutomationConfigurationRequest *configurationRequest = [MSIDTestAutomationConfigurationRequest new];
    configurationRequest.appVersion = MSIDAppVersionOnPrem;
    configurationRequest.accountProvider = MSIDTestAccountProviderADfsv3;
    configurationRequest.accountFeatures = @[];
    [self loadTestConfiguration:configurationRequest];

    NSDictionary *params = @{
                             @"prompt_behavior" : @"auto",
                             @"user_identifier": self.primaryAccount.account,
                             @"validate_authority" : @NO,
                             };

    NSDictionary *config = [self.testConfiguration configWithAdditionalConfiguration:params];

    [self acquireToken:config];
    [self enterADFSPassword];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now do acquiretoken again with prompt auto and expect result to be returned immediately
    [self acquireToken:config];
    [self assertAccessTokenNotNil];
    [self closeResultView];
}

- (void)testInteractiveOnPremLogin_withPromptAlways_ValidateAuthorityTrue_noLoginHint_ADFSv3_shouldFailWithoutUPN
{
    MSIDTestAutomationConfigurationRequest *configurationRequest = [MSIDTestAutomationConfigurationRequest new];
    configurationRequest.appVersion = MSIDAppVersionOnPrem;
    configurationRequest.accountProvider = MSIDTestAccountProviderADfsv3;
    configurationRequest.accountFeatures = @[];
    [self loadTestConfiguration:configurationRequest];

    NSDictionary *params = @{
                             @"prompt_behavior" : @"always",
                             @"validate_authority" : @YES,
                             };

    NSDictionary *config = [self.testConfiguration configWithAdditionalConfiguration:params];

    [self acquireToken:config];
    [self assertErrorCode:@"AD_ERROR_DEVELOPER_INVALID_ARGUMENT"];
}

- (void)testInteractiveOnPremLogin_withPromptAlways_ValidateAuthorityTrue_loginHint_ADFSv3
{
    MSIDTestAutomationConfigurationRequest *configurationRequest = [MSIDTestAutomationConfigurationRequest new];
    configurationRequest.appVersion = MSIDAppVersionOnPrem;
    configurationRequest.accountProvider = MSIDTestAccountProviderADfsv3;
    configurationRequest.accountFeatures = @[];
    [self loadTestConfiguration:configurationRequest];

    NSDictionary *params = @{
                             @"prompt_behavior" : @"always",
                             @"user_identifier": self.primaryAccount.account,
                             @"validate_authority" : @YES
                             };

    NSDictionary *config = [self.testConfiguration configWithAdditionalConfiguration:params];

    [self acquireToken:config];
    [self enterADFSPassword];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now do silent #296725
    config = [self.testConfiguration configWithAdditionalConfiguration:@{}];
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    [self closeResultView];
}

- (void)testInteractiveOnPremLogin_withPromptAlways_ValidateAuthorityTrue_loginHint_ADALWebView_ADFSv4
{
    MSIDTestAutomationConfigurationRequest *configurationRequest = [MSIDTestAutomationConfigurationRequest new];
    configurationRequest.accountProvider = MSIDTestAccountProviderWW;
    configurationRequest.appVersion = MSIDAppVersionOnPrem;
    configurationRequest.accountProvider = MSIDTestAccountProviderADfsv4;
    configurationRequest.accountFeatures = @[];
    [self loadTestConfiguration:configurationRequest];

    NSDictionary *params = @{
                             @"prompt_behavior" : @"always",
                             @"user_identifier": self.primaryAccount.account,
                             @"validate_authority" : @YES
                             };

    NSDictionary *config = [self.testConfiguration configWithAdditionalConfiguration:params];

    [self acquireToken:config];
    [self enterADFSPassword];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now do silent #296725
    NSDictionary *silentParams = @{
                                   @"user_identifier" : self.primaryAccount.account
                                   };

    config = [self.testConfiguration configWithAdditionalConfiguration:silentParams];
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    XCTAssertEqualObjects([[self resultDictionary][@"displayable_id"] lowercaseString], self.primaryAccount.account.lowercaseString);
    [self closeResultView];
}

- (void)testInteractiveOnPremLogin_withPromptAlways_ValidateAuthorityFalse_loginHint_ADALWebView_ADFSv4
{
    MSIDTestAutomationConfigurationRequest *configurationRequest = [MSIDTestAutomationConfigurationRequest new];
    configurationRequest.accountProvider = MSIDTestAccountProviderWW;
    configurationRequest.appVersion = MSIDAppVersionOnPrem;
    configurationRequest.accountProvider = MSIDTestAccountProviderADfsv4;
    configurationRequest.accountFeatures = @[];
    [self loadTestConfiguration:configurationRequest];

    NSDictionary *params = @{
                             @"prompt_behavior" : @"always",
                             @"user_identifier": self.primaryAccount.account,
                             @"validate_authority" : @NO
                             };

    NSDictionary *config = [self.testConfiguration configWithAdditionalConfiguration:params];

    [self acquireToken:config];
    [self enterADFSPassword];
    [self assertAccessTokenNotNil];
    XCTAssertEqualObjects([[self resultDictionary][@"displayable_id"] lowercaseString], self.primaryAccount.account.lowercaseString);
    [self closeResultView];

    // Now do silent #296725
    NSDictionary *silentParams = @{
                                   @"user_identifier" : self.primaryAccount.account,
                                   @"validate_authority" : @NO
                                   };

    config = [self.testConfiguration configWithAdditionalConfiguration:silentParams];
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    [self closeResultView];

    // Now expire access token
    [self expireAccessToken:config];
    [self assertAccessTokenExpired];
    [self closeResultView];

    // Now do access token refresh
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    XCTAssertEqualObjects([[self resultDictionary][@"displayable_id"] lowercaseString], self.primaryAccount.account.lowercaseString);
    [self closeResultView];

    // Now do silent #296725 without providing user ID
    silentParams = @{
                     @"client_id" : self.testConfiguration.clientId,
                     @"authority" : self.testConfiguration.authority,
                     @"resource" : self.testConfiguration.resource,
                     @"validate_authority" : @NO
                     };

    config = [self.testConfiguration configWithAdditionalConfiguration:silentParams];
    [self acquireTokenSilent:config];
    [self assertAccessTokenNotNil];
    XCTAssertEqualObjects([[self resultDictionary][@"displayable_id"] lowercaseString], self.primaryAccount.account.lowercaseString);
    [self closeResultView];
}

#pragma mark - Private

- (void)enterADFSPassword
{
    XCUIElement *passwordTextField = self.testApp.secureTextFields[@"Password"];
    [self waitForElement:passwordTextField];
    [self tapElementAndWaitForKeyboardToAppear:passwordTextField];
    [passwordTextField typeText:[NSString stringWithFormat:@"%@\n", self.primaryAccount.password]];
}

@end
