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

#import "MSIDWorkPlaceJoinUtil.h"
#import "MSIDKeychainUtil.h"
#import "MSIDRegistrationInformation.h"
#import "MSIDWorkPlaceJoinConstants.h"
#import "MSIDError.h"

@implementation MSIDWorkPlaceJoinUtil

// Convenience macro to release CF objects
#define CFReleaseNull(CF) { CFTypeRef _cf = (CF); if (_cf) CFRelease(_cf); CF = NULL; }

+ (MSIDRegistrationInformation *)getRegistrationInformation:(id<MSIDRequestContext>)context
                                               urlChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSString *authMethod = challenge.protectionSpace.authenticationMethod;
    
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"Ignoring SSL");
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        NSURLCredential *cred;
        cred = [NSURLCredential credentialForTrust:trust];
        [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
    }
    
    NSString *teamId = [MSIDKeychainUtil teamId];
    
    if (!teamId)
    {
        MSID_LOG_ERROR(context, @"xc Encountered an error when reading teamID from keychain.");
        return nil;
    }
    
    NSString *sharedAccessGroup = [NSString stringWithFormat:@"%@.com.microsoft.workplacejoin", teamId];

    MSIDRegistrationInformation *info = nil;
    SecIdentityRef identity = NULL;
    SecCertificateRef certificate = NULL;
    SecKeyRef privateKey = NULL;
    NSString *certificateSubject = nil;
    NSData *certificateData = nil;
    NSString *certificateIssuer = nil;
    OSStatus status = noErr;
    
    MSID_LOG_VERBOSE(nil, @"Attempting to get registration information - shared access Group. xx");
    MSID_LOG_VERBOSE_PII(nil, @"Attempting to get registration information - %@ shared access Group. xz", sharedAccessGroup);
    
    identity = [self copyWPJIdentity:context sharedAccessGroup:sharedAccessGroup certificateIssuer:&certificateIssuer];
    if (!identity || CFGetTypeID(identity) != SecIdentityGetTypeID())
    {
        MSID_LOG_VERBOSE(context, @"Failed to retrieve WPJ identity. xc");
        CFReleaseNull(identity);
        return nil;
    }
    
    // Get the wpj certificate
    MSID_LOG_VERBOSE(context, @"Retrieving WPJ certificate reference. xv");
    status = SecIdentityCopyCertificate(identity, &certificate);
    
    // Get the private key
    MSID_LOG_VERBOSE(context, @"Retrieving WPJ private key reference. xb");
    status = SecIdentityCopyPrivateKey(identity, &privateKey);
    
    certificateSubject = (NSString *)CFBridgingRelease(SecCertificateCopySubjectSummary(certificate));
    certificateData = (NSData *)CFBridgingRelease(SecCertificateCopyData(certificate));
    
    if(!(certificate && certificateSubject && certificateData && privateKey && certificateIssuer))
    {
        MSID_LOG_ERROR(context, @"WPJ identity retrieved from keychain is invalid. xn");
    }
    else
    {
        info = [[MSIDRegistrationInformation alloc] initWithSecurityIdentity:identity
                                                           certificateIssuer:certificateIssuer
                                                                 certificate:certificate
                                                          certificateSubject:certificateSubject
                                                             certificateData:certificateData
                                                                  privateKey:privateKey];
        
    }
    
    CFReleaseNull(identity);
    CFReleaseNull(certificate);
    CFReleaseNull(privateKey);
    
    return info;
}

+ (SecIdentityRef)copyWPJIdentity:(id<MSIDRequestContext>)context
                sharedAccessGroup:(NSString *)accessGroup
                certificateIssuer:(NSString **)issuer

{
    NSMutableDictionary *identityDict = [[NSMutableDictionary alloc] init];
    [identityDict setObject:(__bridge id)kSecClassIdentity forKey:(__bridge id)kSecClass];
    [identityDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnRef];
    [identityDict setObject:(__bridge id) kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    [identityDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    [identityDict setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
    
    CFDictionaryRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)identityDict, (CFTypeRef *)&result);
    
    if (status != errSecSuccess)
    {
        return NULL;
    }
    
    NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
    NSData *certIssuer = [resultDict objectForKey:(__bridge NSString*)kSecAttrIssuer];
    
    if (issuer && certIssuer)
    {
        *issuer = [[NSString alloc] initWithData:certIssuer encoding:NSASCIIStringEncoding];
    }
    
    SecIdentityRef identityRef = (__bridge_retained SecIdentityRef)[resultDict objectForKey:(__bridge NSString*)kSecValueRef];
    return identityRef;
}

@end
