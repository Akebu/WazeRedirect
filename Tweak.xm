#import <CoreLocation/CoreLocation.h>
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

@interface MYCLPlacemark : CLPlacemark
@property(nonatomic, readonly, copy) CLLocation *location;
@end

@interface WKNavigationDelegate : NSObject
- (void)launchWazeWithLatitude:(float)latitude Longitude:(float)longitude;
@end

%group WKNavigationDelegate

	%hook WKNavigationDelegate

	%new
	- (void)launchWazeWithLatitude:(float)latitude Longitude:(float)longitude
	{
		if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"waze://"]]){
			NSString *urlStr = [NSString stringWithFormat:@"waze://?ll=%f,%f&navigate=yes", latitude, longitude];
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
		}
	}

	- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
	{
		%orig;

		NSURL *currentURL = [[navigationAction request] URL];
		NSString *host = [currentURL host];
		if(host){
			if([host rangeOfString:@"maps.google"].location != NSNotFound){
				NSString *fullURL = [currentURL absoluteString];

				if([fullURL rangeOfString:@"&daddr="].location != NSNotFound){
					NSString *everythingAfter = [[fullURL componentsSeparatedByString:@"&daddr="] lastObject];
					NSString *mapsLocalisation = [[everythingAfter componentsSeparatedByString:@"&"] firstObject];
					mapsLocalisation = [mapsLocalisation stringByReplacingOccurrencesOfString:@"+" withString:@" "];
					mapsLocalisation = [mapsLocalisation stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					CLGeocoder *geocoder = [[CLGeocoder alloc] init];
					[geocoder geocodeAddressString:mapsLocalisation completionHandler:^(NSArray *placemarks, NSError *error){
						if(!error){
							MYCLPlacemark *placemark = [placemarks lastObject];
							float latitude = placemark.location.coordinate.latitude;
							float longitude = placemark.location.coordinate.longitude;
							decisionHandler(WKNavigationActionPolicyCancel);
							[self launchWazeWithLatitude:latitude Longitude:longitude];
						} else {
							return;
						}
					}];
					[geocoder release];

				}

				if([fullURL rangeOfString:@"&ll="].location != NSNotFound){
					NSString *everythingAfter = [[fullURL componentsSeparatedByString:@"&ll="] lastObject];
					NSString *mapsLocalisation = [[everythingAfter componentsSeparatedByString:@"&"] firstObject];
					NSString *latitude = [[mapsLocalisation componentsSeparatedByString:@","] firstObject];
					NSString *longitude = [[mapsLocalisation componentsSeparatedByString:@","] lastObject];
					decisionHandler(WKNavigationActionPolicyCancel);
					[self launchWazeWithLatitude:[latitude floatValue] Longitude:[longitude floatValue]];
				}
			}
		}
	}
	%end
%end

%hook WKWebView
- (void)setNavigationDelegate:(WKNavigationDelegate *)delegate
{
	if(delegate != nil){
		static dispatch_once_t once;
		dispatch_once(&once, ^ {
			%init(WKNavigationDelegate, WKNavigationDelegate=[delegate class]);
		});
	}
	%orig;
}
%end

%ctor
{
	%init;
}