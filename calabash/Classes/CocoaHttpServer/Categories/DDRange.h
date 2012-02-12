/**
 * LPDDRange is the functional equivalent of a 64 bit NSRange.
 * The HTTP Server is designed to support very large files.
 * On 32 bit architectures (ppc, i386) NSRange uses unsigned 32 bit integers.
 * This only supports a range of up to 4 gigabytes.
 * By defining our own variant, we can support a range up to 16 exabytes.
 * 
 * All effort is given such that LPDDRange functions EXACTLY the same as NSRange.
**/

#import <Foundation/NSValue.h>
#import <Foundation/NSObjCRuntime.h>

@class NSString;

typedef struct _LPDDRange {
    UInt64 location;
    UInt64 length;
} LPDDRange;

typedef LPDDRange *LPDDRangePointer;

NS_INLINE LPDDRange LPDDMakeRange(UInt64 loc, UInt64 len) {
    LPDDRange r;
    r.location = loc;
    r.length = len;
    return r;
}

NS_INLINE UInt64 LPDDMaxRange(LPDDRange range) {
    return (range.location + range.length);
}

NS_INLINE BOOL LPDDLocationInRange(UInt64 loc, LPDDRange range) {
    return (loc - range.location < range.length);
}

NS_INLINE BOOL LPDDEqualRanges(LPDDRange range1, LPDDRange range2) {
    return ((range1.location == range2.location) && (range1.length == range2.length));
}

FOUNDATION_EXPORT LPDDRange LPDDUnionRange(LPDDRange range1, LPDDRange range2);
FOUNDATION_EXPORT LPDDRange LPDDIntersectionRange(LPDDRange range1, LPDDRange range2);
FOUNDATION_EXPORT NSString *LPDDStringFromRange(LPDDRange range);
FOUNDATION_EXPORT LPDDRange LPDDRangeFromString(NSString *aString);

NSInteger LPDDRangeCompare(LPDDRangePointer pDDRange1, LPDDRangePointer pDDRange2);

@interface NSValue (LPNSValueDDRangeExtensions)

+ (NSValue *)valueWithDDRange:(LPDDRange)range;
- (LPDDRange)ddrangeValue;

- (NSInteger)ddrangeCompare:(NSValue *)ddrangeValue;

@end
