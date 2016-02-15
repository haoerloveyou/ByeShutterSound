NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.cabralcole.byeshuttersound.plist";
CFStringRef const PreferencesNotification = CFSTR("com.cabralcole.byeshuttersound.prefs");

@interface CAMCaptureRequest : NSObject
@end

@interface CAMStillImageCaptureRequest : CAMCaptureRequest {
    BOOL  _wantsAudioForCapture;
}
@property (nonatomic, readonly) BOOL wantsAudioForCapture;
- (BOOL)wantsAudioForCapture;
@end

static BOOL CAMAudio;

%hook CAMStillImageCaptureRequest

- (BOOL)wantsAudioForCapture
{
	if (CAMAudio) {
			return NO;
	}
	return %orig;
}
%end

BOOL is_mediaserverd() // Thanks PoomSmart
{
	NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
	NSUInteger count = args.count;
	if (count != 0) {
		NSString *executablePath = args[0];
		return [[executablePath lastPathComponent] isEqualToString:@"mediaserverd"];
	}
	return NO;
}

static void CAMAudioPrefs()
{
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	CAMAudio = [prefs[@"CAMSoundEnabled"] boolValue];
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera mediaserverd");
	CAMAudioPrefs();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (!is_mediaserverd())
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
		CAMAudioPrefs();
		%init;
	[pool drain];
}