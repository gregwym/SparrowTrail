//
//  Game.m
//  AppScaffold
//

#import "Game.h" 

// --- private interface ---------------------------------------------------------------------------

@interface Game ()

- (void)setup;
- (BOOL)isCollidingBetween:(SPDisplayObject *)obj1 and:(SPDisplayObject *)obj2;
- (void)addRunnerToSprite:(SPSprite *)sprite atX:(float)x andY:(float)y;
- (void)addTowerToSprite:(SPSprite *)sprite atX:(float)x andY:(float)y;
- (void)onBackgroundTouched:(SPTouchEvent *)event;
- (void)onImageTouched:(SPTouchEvent *)event;
- (void)onResize:(SPResizeEvent *)event;

@property (strong, nonatomic) SPSprite *contents;
@property (strong, nonatomic) NSMutableSet *towers;

@end


// --- class implementation ------------------------------------------------------------------------

@implementation Game

@synthesize contents = _contents;

- (id)init
{
    if ((self = [super init]))
    {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    // release any resources here
    [Media releaseAtlas];
    [Media releaseSound];
}

- (void)setup
{
    // This is where the code of your game will start. 
    // In this sample, we add just a few simple elements to get a feeling about how it's done.
    
    [SPAudioEngine start];  // starts up the sound engine
    
    
    // The Application contains a very handy "Media" class which loads your texture atlas
    // and all available sound files automatically. Extend this class as you need it --
    // that way, you will be able to access your textures and sounds throughout your 
    // application, without duplicating any resources.
    
    [Media initAtlas];      // loads your texture atlas -> see Media.h/Media.m
    [Media initSound];      // loads all your sounds    -> see Media.h/Media.m
    
    
    // Create some placeholder content: a background image, the Sparrow logo, and a text field.
    // The positions are updated when the device is rotated. To make that easy, we put all objects
    // in one sprite (self.contents): it will simply be rotated to be upright when the device rotates.

    self.contents = [SPSprite sprite];
    [self addChild:self.contents];

	self.towers = [[NSMutableSet alloc] init];

    SPImage *background = [[SPImage alloc] initWithContentsOfFile:@"background.jpg"];
	background.width = Sparrow.stage.width;
	background.height = Sparrow.stage.height;
    [self.contents addChild:background];

	[background addEventListener:@selector(onBackgroundTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
    
    [self addRunnerToSprite:self.contents atX:-40 andY:background.height / 2 + 40];
    
    [self updateLocations];

    // The controller autorotates the game to all supported device orientations. 
    // Choose the orienations you want to support in the Xcode Target Settings ("Summary"-tab).
    // To update the game content accordingly, listen to the "RESIZE" event; it is dispatched
    // to all game elements (just like an ENTER_FRAME event).
    // 
    // To force the game to start up in landscape, add the key "Initial Interface Orientation"
    // to the "App-Info.plist" file and choose any landscape orientation.
    
    [self addEventListener:@selector(onResize:) atObject:self forType:SP_EVENT_TYPE_RESIZE];
    
    // Per default, this project compiles as a universal application. To change that, enter the 
    // project info screen, and in the "Build"-tab, find the setting "Targeted device family".
    //
    // Now choose:  
    //   * iPhone      -> iPhone only App
    //   * iPad        -> iPad only App
    //   * iPhone/iPad -> Universal App  
    // 
    // Sparrow's minimum deployment target is iOS 5.
}

- (BOOL)isCollidingBetween:(SPDisplayObject *)obj1 and:(SPDisplayObject *)obj2
{
	SPPoint *p1 = [SPPoint pointWithX:obj1.x y:obj1.y];
	SPPoint *p2 = [SPPoint pointWithX:obj2.x y:obj2.y];

	float distance = [SPPoint distanceFromPoint:p1 toPoint:p2];
	float radius1 = obj1.width / 2;
	float radius2 = obj2.width / 2;

	if (distance < radius1 + radius2) {

//	SPRectangle *bounds1 = [obj1 boundsInSpace:self.contents];
//	SPRectangle *bounds2 = [obj2 boundsInSpace:self.contents];
//	if ([bounds1 intersectsRectangle:bounds2]) {
		return TRUE;
	}
	return FALSE;
}

- (SPSprite *)wrappedSparrow
{
	SPImage *image = [[SPImage alloc] initWithTexture:[Media atlasTexture:@"sparrow"]];
	SPSprite *sprite = [SPSprite sprite];
	image.x = image.width / -2.0f;
	image.y = image.height / -2.0f;
	[sprite addChild:image];

	return sprite;
}

- (void)addRunnerToSprite:(SPSprite *)sprite atX:(float)x andY:(float)y
{
	SPDisplayObject *image = [self wrappedSparrow];
	image.height = image.height / 5;
	image.width = image.width / 5;
    image.x = x;
    image.y = y;
    [sprite addChild:image];

	// play a sound when the image is touched
    [image addEventListener:@selector(onImageTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];

    // and animate it a little
    SPTween *tween = [SPTween tweenWithTarget:image time:10 transition:SP_TRANSITION_LINEAR];
    [tween animateProperty:@"x" targetValue:self.contents.width];
    tween.repeatCount = 1; // repeat indefinitely
    tween.reverse = NO;
	tween.onComplete = ^(void){
		[Sparrow.juggler removeObjectsWithTarget:image];
		[sprite removeChild:image];
	};
	tween.onUpdate = ^(void){
		for (SPDisplayObject *tower in self.towers) {
			if ([self isCollidingBetween:tower and:image]) {
				[Sparrow.juggler removeObjectsWithTarget:image];
			}
		}
	};
    [Sparrow.juggler addObject:tween];
}

- (void)addTowerToSprite:(SPSprite *)sprite atX:(float)x andY:(float)y
{
	SPDisplayObject *image = [self wrappedSparrow];
	image.height = image.height / 5;
	image.width = image.width / 5;
    image.x = x;
    image.y = y;
	image.scaleX = -0.2;
    [sprite addChild:image];

	[self.towers addObject:image];
}

- (void)updateLocations
{
	self.contents.x = 0;
	self.contents.y = 0;
}

- (void)onBackgroundTouched:(SPTouchEvent *)event
{
	for (SPTouch *touch in event.touches) {
		if (touch.phase != SPTouchPhaseEnded) {
			SPPoint *touchPoint = [touch locationInSpace:self.contents];
			if (touchPoint.x > self.contents.width / 2) {
				[self addTowerToSprite:self.contents atX:touchPoint.x andY:touchPoint.y];
			} else {
				[self addRunnerToSprite:self.contents atX:touchPoint.x andY:touchPoint.y];
			}
		}
	}
}

- (void)onImageTouched:(SPTouchEvent *)event
{
    NSSet *touches = [event touchesWithTarget:self andPhase:SPTouchPhaseEnded];
    if ([touches anyObject]) [Media playSound:@"sound.caf"];
}

- (void)onResize:(SPResizeEvent *)event
{
    NSLog(@"new size: %.0fx%.0f (%@)", event.width, event.height, 
          event.isPortrait ? @"portrait" : @"landscape");
    
    [self updateLocations];
}

@end
