//
//  CJSONDeserializer.h
//  TouchCode
//
//  Created by Jonathan Wight on 12/15/2005.
//  Copyright 2005 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

#import "LPCJSONScanner.h"

extern NSString *const kLPJSONDeserializerErrorDomain /* = @"CJSONDeserializerErrorDomain" */;

enum {
    kLPJSONDeserializationOptions_MutableContainers = kLPJSONScannerOptions_MutableContainers,
    kLPJSONDeserializationOptions_MutableLeaves = kLPJSONScannerOptions_MutableLeaves,
};
typedef NSUInteger LPEJSONDeserializationOptions;

@class LPCJSONScanner;

@interface LPCJSONDeserializer : NSObject {
    LPCJSONScanner *scanner;
    LPEJSONDeserializationOptions options;
}

@property (readwrite, nonatomic) LPCJSONScanner *scanner;
/// Object to return instead when a null encountered in the JSON. Defaults to NSNull. Setting to null causes the scanner to skip null values.
@property (unsafe_unretained, readwrite, nonatomic) id nullObject;
/// JSON must be encoded in Unicode (UTF-8, UTF-16 or UTF-32). Use this if you expect to get the JSON in another encoding.
@property (readwrite, nonatomic, assign) NSStringEncoding allowedEncoding;
@property (readwrite, nonatomic, assign) LPEJSONDeserializationOptions options;

+ (LPCJSONDeserializer *)deserializer;

- (id)deserialize:(NSData *)inData error:(NSError **)outError;

- (id)deserializeAsDictionary:(NSData *)inData error:(NSError **)outError;
- (id)deserializeAsArray:(NSData *)inData error:(NSError **)outError;

@end
