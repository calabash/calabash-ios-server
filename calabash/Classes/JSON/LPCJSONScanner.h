//
//  CJSONScanner.h
//  TouchCode
//
//  Created by Jonathan Wight on 12/07/2005.
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

#import "LPCDataScanner.h"

enum {
    kLPJSONScannerOptions_MutableContainers = 0x1,
    kLPJSONScannerOptions_MutableLeaves = 0x2,
};
typedef NSUInteger LPEJSONScannerOptions;

/// CDataScanner subclass that understands JSON syntax natively. You should generally use CJSONDeserializer instead of this class. (TODO - this could have been a category?)
@interface LPCJSONScanner : LPCDataScanner {
	BOOL strictEscapeCodes;
    
	NSStringEncoding allowedEncoding;
    LPEJSONScannerOptions options;
}

@property (readwrite, nonatomic, assign) BOOL strictEscapeCodes;
@property (strong, nonatomic) id nullObject;
@property (readwrite, nonatomic, assign) NSStringEncoding allowedEncoding;
@property (readwrite, nonatomic, assign) LPEJSONScannerOptions options;

- (BOOL)setData:(NSData *)inData error:(NSError **)outError;

- (BOOL)scanJSONObject:(id *)outObject error:(NSError **)outError;
- (BOOL)scanJSONDictionary:(NSDictionary **)outDictionary error:(NSError **)outError;
- (BOOL)scanJSONArray:(NSArray **)outArray error:(NSError **)outError;
- (BOOL)scanJSONStringConstant:(NSString **)outStringConstant error:(NSError **)outError;
- (BOOL)scanJSONNumberConstant:(NSNumber **)outNumberConstant error:(NSError **)outError;

@end

extern NSString *const kLPJSONScannerErrorDomain /* = @"kJSONScannerErrorDomain" */;

typedef enum {
    
    // Fundamental scanning errors
    kLPJSONScannerErrorCode_NothingToScan = -11, 
    kLPJSONScannerErrorCode_CouldNotDecodeData = -12, 
    kLPJSONScannerErrorCode_CouldNotSerializeData = -13,
    kLPJSONScannerErrorCode_CouldNotSerializeObject = -14, 
    kLPJSONScannerErrorCode_CouldNotScanObject = -15, 
    
    // Dictionary scanning
    kLPJSONScannerErrorCode_DictionaryStartCharacterMissing = -101, 
    kLPJSONScannerErrorCode_DictionaryKeyScanFailed = -102, 
    kLPJSONScannerErrorCode_DictionaryKeyNotTerminated = -103, 
    kLPJSONScannerErrorCode_DictionaryValueScanFailed = -104, 
    kLPJSONScannerErrorCode_DictionaryKeyValuePairNoDelimiter = -105, 
    kLPJSONScannerErrorCode_DictionaryNotTerminated = -106, 
    
    // Array scanning
    kLPJSONScannerErrorCode_ArrayStartCharacterMissing = -201, 
    kLPJSONScannerErrorCode_ArrayValueScanFailed = -202, 
    kLPJSONScannerErrorCode_ArrayValueIsNull = -203, 
    kLPJSONScannerErrorCode_ArrayNotTerminated = -204,
    
    // String scanning
    kLPJSONScannerErrorCode_StringNotStartedWithBackslash = -301, 
    kLPJSONScannerErrorCode_StringUnicodeNotDecoded = -302, 
    kLPJSONScannerErrorCode_StringUnknownEscapeCode = -303, 
    kLPJSONScannerErrorCode_StringNotTerminated = -304,
    
    // Number scanning
    kLPJSONScannerErrorCode_NumberNotScannable = -401
    
} LPEJSONScannerErrorCode;
