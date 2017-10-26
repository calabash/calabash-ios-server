#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPTouchUtils.h"

@interface LPTouchUtils (TEST)

@end

@interface LPTouchUtilsTest : XCTestCase

@end

@implementation LPTouchUtilsTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

@end

SpecBegin(LPTouchUtils)

describe(@"letter box offsets", ^{

  UIInterfaceOrientation portrait = UIInterfaceOrientationPortrait;
  UIInterfaceOrientation upsidedown = UIInterfaceOrientationPortraitUpsideDown;
  UIInterfaceOrientation left = UIInterfaceOrientationLandscapeLeft;
  UIInterfaceOrientation right = UIInterfaceOrientationLandscapeRight;

  __block CGFloat actual = CGFLOAT_MAX;

  describe(@".xOffsetFor4InchLetterBox:", ^{
    it (@"returns 0.0 in portrait orientations", ^{
      actual = [LPTouchUtils xOffsetFor4inchLetterBox:portrait];
      expect(actual).to.equal(0.0);
      actual = [LPTouchUtils xOffsetFor4inchLetterBox:upsidedown];
      expect(actual).to.equal(0.0);
    });

    it (@"returns 44.0 in landscape orientations", ^{
      actual = [LPTouchUtils xOffsetFor4inchLetterBox:left];
      expect(actual).to.equal(44.0);
      actual = [LPTouchUtils xOffsetFor4inchLetterBox:right];
      expect(actual).to.equal(44.0);
    });
  });

  describe(@".yOffsetFor4InchLetterBox:", ^{
    it (@"returns 44.0 in portrait orientations", ^{
      actual = [LPTouchUtils yOffsetFor4inchLetterBox:portrait];
      expect(actual).to.equal(44.0);
      actual = [LPTouchUtils yOffsetFor4inchLetterBox:upsidedown];
      expect(actual).to.equal(44.0);
    });

    it (@"returns 0.0 in landscape orientations", ^{
      actual = [LPTouchUtils yOffsetFor4inchLetterBox:left];
      expect(actual).to.equal(0.0);
      actual = [LPTouchUtils yOffsetFor4inchLetterBox:right];
      expect(actual).to.equal(0.0);
    });
  });

  describe(@".xOffsetForIPhone10LetterBox:", ^{
    it (@"returns 0.0 in portrait orientations", ^{
      actual = [LPTouchUtils xOffsetForIPhone10LetterBox:portrait];
      expect(actual).to.equal(0.0);
      actual = [LPTouchUtils xOffsetForIPhone10LetterBox:upsidedown];
      expect(actual).to.equal(0.0);
    });

    it (@"returns 94.0 in landscape orientations", ^{
      actual = [LPTouchUtils xOffsetForIPhone10LetterBox:left];
      expect(actual).to.equal(94.0);
      actual = [LPTouchUtils xOffsetForIPhone10LetterBox:right];
      expect(actual).to.equal(94.0);
    });
  });

  describe(@".yOffsetForIPhone10LetterBox:", ^{
    it (@"returns 72.0 in portrait orientations", ^{
      actual = [LPTouchUtils yOffsetForIPhone10LetterBox:portrait];
      expect(actual).to.equal(72.0);
      actual = [LPTouchUtils yOffsetForIPhone10LetterBox:upsidedown];
      expect(actual).to.equal(72.0);
    });

    it (@"returns 4.0 in landscape orientations", ^{
      actual = [LPTouchUtils yOffsetForIPhone10LetterBox:left];
      expect(actual).to.equal(4.0);
      actual = [LPTouchUtils yOffsetForIPhone10LetterBox:right];
      expect(actual).to.equal(4.0);
    });
  });
});

SpecEnd
