#import "headers.h"

/* 
	Todo 
	Find another way to hide bg on 11.1.2
	Could create a global init function
	Create better settings icon

	Issues: 
		11.1.2: 
			BG comes back after conditions change
*/

static float deviceVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
static NSString *nsDomainString = @"com.junesiphone.weatheranimation";
static NSString *nsNotificationString = @"com.junesiphone.weatheranimation/preferences.changed";
static bool enabled = NO;
static bool hideBG = NO;

static WUIDynamicWeatherBackground* dynamicBG = nil;
static WUIWeatherCondition* condition = nil;
static bool Loaded = NO;

void loadWeatherAnimation(){

	WeatherPreferences* prefs = [%c(WeatherPreferences) sharedPreferences];
    City* city = [prefs localWeatherCity];

	if(!Loaded){
	    if(city){
		    UIView *weatherAnimation = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
			WUIWeatherConditionBackgroundView *referenceView = [[%c(WUIWeatherConditionBackgroundView) alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
			dynamicBG = [referenceView background];
			condition = [dynamicBG condition];
			[condition resume];
			[weatherAnimation addSubview:dynamicBG];
			[dynamicBG setCity: city];
			SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
			UIView *scrollView = nil;

			if([manager isUILocked]){
				if (manager != nil) {
					SBLockScreenViewController* lockViewController = MSHookIvar<SBLockScreenViewController*>([%c(SBLockScreenManager) sharedInstance], "_lockScreenViewController");
			     	UIView* lockView = MSHookIvar<SBLockScreenView*>(lockViewController, "_view");
			     	if([lockView isKindOfClass:[%c(SBDashBoardView) class]]){
			     		scrollView = MSHookIvar<SBDashBoardView*>(lockView, "_mainPageView");
			     	}
				}
			}

			[scrollView addSubview:weatherAnimation];
			[scrollView sendSubviewToBack:weatherAnimation];
			Loaded = YES;
		}
	}else{
		if(city){
			[dynamicBG setCity: city];
		}
		[condition resume];
	}
}

/* remove view from screen */
void pauseAnimation(){
	[condition pause];
}

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
				loadWeatherAnimation();
			}
		}
	}
%end

/* devices unlock */
%hook SBLockScreenManager
	- (void)lockScreenViewControllerDidDismiss{
		%orig;
		if(enabled){
			pauseAnimation();
		}
	}
%end

/* iPX is unlocked */
%hook SBCoverSheetPresentationManager
	- (void)_relinquishHomeGesture{
		%orig;
		if(enabled){
			pauseAnimation();
		}
	}
%end

/* When device resprings */
%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application{
    %orig;
    if(enabled){
    	loadWeatherAnimation();
    }
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
    NSNumber *hide = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"hidebg" inDomain:nsDomainString];
    enabled = (en) ? [en boolValue] : NO;
    hideBG = (hide) ? [hide boolValue] : NO;
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