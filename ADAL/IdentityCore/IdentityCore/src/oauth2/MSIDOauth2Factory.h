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

#import <Foundation/Foundation.h>
#import "MSIDCredentialType.h"

@class MSIDTokenResponse;
@class MSIDBaseToken;
@class MSIDAccessToken;
@class MSIDLegacyAccessToken;
@class MSIDRefreshToken;
@class MSIDIdToken;
@class MSIDLegacySingleResourceToken;
@class MSIDLegacyRefreshToken;
@class MSIDAccount;
@class MSIDConfiguration;
@class MSIDWebviewFactory;
@class MSIDAuthority;

@protocol MSIDRequestContext;

@interface MSIDOauth2Factory : NSObject
{
    MSIDWebviewFactory *_webviewFactory;
}

// Response handling
- (MSIDTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                     context:(id<MSIDRequestContext>)context
                                       error:(NSError * __autoreleasing *)error;

- (BOOL)verifyResponse:(MSIDTokenResponse *)response
               context:(id<MSIDRequestContext>)context
                 error:(NSError * __autoreleasing *)error;

// Tokens
- (MSIDBaseToken *)baseTokenFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;
- (MSIDAccessToken *)accessTokenFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;
- (MSIDLegacyAccessToken *)legacyAccessTokenFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;
- (MSIDLegacyRefreshToken *)legacyRefreshTokenFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;
- (MSIDRefreshToken *)refreshTokenFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;
- (MSIDIdToken *)idTokenFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;
- (MSIDLegacySingleResourceToken *)legacyTokenFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;
- (MSIDAccount *)accountFromResponse:(MSIDTokenResponse *)response configuration:(MSIDConfiguration *)configuration;

// Webview Factory
@property (readonly) MSIDWebviewFactory *webviewFactory;

@end

