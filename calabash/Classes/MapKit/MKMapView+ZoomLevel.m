//
//  MKMapView+ZoomLevel.h
//  http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/

#import "MKMapView+ZoomLevel.h"

#define CAL_MERCATOR_OFFSET 268435456
#define CAL_MERCATOR_RADIUS 85445659.44705395

@implementation MKMapView (ZoomLevel)

#pragma mark -
#pragma mark Map conversion methods

- (double) calLongitudeToPixelSpaceX:(double) longitude {
  return round(CAL_MERCATOR_OFFSET + CAL_MERCATOR_RADIUS * longitude * M_PI / 180.0);
}


- (double) calLatitudeToPixelSpaceY:(double) latitude {
  return round(CAL_MERCATOR_OFFSET - CAL_MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}


- (double) calPixelSpaceXToLongitude:(double) pixelX {
  return ((round(pixelX) - CAL_MERCATOR_OFFSET) / CAL_MERCATOR_RADIUS) * 180.0 / M_PI;
}


- (double) calPixelSpaceYToLatitude:(double) pixelY {
  return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - CAL_MERCATOR_OFFSET) / CAL_MERCATOR_RADIUS))) * 180.0 / M_PI;
}

#pragma mark -
#pragma mark Helper methods

- (MKCoordinateSpan) calCoordinateSpanWithMapView:(MKMapView *) mapView centerCoordinate:(CLLocationCoordinate2D) centerCoordinate andZoomLevel:(NSUInteger) zoomLevel {
  // convert center coordiate to pixel space
  double centerPixelX = [self calLongitudeToPixelSpaceX:centerCoordinate.longitude];
  double centerPixelY = [self calLatitudeToPixelSpaceY:centerCoordinate.latitude];

  // determine the scale value from the zoom level
  NSInteger zoomExponent = 20 - zoomLevel;
  double zoomScale = pow(2, zoomExponent);

  // scale the map’s size in pixel space
  CGSize mapSizeInPixels = mapView.bounds.size;
  double scaledMapWidth = mapSizeInPixels.width * zoomScale;
  double scaledMapHeight = mapSizeInPixels.height * zoomScale;

  // figure out the position of the top-left pixel
  double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
  double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);

  // find delta between left and right longitudes
  CLLocationDegrees minLng = [self calPixelSpaceXToLongitude:topLeftPixelX];
  CLLocationDegrees maxLng = [self calPixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
  CLLocationDegrees longitudeDelta = maxLng - minLng;

  // find delta between top and bottom latitudes
  CLLocationDegrees minLat = [self calPixelSpaceYToLatitude:topLeftPixelY];
  CLLocationDegrees maxLat = [self calPixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
  CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);

  // create and return the lat/lng span
  MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
  return span;
}


- (NSUInteger) calZoomLevelWithMapView:(MKMapView *) mapView {
  MKCoordinateRegion region = self.region;

  double centerPixelX = [self calLongitudeToPixelSpaceX:region.center.longitude];
  double topLeftPixelX = [self calLongitudeToPixelSpaceX:region.center.longitude - region.span.longitudeDelta / 2];

  double scaledMapWidth = (centerPixelX - topLeftPixelX) * 2;
  CGSize mapSizeInPixels = mapView.bounds.size;
  double zoomScale = scaledMapWidth / mapSizeInPixels.width;
  double zoomExponent = log(zoomScale) / log(2);
  double zoomLevel = 20 - zoomExponent;
  // TODO suspicious conversion of double to NSUInteger in MKMapView+ZoomLevel.m
  return zoomLevel;
}

#pragma mark -
#pragma mark Public methods

- (void) calSetCenterCoordinate:(CLLocationCoordinate2D) centerCoordinate zoomLevel:(NSUInteger) zoomLevel animated:(BOOL) animated {
  // clamp large numbers to 28
  zoomLevel = MIN(zoomLevel, 28);

  // use the zoom level to compute the region
  MKCoordinateSpan span = [self calCoordinateSpanWithMapView:self centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
  MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);

  // set the region like normal
  [self setRegion:region animated:animated];
}


- (NSNumber *) calSetZoomLevel:(int) zoomLevel {
  CLLocationCoordinate2D center = self.centerCoordinate;
  [self calSetCenterCoordinate:center zoomLevel:zoomLevel animated:NO];

  NSUInteger newZoomLevel = [self calZoomLevel];
  BOOL success = (newZoomLevel == zoomLevel);
  return [NSNumber numberWithBool:success];
}


- (NSNumber *) calZoomIn {
  NSUInteger prevZoomLevel = [self calZoomLevel];
  NSUInteger reqZoomLevel = prevZoomLevel + 1;
  return [self calSetZoomLevel:reqZoomLevel];
}


- (NSNumber *) calZoomOut {
  NSUInteger prevZoomLevel = [self calZoomLevel];
  NSUInteger reqZoomLevel = prevZoomLevel - 1;
  return [self calSetZoomLevel:reqZoomLevel];
}


- (NSUInteger) calZoomLevel {
  NSUInteger zoom = [self calZoomLevelWithMapView:self];
  return zoom;
}

@end