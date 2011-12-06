//
//  SHKVkontakteOAuthView.m
//  forismatic
//
//  Created by MacBook on 05.12.11.
//  Copyright (c) 2011 Alterplay. All rights reserved.
//

#import "SHKVkontakteOAuthView.h"
#import "SHKVkontakte.h"

@implementation SHKVkontakteOAuthView
@synthesize vkWebView, appID, delegate;

- (void) dealloc {
	[delegate release];
	[appID release];
	vkWebView.delegate = nil;
	[vkWebView release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if(!vkWebView)
	{
		self.vkWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
		vkWebView.delegate = self;
		vkWebView.scalesPageToFit = YES;
		self.vkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:vkWebView];
	}

	
	if(!appID) 
	{
		[self dismissModalViewControllerAnimated:YES];
		return;
	}
	NSString *authLink = [NSString stringWithFormat:@"http://api.vk.com/oauth/authorize?client_id=%@&scope=wall,photos&redirect_uri=http://api.vk.com/blank.html&display=touch&response_type=token", appID];
	NSURL *url = [NSURL URLWithString:authLink];
	
	[vkWebView loadRequest:[NSURLRequest requestWithURL:url]];
	
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[vkWebView stopLoading];
	vkWebView.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Web View Delegate

- (BOOL)webView:(UIWebView *)aWbView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
	NSURL *URL = [request URL];

	if ([[URL absoluteString] isEqualToString:@"http://api.vk.com/blank.html#error=access_denied&error_reason=user_denied&error_description=User%20denied%20your%20request"]) {
		[super dismissModalViewControllerAnimated:YES];
		return NO;
	}
	NSLog(@"Request: %@", [URL absoluteString]); 
	return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
	
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {

	if ([vkWebView.request.URL.absoluteString rangeOfString:@"access_token"].location != NSNotFound) {
		NSString *accessToken = [self stringBetweenString:@"access_token=" 
																						andString:@"&" 
																					innerString:[[[webView request] URL] absoluteString]];
		
		NSArray *userAr = [[[[webView request] URL] absoluteString] componentsSeparatedByString:@"&user_id="];
		NSString *user_id = [userAr lastObject];
		NSLog(@"User id: %@", user_id);
		if(user_id){
			[[NSUserDefaults standardUserDefaults] setObject:user_id forKey:kSHKVkonakteUserId];
		}
		
		if(accessToken){
			[[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kSHKVkontakteAccessTokenKey];

			[[NSUserDefaults standardUserDefaults] setObject:[[NSDate date] dateByAddingTimeInterval:86400] forKey:kSHKVkontakteExpiryDateKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		
		NSLog(@"vkWebView response: %@",[[[webView request] URL] absoluteString]);
		[(SHKVkontakte *)delegate authComplete];
		[self dismissModalViewControllerAnimated:YES];
	} else if ([vkWebView.request.URL.absoluteString rangeOfString:@"error"].location != NSNotFound) {
		NSLog(@"Error: %@", vkWebView.request.URL.absoluteString);
		[self dismissModalViewControllerAnimated:YES];
	}
	
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	
	NSLog(@"vkWebView Error: %@", [error localizedDescription]);
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Methods

- (NSString*)stringBetweenString:(NSString*)start 
                       andString:(NSString*)end 
                     innerString:(NSString*)str 
{
	NSScanner* scanner = [NSScanner scannerWithString:str];
	[scanner setCharactersToBeSkipped:nil];
	[scanner scanUpToString:start intoString:NULL];
	if ([scanner scanString:start intoString:NULL]) {
		NSString* result = nil;
		if ([scanner scanUpToString:end intoString:&result]) {
			return result;
		}
	}
	return nil;
}

@end
