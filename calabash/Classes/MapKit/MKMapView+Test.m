//
//  MKMapView+Test.m
//  calabash
//
//  Created by Nicholas Albion on 3/08/12.

#import "MKMapView+Test.h"

@implementation MKMapView (Test)

- (NSString *) mapBounds {
  MKCoordinateRegion region = [self region];
  double dlat = region.span.latitudeDelta / 2;
  double dlon = region.span.longitudeDelta / 2;
  double top = region.center.latitude + dlat;
  double bottom = region.center.latitude - dlat;
  double left = region.center.longitude - dlon;
  double right = region.center.longitude + dlon;
  return [NSString stringWithFormat:@"{\"top\":%F, \"right\":%F, \"bottom\":%F, \"left\":%F}", top, right, bottom, left];
}


- (void) setCenterToLat:(double) lat lon:(double) lon {
  CLLocationCoordinate2D coordinate = (CLLocationCoordinate2D) {lat, lon};
  [self setCenterCoordinate:coordinate animated:NO];
}


- (void) panToLat:(double) lat lon:(double) lon {
  CLLocationCoordinate2D coordinate = (CLLocationCoordinate2D) {lat, lon};
  [self setCenterCoordinate:coordinate animated:YES];
}


- (NSString *) currentCenterLocation {
  CLLocationCoordinate2D center = self.centerCoordinate;
  return [NSString stringWithFormat:@"%3.6F,%3.6F", center.latitude, center.longitude];
}


- (void) showUserLocation:(NSString *) show {
  BOOL showUser = [@"false" isEqualToString:show] == NO;
  //    [self showsUserLocation:showUser];
  self.showsUserLocation = showUser;
}


/**
 * selects or deselects the named marker (AKA annotation)
 */
- (NSNumber *) tapMarkerByTitle:(NSString *) title {
  for (NSObject <MKAnnotation> *annotation in [self annotations]) {
    BOOL matched = [[annotation title] isEqualToString:title];
    if (!matched) {
      // If we can't match by title, perhaps we can match against something in the description
      // for iPhone 3.2 or better we can check the :description for the title
      NSString *regEx = [NSString stringWithFormat:@"[\\b_]%@\\b", title];
      NSRange r = [[annotation description] rangeOfString:regEx options:NSRegularExpressionSearch];
      if (r.location != NSNotFound) {
        matched = TRUE;
      }
      // for older phones, we could fall back to  [[annotation description] hasSuffix:title]
    }

    if (matched) {
      if ([[self selectedAnnotations] containsObject:annotation]) {
        [self deselectAnnotation:(id <MKAnnotation>) annotation animated:NO];
      } else {
        [self selectAnnotation:(id <MKAnnotation>) annotation animated:NO];
      }
      return [NSNumber numberWithBool:YES];
    }
  }

  return [NSNumber numberWithBool:NO];
}


/**
 * Provides useful information for a specified marker (MKAnnotation) using the annotation's "debugDescription" method
 * Your MKAnnotation subclass should implement debugDescription() to return a JSON string.  "focused" will be inserted if the marker has been tapped and focused by the user.
 *
 * @return nil or (for example)) {title:"My Marker", "latitude":-33.123456, "longitude":151.123456, "foo":"bar", "focused":true}
 */
- (NSString *) getMarkerByTitle:(NSString *) title {
  for (NSObject <MKAnnotation> *annotation in [self annotations]) {
    BOOL matched = [[annotation title] isEqualToString:title];
    if (!matched) {
      // If we can't match by title, perhaps we can match against something in the description
      // for iPhone 3.2 or better we can check the :description for the title
      NSString *regEx = [NSString stringWithFormat:@"[\\b_]%@\\b", title];
      NSRange r = [[annotation description] rangeOfString:regEx options:NSRegularExpressionSearch];
      if (r.location != NSNotFound) {
        matched = TRUE;
      }
      // for older phones, we could fall back to  [[annotation description] hasSuffix:title]
    }

    if (matched) {
      NSString *str = [annotation debugDescription];

      if ([[self selectedAnnotations] containsObject:annotation]) {
        //str = [str stringByReplacingOccurrencesOfString:@"}" withString:@", \"focused\":true}"];
        str = [str substringToIndex:([str length] - 1)];  // up to but not including index
        str = [str stringByAppendingString:@", \"focused\":true}"];
      }

      return str;
    }
  }
  return nil;
}

@end
