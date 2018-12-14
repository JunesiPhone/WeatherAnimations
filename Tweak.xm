#import "headers.h"
#import "weather.h"

/* 
	Sharing: Feel free to use this code, give credit in your projects and promotions.
	License will allow you to create your own builds for personal or commercial use, you must provide
	source code to the public.

	Contributing: I share this code to show what i've found and to learn from. If you find something that can
	improved please contact me or make a pull request. Would love to improve this and both us learned something.

	Todo:
		Find another way to hide bg on 11.1.2 (iPX)
		Add check for last weather update to stop updating if not needed 

	Issues: 
		11.1.2: 
			BG comes back after conditions change only (iPX) and rarely happens

	Credits: 
		Name: Matchstic 
		Twitter: https://twitter.com/_Matchstic 
		Github: https://github.com/Matchstic

*/

static float deviceVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

/* Settings */
static NSString *nsDomainString = @"com.junesiphone.weatheranimation";
static NSString *nsNotificationString = @"com.junesiphone.weatheranimation/preferences.changed";
static bool enabled = NO;
static bool hideBG = NO;
static bool hideonnotification = NO;
static bool showonsb = NO;
static bool showonls = NO;
static bool showaboveXen = NO;
static bool usecondition = NO;
static int conditionNumber = 0;

/* References */
static WUIDynamicWeatherBackground* dynamicBG = nil;
static WUIWeatherCondition* condition = nil;
static bool loaded = NO;
static WATodayAutoupdatingLocationModel* todayModel = nil;
static NSDate * lastUpdateTime;
static SBHomeScreenView* HSView;

/* 
	Todo: add check for last update to stop updating if not needed 
	Credit: Matchstic
		Since this tweak runs on iOS11 we can use Matchstics method (used in XenInfo) to get the current city
		much nicer implementation than anything i've seen. Huge shoutout and a huge thanks to him for his work.
		Twitter: https://twitter.com/_Matchstic
		Github: https://github.com/Matchstic

*/

void applyCityToDynamicBG(){
		WeatherPreferences *preferences = [%c(WeatherPreferences) sharedPreferences];
		if(!todayModel){
			todayModel = [%c(WATodayModel) autoupdatingLocationModelWithPreferences:preferences effectiveBundleIdentifier:@"com.apple.weather"];
		}

		[todayModel setLocationServicesActive:YES];
		[todayModel setIsLocationTrackingEnabled:YES];
		[todayModel executeModelUpdateWithCompletion:^(BOOL arg1, NSError *arg2) {
			if(todayModel.forecastModel.city){
				[dynamicBG setCity: todayModel.forecastModel.city];
				[todayModel setIsLocationTrackingEnabled:NO];
				lastUpdateTime = todayModel.forecastModel.city.updateTime;
				[condition resume];
				if(usecondition){
					[condition setCondition:conditionNumber];
				}
			}
		}];
		
}

/* grabs background view of LS */
UIView* grabLSView(){
	SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
	UIView* bgView = nil;
	if([manager isUILocked]){
		if (manager != nil) {
			SBLockScreenViewController* lockViewController = MSHookIvar<SBLockScreenViewController*>(manager, "_lockScreenViewController");
	     	UIView* lockView = MSHookIvar<SBLockScreenView*>(lockViewController, "_view");
	     	if([lockView isKindOfClass:[%c(SBDashBoardView) class]]){
	     		bgView = MSHookIvar<SBDashBoardView*>(lockView, "_backgroundView");
	     	}
		}
	}
	return bgView;
}

/* Moves view to LS */
void moveToLockscreen(){
	if(showonls){
		UIView* LSView = grabLSView();
		if(LSView){
			if(![LSView viewWithTag:982]){
				[LSView addSubview:dynamicBG];
				[LSView sendSubviewToBack:dynamicBG];
			}
			applyCityToDynamicBG();
		}
	}
}

/* Moves view to SB */
void moveToSpringBoard(){
	if(![HSView viewWithTag:982]){
		[HSView addSubview:dynamicBG];
	}
	if(!showaboveXen){
		[HSView sendSubviewToBack:dynamicBG];
	}
	applyCityToDynamicBG();
}

/* pause animation to conserve battery*/
void pauseAnimation(){
	[condition pause];
}

/* initialize a background view */
void loadWeatherAnimation(){

	if(!showonsb && !showonls){
		return;
	}

	/* get reference once, we can use one view for both LS and SB */
	if(!loaded){
		WUIWeatherConditionBackgroundView *referenceView = [[%c(WUIWeatherConditionBackgroundView) alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
		dynamicBG = [referenceView background];
		dynamicBG.clipsToBounds = YES;
		dynamicBG.tag = 982;
		dynamicBG.userInteractionEnabled = NO;
		condition = [dynamicBG condition];
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
			dynamicBG.hidden = YES;
			[condition pause];
		}else{
			dynamicBG.hidden = NO;
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
		if(hideBG && enabled){
			return nil;
		}
		return %orig;
	}
	-(void)setCurrentBackground:(CALayer *)arg1{
		if(!enabled){
			%orig;
		}
	}
	-(void)setBackgroundCache:(NSCache *)arg1{
		if(!enabled){
			%orig;
		}
	}
	/* 11.1.2 (iPX) Still needs improving */ 
	-(void)addSublayer:(id)arg1{
		%orig;
		if(hideBG && enabled){
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
    	/* give weather time to initiate on device respring also stops background showing on iPX */
    	dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 4);
		dispatch_after(delay, dispatch_get_main_queue(), ^(void){
		    loadWeatherAnimation();
		});
    }
}
- (_Bool)isShowingHomescreen{
	if(showonsb && enabled){
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
    NSNumber *usemanualcondition = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"usecondition" inDomain:nsDomainString];
    NSNumber *conditiontype = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"conditionType" inDomain:nsDomainString];
    
    enabled = (en) ? [en boolValue] : NO;
    showonls = (onls) ? [onls boolValue] : NO;
    showonsb = (onsb) ? [onsb boolValue] : NO;
    showaboveXen = (abovexen) ? [abovexen boolValue] : NO;
    hideBG = (hide) ? [hide boolValue] : NO;
    hideonnotification = (hidenotify) ? [hidenotify boolValue] : NO;
    usecondition = (usemanualcondition) ? [usemanualcondition boolValue] : NO;
    conditionNumber = (conditiontype) ? [conditiontype integerValue] : 0;
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
				/* Weather */
				dlopen("System/Library/PrivateFrameworks/Weather.framework/Weather", RTLD_NOW);
				/* WeatherUI */
    			dlopen("System/Library/PrivateFrameworks/WeatherUI.framework/WeatherUI", RTLD_NOW);
			}
		}
	}
}