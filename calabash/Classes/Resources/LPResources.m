//
//  Resources.m
/* Copyright (c) 2010 - 2011, Quasidea Development, LLC
 * For more information, please go to http://www.quasidea.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
*/
// This file has been modified by Karl Krukow <karl@lesspainful.com>
/*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
*/

#import "LPResources.h"


@implementation LPResources

static const short _base64DecodingTable[256] = {-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2, -2, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2, -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2};


+ (NSData *) decodeBase64WithString:(NSString *) strBase64 {
  const char *objPointer = [strBase64 cStringUsingEncoding:NSASCIIStringEncoding];
  if (objPointer == NULL) {return nil;}
  size_t intLength = strlen(objPointer);
  int intCurrent;
  int i = 0, j = 0, k;

  unsigned char *objResult;
  objResult = calloc(intLength, sizeof(unsigned char));

  // Run through the whole string, converting as we go
  while (((intCurrent = *objPointer++) != '\0') && (intLength-- > 0)) {
    if (intCurrent == '=') {
      if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
        // the padding character is invalid at this point -- so this entire string is invalid
        free(objResult);
        return nil;
      }
      continue;
    }

    intCurrent = _base64DecodingTable[intCurrent];
    if (intCurrent == -1) {
      // we're at a whitespace -- simply skip over
      continue;
    } else if (intCurrent == -2) {
      // we're at an invalid character
      free(objResult);
      return nil;
    }

    switch (i % 4) {
      case 0: objResult[j] = intCurrent << 2;
        break;

      case 1: objResult[j++] |= intCurrent >> 4;
        objResult[j] = (intCurrent & 0x0f) << 4;
        break;

      case 2: objResult[j++] |= intCurrent >> 2;
        objResult[j] = (intCurrent & 0x03) << 6;
        break;

      case 3: objResult[j++] |= intCurrent;
        break;
    }
    i++;
  }

  // mop things up if we ended on a boundary
  k = j;
  if (intCurrent == '=') {
    switch (i % 4) {
      case 1:
        // Invalid state
        free(objResult);
        return nil;

      case 2: k++;
        // flow through
      case 3: objResult[k] = 0;
    }
  }

  // Cleanup and setup the return NSData
  return [[[NSData alloc]
          initWithBytesNoCopy:objResult length:j freeWhenDone:YES] autorelease];
}


+ (NSArray *) eventsFromEncoding:(NSString *) encoded {
  NSData *data = [self decodeBase64WithString:encoded];
  NSString *err = nil;
  NSPropertyListFormat format;
  return [NSPropertyListSerialization propertyListFromData:data
                                          mutabilityOption:NSPropertyListImmutable
                                                    format:&format
                                          errorDescription:&err];
}


+ (NSArray *) transformEvents:(NSArray *) eventsRecord toPoint:(CGPoint) _viewCenter {
  NSMutableArray *transformedEvents = [NSMutableArray arrayWithCapacity:[eventsRecord count]];

//    NSRange iosRange = NSMakeRange(32, 4);

  NSRange xRange = NSMakeRange(48, 4);
  NSRange yRange = NSMakeRange(52, 4);

  CGPoint currentPoint, lastPoint = CGRectNull.origin;
  CGPoint delta = CGPointZero;
  float x_buf[1];
  float y_buf[1];
//    unsigned short *ios_buf[4];
  for (NSDictionary *d in eventsRecord) {

    NSDictionary *loc = [d valueForKey:@"Location"];
    NSDictionary *windowLoc = [d valueForKey:@"WindowLocation"];
    if (loc == nil || windowLoc == nil || [[d valueForKey:@"Type"]
            integerValue] == 50) {
      continue;
    }

    currentPoint = CGPointMake([[windowLoc valueForKey:@"X"] floatValue],
            [[windowLoc valueForKey:@"Y"] floatValue]);
    if (!CGPointEqualToPoint(CGRectNull.origin, lastPoint)) {
      delta = CGPointMake(delta.x + (currentPoint.x - lastPoint.x),
              delta.y + (currentPoint.y - lastPoint.y));
    }


    NSMutableDictionary *newLoc = [NSMutableDictionary dictionaryWithDictionary:loc];
    NSMutableDictionary *newWindowLoc = [NSMutableDictionary dictionaryWithDictionary:windowLoc];

    [newLoc setValue:[NSNumber numberWithFloat:_viewCenter.x + delta.x]
              forKey:@"X"];
    [newLoc setValue:[NSNumber numberWithFloat:_viewCenter.y + delta.y]
              forKey:@"Y"];

    [newWindowLoc setValue:[NSNumber numberWithFloat:_viewCenter.x + delta.x]
                    forKey:@"X"];
    [newWindowLoc setValue:[NSNumber numberWithFloat:_viewCenter.y + delta.y]
                    forKey:@"Y"];


    NSData *data = [d valueForKey:@"Data"];

    [data getBytes:x_buf range:xRange];
    [data getBytes:y_buf range:yRange];
//        [data getBytes:ios_buf   range:iosRange];
//        NSData *iosData = [[NSData alloc] initWithBytes:ios_buf length:4];
//        NSLog(@"iosData: %@",iosData);
//        [iosData release];

    NSMutableDictionary *newD = [NSMutableDictionary dictionaryWithDictionary:d];
    NSMutableData *newData = [NSMutableData dataWithData:data];


    x_buf[0] = _viewCenter.x + delta.x;
    y_buf[0] = _viewCenter.y + delta.y;
    [newData replaceBytesInRange:xRange withBytes:x_buf];
    [newData replaceBytesInRange:yRange withBytes:y_buf];


    [newD setValue:newData forKey:@"Data"];
    [newD setValue:newLoc forKey:@"Location"];
    [newD setValue:newWindowLoc forKey:@"WindowLocation"];

    [transformedEvents addObject:newD];
    lastPoint = currentPoint;
  }
  return transformedEvents;
}


//https://www.maa.org/EbusPPRO/pdf/meg_ch12.pdf
//Theorem 12.8 - fundamental theorem of Affine Transformations
+ (NSArray *) interpolateEvents:(NSArray *) baseEvents fromPoint:(CGPoint) startAt toPoint:(CGPoint) endAt {
  NSMutableArray *transformedEvents = [NSMutableArray arrayWithCapacity:[baseEvents count]];

  NSDictionary *baseStart = [[baseEvents objectAtIndex:0]
          valueForKey:@"WindowLocation"];
  NSDictionary *baseCenter = [[baseEvents objectAtIndex:[baseEvents count] / 2]
          valueForKey:@"WindowLocation"];
  NSDictionary *baseEnd = [[baseEvents objectAtIndex:[baseEvents count] - 1]
          valueForKey:@"WindowLocation"];

  CGPoint centerAt = CGPointMake(startAt.x + (endAt.x - startAt.x) / 2 + 3,
          startAt.y + (endAt.y - startAt.y) / 2 + 3);

  CGPoint p = CGPointMake([[baseStart valueForKey:@"X"] floatValue],
          [[baseStart valueForKey:@"Y"] floatValue]);

  CGPoint q = CGPointMake([[baseCenter valueForKey:@"X"] floatValue],
          [[baseCenter valueForKey:@"Y"] floatValue]);

  CGPoint r = CGPointMake([[baseEnd valueForKey:@"X"] floatValue],
          [[baseEnd valueForKey:@"Y"] floatValue]);

  CGFloat a1 = q.x - p.x;
  CGFloat c1 = r.x - p.x;
  CGFloat b1 = q.y - p.y;
  CGFloat d1 = r.y - p.y;

  CGFloat a2 = centerAt.x - startAt.x;
  CGFloat c2 = endAt.x - startAt.x;
  CGFloat b2 = centerAt.y - startAt.y;
  CGFloat d2 = endAt.y - startAt.y;

  CGAffineTransform f = CGAffineTransformMake(a1, b1, c1, d1, p.x, p.y);

  CGAffineTransform f_inv = CGAffineTransformInvert(f);

  CGAffineTransform g = CGAffineTransformMake(a2, b2, c2, d2, startAt.x,
          startAt.y);

  CGAffineTransform interpolate = CGAffineTransformConcat(f_inv, g);

//    CGPoint should_be_startAt = CGPointApplyAffineTransform(p, interpolate);
//    CGPoint should_be_centerAt = CGPointApplyAffineTransform(q, interpolate);
//    CGPoint should_be_endAt = CGPointApplyAffineTransform(r, interpolate);
//
//
//    NSLog(@"should_be_start_at = [ %@]", CGPointCreateDictionaryRepresentation(should_be_startAt));
//
//    NSLog(@"should_be_center_at = [ %@]", CGPointCreateDictionaryRepresentation(should_be_centerAt));
//    NSLog(@"should_be_should_be_endAt = [ %@]", CGPointCreateDictionaryRepresentation(should_be_endAt));


  NSRange xRange = NSMakeRange(48, 4);
  NSRange yRange = NSMakeRange(52, 4);

  CGPoint currentPoint, translatedPoint;

  float x_buf[1];
  float y_buf[1];
  //    unsigned short *ios_buf[4];
  for (NSDictionary *d in baseEvents) {

    NSDictionary *loc = [d valueForKey:@"Location"];
    NSDictionary *windowLoc = [d valueForKey:@"WindowLocation"];
    if (loc == nil || windowLoc == nil || [[d valueForKey:@"Type"]
            integerValue] == 50) {
      continue;
    }

    currentPoint = CGPointMake([[windowLoc valueForKey:@"X"] floatValue],
            [[windowLoc valueForKey:@"Y"] floatValue]);

    NSMutableDictionary *newLoc = [NSMutableDictionary dictionaryWithDictionary:loc];
    NSMutableDictionary *newWindowLoc = [NSMutableDictionary dictionaryWithDictionary:windowLoc];

    translatedPoint = CGPointApplyAffineTransform(currentPoint, interpolate);

    [newLoc setValue:[NSNumber numberWithFloat:translatedPoint.x] forKey:@"X"];
    [newLoc setValue:[NSNumber numberWithFloat:translatedPoint.y] forKey:@"Y"];

    [newWindowLoc setValue:[NSNumber numberWithFloat:translatedPoint.x]
                    forKey:@"X"];
    [newWindowLoc setValue:[NSNumber numberWithFloat:translatedPoint.y]
                    forKey:@"Y"];


    NSData *data = [d valueForKey:@"Data"];

    [data getBytes:x_buf range:xRange];
    [data getBytes:y_buf range:yRange];
    //        [data getBytes:ios_buf   range:iosRange];
    //        NSData *iosData = [[NSData alloc] initWithBytes:ios_buf length:4];
    //        NSLog(@"iosData: %@",iosData);
    //        [iosData release];

    NSMutableDictionary *newD = [NSMutableDictionary dictionaryWithDictionary:d];
    NSMutableData *newData = [NSMutableData dataWithData:data];


    x_buf[0] = translatedPoint.x;
    y_buf[0] = translatedPoint.y;
    [newData replaceBytesInRange:xRange withBytes:x_buf];
    [newData replaceBytesInRange:yRange withBytes:y_buf];


    [newD setValue:newData forKey:@"Data"];
    [newD setValue:newLoc forKey:@"Location"];
    [newD setValue:newWindowLoc forKey:@"WindowLocation"];

    [transformedEvents addObject:newD];
  }
  return transformedEvents;
}

@end
