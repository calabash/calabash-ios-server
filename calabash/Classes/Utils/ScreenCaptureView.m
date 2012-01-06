#import "ScreenCaptureView.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>



@interface ScreenCaptureView(Private)
- (void) writeVideoFrameAtTime:(CMTime)time;
@end

@implementation ScreenCaptureView

@synthesize currentScreen, frameRate, delegate;

- (void) initialize {
	// Initialization code
//	self.clearsContextBeforeDrawing = YES;
	self.currentScreen = nil;
	self.frameRate = 10.0f;     //10 frames per seconds
	_recording = false;
	videoWriter = nil;
	videoWriterInput = nil;
	avAdaptor = nil;
	startedAt = nil;
	bitmapData = NULL;
}

- (id) init {
	self = [super init];
	if (self) {
		[self initialize];
	}
	return self;
}

- (CGContextRef) createBitmapContextOfSize:(CGSize) size {
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	
	bitmapBytesPerRow   = (size.width * 4);
	bitmapByteCount     = (bitmapBytesPerRow * size.height);
	colorSpace = CGColorSpaceCreateDeviceRGB();
	if (bitmapData != NULL) {
		free(bitmapData);
	}
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL) {
		fprintf (stderr, "Memory not allocated!");
		return NULL;
	}
	
	context = CGBitmapContextCreate (bitmapData,
									 size.width,
									 size.height,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaNoneSkipFirst);
	
	CGContextSetAllowsAntialiasing(context,NO);
	if (context== NULL) {
		free (bitmapData);
		fprintf (stderr, "Context not created!");
		return NULL;
	}
	CGColorSpaceRelease( colorSpace );
	
	return context;
}

//static int frameCount = 0;            //debugging
- (void) recordFrame {
    if (!_recording) {return;}
//    NSLog(@"recordFrame");
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
//    
//    dispatch_async(queue, ^{
        NSDate* start = [NSDate date];
//        NSLog(@"recordFrame: %@",start);
//        // Create a graphics context with the target size
//        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
//        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        CGSize imageSize = [[UIScreen mainScreen] bounds].size;
        //    if (NULL != UIGraphicsBeginImageContextWithOptions)
        //        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
        //    else
        //        UIGraphicsBeginImageContext(imageSize);
        
        //    CGContextRef context = UIGraphicsGetCurrentContext();
        
        
        CGContextRef context = [self createBitmapContextOfSize:imageSize];
        
        //not sure why this is necessary...image renders upside-down and mirrored
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, imageSize.height);
        CGContextConcatCTM(context, flipVertical);
        
        // Iterate over every window from back to front
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
        {
//            if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
//            {
                //            // -renderInContext: renders in the coordinate space of the layer,
                //            // so we must first apply the layer's geometry to the graphics context
                CGContextSaveGState(context);
                //            // Center the context around the window's anchor point
                CGContextTranslateCTM(context, [window center].x, [window center].y);
                //            // Apply the window's transform about the anchor point
                CGContextConcatCTM(context, [window transform]);
                //            // Offset by the portion of the bounds left of and above the anchor point
                CGContextTranslateCTM(context,
                                      -[window bounds].size.width * [[window layer] anchorPoint].x,
                                    -[window bounds].size.height * [[window layer] anchorPoint].y);

                [[window layer] renderInContext:context];
                
                // Restore the context
                CGContextRestoreGState(context);
           // }
        }
        //    
        //    // Retrieve the screenshot image
        //    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        //    
        //    UIGraphicsEndImageContext();
        
        //	[self.layer renderInContext:context];
        
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        UIImage* background = [UIImage imageWithCGImage: cgImage];
        CGImageRelease(cgImage);
     self.currentScreen = background;
    
//    NSLog(@"capture image");
//    UIImage *image = nil;
//	CGImageRef cgScreen = UIGetScreenImage();
//	if (cgScreen) {
//            NSLog(@"capture image OK");
//            image = [UIImage imageWithCGImage:cgScreen];
//            self.currentScreen = image;
//    } else }
//    
//	CGImageRelease(cgScreen);
//
        
        
        
        //debugging
        //if (frameCount < 40) {
        //      NSString* filename = [NSString stringWithFormat:@"Documents/frame_%d.png", frameCount];
        //      NSString* pngPath = [NSHomeDirectory() stringByAppendingPathComponent:filename];
        //      [UIImagePNGRepresentation(self.currentScreen) writeToFile: pngPath atomically: YES];
        //      frameCount++;
        //}
        
        //NOTE:  to record a scrollview while it is scrolling you need to implement your UIScrollViewDelegate such that it calls
        //       'setNeedsDisplay' on the ScreenCaptureView.
  //  if (image) {
       // @synchronized(self) {
            if (_recording) {
                float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
                [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000)];
            }
        //}
        
   // }
        
        float processingSeconds = [[NSDate date] timeIntervalSinceDate:start];
        float delayRemaining = (1.0 / self.frameRate) - processingSeconds;
        
        
//        NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:delayRemaining] interval:0 target:self selector:@selector(recordFrame) userInfo:nil repeats:NO];
//    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
//    [runloop addTimer:timer forMode:NSDefaultRunLoopMode];
////    [runloop addTimer:timer forMode:UITrackingRunLoopMode];
//        [timer release];
//        
    [self performSelector:@selector(recordFrame) withObject:nil afterDelay:delayRemaining > 0.0 ? delayRemaining : 0.01];    
//        
//        CGContextRelease(context);
        
        //redraw at the specified framerate
    
//    });
    
    
	
}

- (void) cleanupWriter {
	[avAdaptor release];
	avAdaptor = nil;
	
	[videoWriterInput release];
	videoWriterInput = nil;
	
	[videoWriter release];
	videoWriter = nil;
	
	[startedAt release];
	startedAt = nil;
	
	if (bitmapData != NULL) {
		free(bitmapData);
		bitmapData = NULL;
	}
}

- (void)dealloc {
	[self cleanupWriter];
	[super dealloc];
}

- (NSURL*) tempFileURL {
	NSString* outputPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"output.mp4"];
	NSURL* outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:outputPath]) {
		NSError* error;
		if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
			NSLog(@"Could not delete old recording file at path:  %@", outputPath);
		}
	}
	
	[outputPath release];
	return [outputURL autorelease];
}

-(BOOL) setUpWriter {
	NSError* error = nil;
	videoWriter = [[AVAssetWriter alloc] initWithURL:[self tempFileURL] fileType:AVFileTypeQuickTimeMovie error:&error];
	NSParameterAssert(videoWriter);
	
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
	//Configure video
	NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:1024.0*1024.0], AVVideoAverageBitRateKey,
										   nil ];
	
	NSDictionary* videoSettings = 
    [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:imageSize.width], AVVideoWidthKey,
								   [NSNumber numberWithInt:imageSize.height], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];
	
	videoWriterInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings] retain];
	
	NSParameterAssert(videoWriterInput);
	videoWriterInput.expectsMediaDataInRealTime = YES;
	NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
	
	avAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes] retain];
	
	//add input
	[videoWriter addInput:videoWriterInput];
	[videoWriter startWriting];
	[videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
	
	return YES;
}

- (NSString *)completeRecordingSession {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[videoWriterInput markAsFinished];
	
	// Wait for the video
	int status = videoWriter.status;
	while (status == AVAssetWriterStatusUnknown) {
		NSLog(@"Waiting...");
		[NSThread sleepForTimeInterval:0.5f];
		status = videoWriter.status;
	}
	
    NSString *outputPath = nil;
	@synchronized(self) {
		BOOL success = [videoWriter finishWriting];
		if (!success) {
			NSLog(@"finishWriting returned NO");
		}
		
		[self cleanupWriter];
		
		id delegateObj = self.delegate;
        
        NSLog(@"ready to write");

		outputPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"output.mp4"];
		NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
		
		NSLog(@"Completed recording, file is stored at:  %@", outputURL);
		if ([delegateObj respondsToSelector:@selector(recordingFinished:)]) {
			[delegateObj performSelectorOnMainThread:@selector(recordingFinished:) withObject:(success ? outputURL : nil) waitUntilDone:YES];
		}
		
		[outputURL release];
	}
	
	[pool drain];
    return [outputPath autorelease];
}

- (bool) startRecording {
	bool result = NO;
	@synchronized(self) {
		if (! _recording) {
			result = [self setUpWriter];
			startedAt = [[NSDate date] retain];
			_recording = true;
            [self recordFrame];
		}
	}
	
	return result;
}

- (NSString *)stopRecording {
	@synchronized(self) {
		if (_recording) {
			_recording = false;
            NSLog(@"complete recording");
			return [self completeRecordingSession];
		}
	}
    return nil;
}

-(void) writeVideoFrameAtTime:(CMTime)time {
	if (![videoWriterInput isReadyForMoreMediaData]) {
		NSLog(@"Not ready for video data");
	}
	else {
		@synchronized (self) {
			UIImage* newFrame = [self.currentScreen retain];
			CVPixelBufferRef pixelBuffer = NULL;
			CGImageRef cgImage = CGImageCreateCopy([newFrame CGImage]);
			CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
			
			int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
			if(status != 0){
				//could not get a buffer from the pool
				NSLog(@"Error creating pixel buffer:  status=%d", status);
			}
			// set image data into pixel buffer
			CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
			uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
			CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  //XXX:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
			
			if(status == 0){
				BOOL success = [avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
				if (!success)
					NSLog(@"Warning:  Unable to write buffer to video");
			}
			
			//clean up
			[newFrame release];
			CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
			CVPixelBufferRelease( pixelBuffer );
			CFRelease(image);
			CGImageRelease(cgImage);
		}
		
	}
	
}

@end