#import "headers.h"

/* 
	Sharing: Feel free to use this code, give credit in your projects and promotions.
	License will allow you to create your own builds for personal or commercial use, you must provide
	source code to the public.

	Contributing: I share this code to show what i've found and to learn from. If you find something that can
	improved please contact me or make a pull request. Would love to improve this and both us learned something.

	Todo 
	Find another way to hide bg on 11.1.2
	Could create a global init function

	Issues: 
		11.1.2: 
			BG comes back after conditions change only (iPX) and rarely happens

*/

static float deviceVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
static NSString *nsDomainString = @"com.junesiphone.weatheranimation";
static NSString *nsNotificationString = @"com.junesiphone.weatheranimation/preferences.changed";
static bool enabled = NO;
static bool hideBG = NO;
static bool hideonnotification = NO;
static bool showonsb = NO;
static bool showonls = NO;
static bool showaboveXen = NO;

static WUIDynamicWeatherBackground* dynamicBG = nil;
static WUIWeatherCondition* condition = nil;
static UIView* weatherAnimation = nil;
static SBHomeScreenView* HSView;
static bool loaded = NO;


void applyCityToDynamicBG(){
	/* Could refresh weather here but for battery we will rely on the system */
	WeatherPreferences* prefs = [%c(WeatherPreferences) sharedPreferences];
    City* city = [prefs localWeatherCity];
    if(city){
    	[dynamicBG setCity: city];
    }
}

void moveToLockscreen(){
	if(showonls){
		SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
		if([manager isUILocked]){
			if (manager != nil) {
				SBLockScreenViewController* lockViewController = MSHookIvar<SBLockScreenViewController*>([%c(SBLockScreenManager) sharedInstance], "_lockScreenViewController");
		     	UIView* lockView = MSHookIvar<SBLockScreenView*>(lockViewController, "_view");
		     	if([lockView isKindOfClass:[%c(SBDashBoardView) class]]){
		     		UIView *scrollView = MSHookIvar<SBDashBoardView*>(lockView, "_backgroundView");
		     		[scrollView addSubview:weatherAnimation];
					[scrollView sendSubviewToBack:weatherAnimation];
		     	}
			}
		}
		applyCityToDynamicBG();
		[condition resume];
	}
}

void moveToSpringBoard(){
	if(![HSView viewWithTag:982]){
		[HSView addSubview:weatherAnimation];
	}
	if(!showaboveXen){
		[HSView sendSubviewToBack:weatherAnimation];
	}
	applyCityToDynamicBG();
	[condition resume];
}

/* pause animation */
void pauseAnimation(){
	[condition pause];
}

/* initialize a background view */
void loadWeatherAnimation(){

	if(!showonsb && !showonls){
		return;
	}

	if(!loaded){
	    weatherAnimation = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
		weatherAnimation.clipsToBounds = YES;
		weatherAnimation.tag = 982;
		weatherAnimation.userInteractionEnabled = NO;
		WUIWeatherConditionBackgroundView *referenceView = [[%c(WUIWeatherConditionBackgroundView) alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
		dynamicBG = [referenceView background];
		condition = [dynamicBG condition];
		[condition resume];
		[weatherAnimation addSubview:dynamicBG];
		applyCityToDynamicBG();
		moveToLockscreen(); //on initial load set to lockscreen
		loaded = YES;
	}
}

/* get homescreen view */
%hook SBHomeScreenView
	-(void)setFrame:(CGRect)arg1{
		HSView = self;
		%orig;
	}
%end

/* Hide weather on notification */
%hook SBDashBoardCombinedListViewController
- (void)_setListHasContent:(_Bool)arg1{
	%orig;
	if(hideonnotification && enabled){
		if(arg1 == YES){
			weatherAnimation.hidden = YES;
			[condition pause];
		}else{
			weatherAnimation.hidden = NO;
			[condition resume];
		}
	}
}
%end

/* 
	ON iOS 11.3 you can just return nil on gradientLayer to drop the background
	iOS 11.1.2 you need to get the layer that has a background color
	and also hide the gradient layer
*/
%hook WUIDynamicWeatherBackground
	-(id)gradientLayer{
		if(hideBG){
			return nil;
		}
		return %orig;
	}
	-(void)setCurrentBackground:(CALayer *)arg1{

	}
	-(void)setBackgroundCache:(NSCache *)arg1{
		
	}
	/* 11.1.2 Still nees improving */ 
	-(void)addSublayer:(id)arg1{
		%orig;
		if(hideBG){
			if(deviceVersion < 11.3){
				CALayer* layer = arg1;
				for(CALayer* firstLayers in layer.sublayers){
					if(firstLayers.backgroundColor){
						firstLayers.backgroundColor = [UIColor clearColor].CGColor;
					}
					for(CALayer* secLayers in firstLayers.sublayers){
						for(CALayer* thrLayers in secLayers.sublayers){
							if([thrLayers isKindOfClass:[CAGradientLayer class]]){
								thrLayers.hidden = YES;
							}
						}
					}
				}
			}
		}
	}
%end

/* when device goes to sleep */
%hook SBLockScreenViewControllerBase
	- (void)setInScreenOffMode:(_Bool)arg1 forAutoUnlock:(_Bool)arg2{
		%orig;
		if(enabled){
			if(arg1){
				pauseAnimation();
			}else{
				moveToLockscreen();
			}
		}
	}
%end

/* devices unlock */
%hook SBLockScreenManager
	- (void)lockScreenViewControllerDidDismiss{
		%orig;
		if(enabled && !showonsb){
			pauseAnimation();
		}
	}
%end

/* iPX is unlocked */
%hook SBCoverSheetPresentationManager
	- (void)_relinquishHomeGesture{
		%orig;
		if(enabled && !showonsb){
			pauseAnimation();
		}
	}
%end

/* When device resprings */
%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application{
    %orig;
    if(enabled){
    	/* give weather time to initiate */
    	dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 4);
		dispatch_after(delay, dispatch_get_main_queue(), ^(void){
		    loadWeatherAnimation();
		});
    }
}
- (_Bool)isShowingHomescreen{
	if(showonsb){
		moveToSpringBoard();
	}
	return %orig;
}
%end

/* respring device */
static void respring() {
	SpringBoard *sb = (SpringBoard *)[UIApplication sharedApplication];
  	if ([sb respondsToSelector:@selector(_relaunchSpringBoardNow)]) {
    	[sb _relaunchSpringBoardNow];
  	} else if (%c(FBSystemService)) {
    	[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
  	}
}

/* settings callback */
static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSNumber *en = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
    NSNumber *onls = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"showonls" inDomain:nsDomainString];
    NSNumber *onsb = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"showonsb" inDomain:nsDomainString];
    NSNumber *abovexen = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"showabovexen" inDomain:nsDomainString];
    NSNumber *hide = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"hidebg" inDomain:nsDomainString];
    NSNumber *hidenotify = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"hideonnotification" inDomain:nsDomainString];
    enabled = (en) ? [en boolValue] : NO;
    showonls = (onls) ? [onls boolValue] : NO;
    showonsb = (onsb) ? [onsb boolValue] : NO;
    showaboveXen = (abovexen) ? [abovexen boolValue] : NO;
    hideBG = (hide) ? [hide boolValue] : NO;
    hideonnotification = (hidenotify) ? [hidenotify boolValue] : NO;
}


%ctor {
	/* Settings */
	notificationCallback(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        notificationCallback,
        (CFStringRef)nsNotificationString,
        NULL,
        CFNotificationSuspensionBehaviorCoalesce);

    /* respring button */
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)respring, CFSTR("com.junesiphone.weatheranimations/respring"), NULL, 0);

    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
	NSUInteger count = args.count;
	if (count != 0) {
		NSString *executablePath = args[0];
		if (executablePath) {
			NSString *processName = [executablePath lastPathComponent];
			BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
			BOOL isApplication = [executablePath rangeOfString:@"/Application"].location != NSNotFound;
			if (isSpringBoard || isApplication) {
				/* WeatherUI */
    			dlopen("System/Library/PrivateFrameworks/WeatherUI.framework/WeatherUI", RTLD_NOW);
			}
		}
	}
}