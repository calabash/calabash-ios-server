//
//  MKMapView+ZoomLevel.h
//  http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

- (NSUInteger) zoomLevel;

@end