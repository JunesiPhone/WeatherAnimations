#include "WASRootListController.h"
#include "notify.h"

@implementation WASRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)respring:(id)sender {
  notify_post("com.junesiphone.weatheranimations/respring");
}
- (void)launchTwitter:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/junesiphone"]];
}
- (void)launchInstagram:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.instagram.com/junesiphone/"]];
}
- (void)launchWebsite:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://junesiphone.com/"]];
}

@end
