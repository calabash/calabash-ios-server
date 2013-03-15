//
//  StaticResourcesRoute.m
//  Frank
//
//  Created by phodgson on 5/30/10.
//  Copyright 2010 ThoughtWorks. See NOTICE file for details.
//
#import "LPStaticResourcesRoute.h"

#import "LPHTTPResponse.h"
#import "LPHTTPDataResponse.h"
#import "LPRouter.h"

@interface LPStaticResourcesRoute ()
@property (nonatomic, retain) NSString *staticResourceDirectoryPath;
@end

@implementation LPStaticResourcesRoute

- (id) initWithStaticResourceSubDir:(NSString *)resourceSubdir
{
	self = [super init];
	if (self != nil) {
		self.staticResourceDirectoryPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:resourceSubdir];
	}
	return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
	if([path isEqualToString: @"/"] || path.length == 0) {
		return NO;
	}
	
    return [method isEqualToString:@"GET"];
}

#pragma mark Route implementation
- (NSObject<LPHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path{

	// start by looking for a file at the specified path, starting from the bundle root
	NSString *fullPathToRequestedResource = [self.staticResourceDirectoryPath stringByAppendingPathComponent: path];
	BOOL isDir = YES;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:fullPathToRequestedResource
													   isDirectory:&isDir];
	
	// The path is actually a folder, attempt index.html in this case.
	if(exists && isDir) {
		fullPathToRequestedResource = [fullPathToRequestedResource stringByAppendingPathComponent: @"index.html"];
	}
	// the construct is weird
	exists = [[NSFileManager defaultManager] fileExistsAtPath:fullPathToRequestedResource
												  isDirectory:&isDir];
	
	// there's nothing we can do with a folder, so return nil when that happens
	if(isDir)
	{
		return nil;
	}
	
	NSData *data = [[NSData alloc] initWithContentsOfFile: fullPathToRequestedResource];
	LPHTTPDataResponse *response = [[LPHTTPDataResponse alloc] initWithData: data];
	return response;
}

@end