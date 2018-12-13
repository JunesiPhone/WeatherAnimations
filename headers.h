@interface SBLockScreenScrollView : UIScrollView
@end

@interface SBAlert : UIViewController
@end

@interface SBLockScreenViewControllerBase : SBAlert
@end

@interface SBLockScreenViewController : SBLockScreenViewControllerBase
-(id)lockScreenView;
@end

@interface SBDashBoardView : UIView
@end

@interface SBLockScreenView : UIView
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
@property (readonly) BOOL isUILocked;
@end



/* settings */
@interface NSUserDefaults (WA)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

/* respring */
@interface FBSystemService : NSObject
  +(id)sharedInstance;
  -(void)exitAndRelaunch:(BOOL)arg1;
@end
@interface SpringBoard : NSObject
  - (void)_simulateLockButtonPress;
  - (void)_simulateHomeButtonPress;
  - (void)_relaunchSpringBoardNow;
  +(id)sharedInstance;
  -(id)_accessibilityFrontMostApplication;
  -(void)clearMenuButtonTimer;
@end

/* springboard */

@interface SBHomeScreenView : UIView
-(void)setFrame:(CGRect)arg1;
@end
