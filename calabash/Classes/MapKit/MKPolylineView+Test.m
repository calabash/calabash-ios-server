//
//  MKPolylineView+Test.m
//
//  Created by Nicholas Albion on 27/07/12.

#import "MKPolylineView+Test.h"

@implementation MKPolylineView (Test)


/**
 * @return {"width: 1, "color":[r,g,b], "points":[[lat,lon], ...]}
 */
- (NSString *) calDebugDescription {
  int count = self.polyline.pointCount;
  CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * count);
  NSRange range = NSMakeRange(0, count);
  [[self polyline] getCoordinates:coords range:range];

  CGFloat lineWidth = self.lineWidth;

  CGFloat red, green, blue, alpha;
  [[self strokeColor] getRed:&red green:&green blue:&blue alpha:&alpha];

  NSString *str = [NSString stringWithFormat:@"{\"width\":%F, \"color\":[%d, %d, %d], \"points\":[", lineWidth, (int) (red * 255), (int) (green * 255), (int) (blue * 255)];

  for (int i = 0; i < count; i++) {
    if (i != 0) {
      str = [str stringByAppendingString:@","];
    }
    str = [str stringByAppendingFormat:@"[%F,%F]", coords[i].latitude, coords[i].longitude];
  }
  str = [str stringByAppendingFormat:@"]}"];

  free(coords);
  return str;
}

@end
