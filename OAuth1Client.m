//
//  OAuth1Client.m
//
//  Created by Rex Sheng on 10/24/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "OAuth1Client.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation NSURL (OAuthAdditions)

+ (NSDictionary *)ab_parseURLQueryString:(NSString *)query
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	for(NSString *pair in pairs) {
		NSArray *keyValue = [pair componentsSeparatedByString:@"="];
		if([keyValue count] == 2) {
			NSString *key = keyValue[0];
			NSString *value = keyValue[1];
			value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			if(key && value)
				dict[key] = value;
		}
	}
	return [NSDictionary dictionaryWithDictionary:dict];
}

@end

@implementation NSString (OAuthAdditions)

- (NSString *)ab_RFC3986EncodedString // UTF-8 encodes prior to URL encoding
{
	NSMutableString *result = [NSMutableString string];
	const char *p = [self UTF8String];
	unsigned char c;
	
	for(; (c = *p); p++)
	{
		switch(c)
		{
			case '0' ... '9':
			case 'A' ... 'Z':
			case 'a' ... 'z':
			case '.':
			case '-':
			case '~':
			case '_':
				[result appendFormat:@"%c", c];
				break;
			default:
				[result appendFormat:@"%%%02X", c];
		}
	}
	return result;
}

+ (NSString *)ab_GUID
{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	NSString *ident = [NSString stringWithString:(__bridge NSString *)uuidStringRef];
	CFRelease(uuidStringRef);
	return ident;
}

@end

static NSString * AFBase64EncodedStringFromData(NSData *data) {
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

static NSData *HMAC_SHA1(NSString *data, NSString *key) {
	unsigned char buf[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [data UTF8String], [data length], buf);
	return [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
}

NSString *OAuthorizationHeader(NSURL *url, NSString *method, NSData *body, NSString *_oAuthConsumerKey, NSString *_oAuthConsumerSecret, NSString *_oAuthToken, NSString *_oAuthTokenSecret)
{
	NSString *_oAuthNonce = [NSString ab_GUID];
	NSString *_oAuthTimestamp = [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970] + 200];
	NSString *_oAuthSignatureMethod = @"HMAC-SHA1";
	NSString *_oAuthVersion = @"1.0";
	
	NSMutableDictionary *oAuthAuthorizationParameters = [NSMutableDictionary dictionary];
	oAuthAuthorizationParameters[@"oauth_nonce"] = _oAuthNonce;
	oAuthAuthorizationParameters[@"oauth_timestamp"] = _oAuthTimestamp;
	oAuthAuthorizationParameters[@"oauth_signature_method"] = _oAuthSignatureMethod;
	oAuthAuthorizationParameters[@"oauth_version"] = _oAuthVersion;
	oAuthAuthorizationParameters[@"oauth_consumer_key"] = _oAuthConsumerKey;
	if(_oAuthToken)
		oAuthAuthorizationParameters[@"oauth_token"] = _oAuthToken;
	
	// get query and body parameters
	NSDictionary *additionalQueryParameters = [NSURL ab_parseURLQueryString:[url query]];
	NSDictionary *additionalBodyParameters = nil;
	if (body) {
		NSString *string = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
		if(string) {
			additionalBodyParameters = [NSURL ab_parseURLQueryString:string];
		}
	}
	
	// combine all parameters
	NSMutableDictionary *parameters = [oAuthAuthorizationParameters mutableCopy];
	if(additionalQueryParameters) [parameters addEntriesFromDictionary:additionalQueryParameters];
	if(additionalBodyParameters) [parameters addEntriesFromDictionary:additionalBodyParameters];
	
	// -> UTF-8 -> RFC3986
	NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionary];
	for(NSString *key in parameters) {
		NSString *value = parameters[key];
		encodedParameters[[key ab_RFC3986EncodedString]] = [value ab_RFC3986EncodedString];
	}
	
	NSArray *sortedKeys = [[encodedParameters allKeys] sortedArrayUsingComparator:^NSComparisonResult(id key1, id key2) {
		NSComparisonResult r = [key1 compare:key2];
		if(r == NSOrderedSame) { // compare by value in this case
			NSString *value1 = encodedParameters[key1];
			NSString *value2 = encodedParameters[key2];
			return [value1 compare:value2];
		}
		return r;
	}];
	
	NSMutableArray *parameterArray = [NSMutableArray array];
	for(NSString *key in sortedKeys) {
		[parameterArray addObject:[NSString stringWithFormat:@"%@=%@", key, encodedParameters[key]]];
	}
	NSString *normalizedParameterString = [parameterArray componentsJoinedByString:@"&"];
	
	NSString *normalizedURLString = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];
	
	NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
									 [method ab_RFC3986EncodedString],
									 [normalizedURLString ab_RFC3986EncodedString],
									 [normalizedParameterString ab_RFC3986EncodedString]];
	
	NSString *key = [NSString stringWithFormat:@"%@&%@",
					 [_oAuthConsumerSecret ab_RFC3986EncodedString],
					 [_oAuthTokenSecret ab_RFC3986EncodedString]];
	
	NSData *signature = HMAC_SHA1(signatureBaseString, key);
	NSString *base64Signature = AFBase64EncodedStringFromData(signature);
	
	NSMutableDictionary *authorizationHeaderDictionary = [oAuthAuthorizationParameters mutableCopy];
	authorizationHeaderDictionary[@"oauth_signature"] = base64Signature;
	
	NSMutableArray *authorizationHeaderItems = [NSMutableArray array];
	for (NSString *key in authorizationHeaderDictionary) {
		NSString *value = authorizationHeaderDictionary[key];
		[authorizationHeaderItems addObject:[NSString stringWithFormat:@"%@=\"%@\"",
											 [key ab_RFC3986EncodedString],
											 [value ab_RFC3986EncodedString]]];
	}
	
	NSString *authorizationHeaderString = [authorizationHeaderItems componentsJoinedByString:@", "];
	authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", authorizationHeaderString];
	
	return authorizationHeaderString;
}

@implementation OAuth1Client
{
	NSString *key;
	NSString *secret;
}

@synthesize userToken, userTokenSecret=userSecret;

- (id)initWithBaseURL:(NSURL *)url
                  key:(NSString *)clientID
               secret:(NSString *)_secret
{
    if (self = [super initWithBaseURL:url]) {
		key = clientID;
		secret = _secret;
		userSecret = @"";
	}
	return self;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSMutableURLRequest *)request success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
	NSString *oauthString = OAuthorizationHeader(request.URL, request.HTTPMethod, request.HTTPBody, key, secret, userToken, userSecret);
	[request setHTTPShouldHandleCookies:NO];
	[request setValue:oauthString forHTTPHeaderField:@"Authorization"];
	return [super HTTPRequestOperationWithRequest:request success:success failure:failure];
}

@end
