//
//  ExampleUIWebViewController.m
//  ExampleApp-iOS
//
//  Created by Marcus Westin on 1/13/14.
//  Copyright (c) 2014 Marcus Westin. All rights reserved.
//

#import "ExampleUIWebViewController.h"
#import "WebViewJavascriptBridge.h"

@interface ExampleUIWebViewController ()
@property WebViewJavascriptBridge* bridge;
@end

@implementation ExampleUIWebViewController

- (void)viewWillAppear:(BOOL)animated {
    if (_bridge) { return; }
    
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    
    [WebViewJavascriptBridge enableLogging];
    
    __weak __typeof(self)weakSelf = self;

    _bridge = [WebViewJavascriptBridge bridgeForWebView:webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        responseCallback(@"Response for message from ObjC");
        [weakSelf callHandler:nil];
    }];
    
    [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
    
    
    [_bridge registerHandler:@"resetTitleCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        self.title = data;
        responseCallback(@"Response from resetTitleCallback 重置标题");
    }];
    
    
    [_bridge registerHandler:@"resetCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        self.title = data;
        responseCallback(@"Response from resetTitleCallback 重置标题");
    }];
    
    [_bridge registerHandler:@"chatCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"点击和某人聊天");
        
        NSDictionary *dict = (NSDictionary *)data;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"聊天人id:" message:dict[@"userId"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];
        [weakSelf presentViewController:alert animated:YES completion:nil];
        [weakSelf chatHandler:data];
        
    }];
    
    [_bridge send:@"A string sent from ObjC before Webview has loaded." responseCallback:^(id responseData) {
        NSLog(@"objc got response! %@", responseData);
    }];
    
    [_bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" }];
    
    [self renderButtons:webView];
    [self loadExamplePage:webView];
    
    [_bridge send:@"A string sent from ObjC after Webview has loaded."];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad");
}

- (void)renderButtons:(UIWebView*)webView {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    
    UIButton *messageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [messageButton setTitle:@"Send message" forState:UIControlStateNormal];
    [messageButton addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:messageButton aboveSubview:webView];
    messageButton.frame = CGRectMake(10, 414, 100, 35);
    messageButton.titleLabel.font = font;
    messageButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
    
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"Call handler" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(110, 414, 100, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"Reload webview" forState:UIControlStateNormal];
    [reloadButton addTarget:webView action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(210, 414, 100, 35);
    reloadButton.titleLabel.font = font;
}

- (void)sendMessage:(id)sender {
    [_bridge send:@"A string sent from ObjC to JS你好" responseCallback:^(id response) {
        NSLog(@"sendMessage got response: %@", response);
    }];
}

- (void)callHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, JS!",@"userid":@"1000000" };
//    [_bridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
//        NSLog(@"testJavascriptHandler responded: %@", response);
//    }];
    
    [_bridge callHandler:@"testHandler" data:data responseCallback:^(id responseData) {
        NSLog(@"======================testHandler");
    }];
}

- (void)chatHandler:(id)data
{
    [_bridge callHandler:@"chatHandler" data:data responseCallback:^(id responseData) {
        NSLog(@"======================chatHandler");
    }];
}

- (void)loadExamplePage:(UIWebView*)webView {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"ExampleApp" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}
@end
