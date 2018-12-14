#include "WASRootListController.h"
#include "notify.h"

@implementation WASRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

-(NSArray *)conditionTitles {
    NSArray *name = @[@"Tornado", @"Tropical Storm", @"Hurricane", @"Severe Thunderstorms", @"Thunderstorms", @"Mixed rain and snow", @"Mixed rain and sleet", @"Mixed snow and sleet", @"Freezing drizzle", @"Drizzle", @"Freezing rain", @"Showers1", @"Showers2", @"Snow flurries", @"Light snow showers", @"Blowing snow", @"Snow", @"Hail", @"Sleet", @"Dust", @"Foggy", @"Haze", @"Smoky", @"Blustery", @"Windy", @"Cold", @"Cloudy", @"Mostly cloudy night", @"Mostly cloudy day", @"Partly cloudy night", @"Partly cloudy day", @"Clear night", @"Sunny", @"Fair night", @"Fair day", @"Mixed rain and hail", @"Hot", @"Isolated thunderstorms", @"Scattered thunderstorms", @"Scattered thunderstorms2", @"Scattered showers", @"Heavy snow", @"Scattered snow showers", @"Heavy snow2", @"Partly Cloudy2", @"Thunderstorms2", @"Snow Showers", @"Isolated thunderstorms2"];
    return name;
}

-(NSArray *)conditionValues {
    NSArray *value = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22", @"23", @"24", @"25", @"26", @"27", @"28", @"29", @"30", @"31", @"32", @"33", @"34", @"35", @"36", @"37", @"38", @"39", @"40", @"41", @"42", @"43", @"44", @"45", @"46", @"47"];
    return value;
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
