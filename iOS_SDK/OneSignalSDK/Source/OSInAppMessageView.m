/**
 * Modified MIT License
 *
 * Copyright 2017 OneSignal
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * 2. All copies of substantial portions of the Software may only be used in connection
 * with services provided by OneSignal.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "OSInAppMessageView.h"
#import "OneSignalHelper.h"
#import <WebKit/WebKit.h>
#import "OSInAppMessageAction.h"
#import "OneSignalViewHelper.h"


@interface OSInAppMessageView () <UIScrollViewDelegate, WKUIDelegate, WKNavigationDelegate>

@property (strong, nonatomic, nonnull) OSInAppMessage *message;
@property (strong, nonatomic, nonnull) WKWebView *webView;
@property (nonatomic) BOOL loaded;

@end


@implementation OSInAppMessageView

- (instancetype _Nonnull)initWithMessage:(OSInAppMessage *)inAppMessage withScriptMessageHandler:(id<WKScriptMessageHandler>)messageHandler {
    if (self = [super init]) {
        self.message = inAppMessage;
        self.translatesAutoresizingMaskIntoConstraints = false;
        [self setupWebviewWithMessageHandler:messageHandler];
    }
    
    return self;
}

- (void)loadedHtmlContent:(NSString *)html withBaseURL:(NSURL *)url {
    // UI Update must be done on the main thread
    NSLog(@"11111 [self.webView loadHTMLString:html baseURL:url];");

    html = @"<head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\">\n"
           @"<style>\n"
           @"    * {\n"
           @"        -webkit-touch-callout: none;\n"
           @"        -webkit-user-select: none; /* Disable selection/copy in UIWebView */\n"
           @"    }\n"
           @"    p {\n"
           @"        margin-top: 16px;\n"
           @"        margin-bottom: 16px;\n"
           @"    }\n"
           @"    h1 {\n"
           @"        margin-top: 0;\n"
           @"        margin-bottom: 8px;\n"
           @"        font-weight: 400;\n"
           @"    }\n"
           @"    body {\n"
           @"        font-family: -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Oxygen-Sans,Ubuntu,Cantarell,\"Helvetica Neue\",sans-serif;\n"
           @"        padding: 16px;\n"
           @"        overflow: hidden;\n"
           @"        cursor: pointer;background-image: url(https://media.giphy.com/media/QJvwBSGaoc4eI/giphy.gif);\n"
           @"            background-position: center;\n"
           @"            background-repeat: no-repeat;\n"
           @"            background-size: cover;background-color: #ffffff;\n"
           @"        \n"
           @"    }\n"
           @"\n"
           @"    .flex-container {\n"
           @"        display: flex;\n"
           @"        flex-direction: column;\n"
           @"        height: 100%;\n"
           @"    }\n"
           @"\n"
           @"    /* Image only for Fullscreen and Modal */\n"
           @"    .image-container {\n"
           @"        display: flex;\n"
           @"        justify-content: center;\n"
           @"        flex-direction: column;\n"
           @"    }\n"
           @"</style>\n"
           @"<script>\n"
           @"    // Called from onClick of images, buttons, and dismiss button\n"
           @"    function actionTaken(data, clickType) {\n"
           @"        console.log(\"actionTaken(): \" + JSON.stringify(data));\n"
           @"        if (clickType)\n"
           @"            data[\"click_type\"] = clickType;\n"
           @"        postMessageToNative({ type: \"action_taken\", body: data });\n"
           @"    }\n"
           @"\n"
           @"    function postMessageToNative(msgJson) {\n"
           @"        console.log(\"postMessageToNative(): \" + JSON.stringify(msgJson));\n"
           @"        var encodedMsg = JSON.stringify(msgJson);\n"
           @"        postMessageToIos(encodedMsg);\n"
           @"        postMessageToAndroid(encodedMsg);\n"
           @"        postMessageToDashboard(encodedMsg);\n"
           @"    }\n"
           @"\n"
           @"    function postMessageToIos(encodedMsg) {\n"
           @"        // See iOS SDK Source\n"
           @"        //    userContentController:didReceiveScriptMessage:\n"
           @"        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iosListener)\n"
           @"            window.webkit.messageHandlers.iosListener.postMessage(encodedMsg);\n"
           @"    }\n"
           @"\n"
           @"    function postMessageToAndroid(encodedMsg) {\n"
           @"        if (window.OSAndroid)\n"
           @"            window.OSAndroid.postMessage(encodedMsg);\n"
           @"    }\n"
           @"\n"
           @"    function postMessageToDashboard(encodedMsg) {\n"
           @"        if (window.parent) {\n"
           @"            window.parent.postMessage(encodedMsg, \"*\");\n"
           @"        }\n"
           @"    }\n"
           @"\n"
           @"    // last-element needed to give the correct height for modals and banners\n"
           @"    function getPageMetaData() {\n"
           @"        var lastElement = document.getElementById(\"last-element\");\n"
           @"        if (!lastElement)\n"
           @"            return {};\n"
           @"\n"
           @"        var flexContainer = document.querySelector(\".flex-container\");\n"
           @"        if (!flexContainer) {\n"
           @"            console.error(\"Could not find flex-container class required to resize modal correctly!\");\n"
           @"            return {};\n"
           @"        }\n"
           @"\n"
           @"        // rect.y will be undefined on Android 4.4\n"
           @"        var flexContainerRect = flexContainer.getBoundingClientRect();\n"
           @"        return {\n"
           @"            rect: {\n"
           @"                height: lastElement.getBoundingClientRect().top + flexContainerRect.top\n"
           @"            },\n"
           @"            flexContainerRect: toJsonObject(flexContainerRect)\n"
           @"        };\n"
           @"    }\n"
           @"\n"
           @"    function toJsonObject(value) {\n"
           @"        return JSON.parse(JSON.stringify(value));\n"
           @"    }\n"
           @"\n"
           @"    function getDisplayLocation() {\n"
           @"        var flexContainer = document.querySelector(\".flex-container\");\n"
           @"        if (!flexContainer) {\n"
           @"            console.error(\"Could not find flex-container class required to resize modal correctly!\");\n"
           @"            return null;\n"
           @"        }\n"
           @"\n"
           @"        return flexContainer.dataset.displaylocation;\n"
           @"    }\n"
           @"\n"
           @"    function getAttributes(element) {\n"
           @"        var attributes = {};\n"
           @"        if (element.hasAttributes()) {\n"
           @"            for (var i = 0, n = element.attributes.length; i < n; i++) {\n"
           @"                var attr = element.attributes[i];\n"
           @"                attributes[attr.name] = attr.value;\n"
           @"            }\n"
           @"        }\n"
           @"        return attributes;\n"
           @"    }\n"
           @"\n"
           @"    // TODO: Remove after we have verified we are not seeing any mis touches.\n"
           @"    // Just a quick and dirty way to see where you have tapped by moving the close button to where you tapped.\n"
           @"    function debugTaps() {\n"
           @"        document.body.addEventListener('click', function(e) {\n"
           @"            console.log(\"body onlick:\" + JSON.stringify({x: e.pageX, y: e.pageY}));\n"
           @"            document.querySelector(\".close-button\").style.display = \"block\";\n"
           @"            document.querySelector(\".close-button\").style.right = 0;\n"
           @"            document.querySelector(\".close-button\").style.left = e.pageX;\n"
           @"            document.querySelector(\".close-button\").style.top = e.pageY;\n"
           @"        }, true);\n"
           @"    }\n"
           @"\n"
           @"    // Lets the SDK know the page is done loading as well as it's display type and location.\n"
           @"    window.onload = function() {\n"
           @"        postMessageToNative({\n"
           @"            type: \"rendering_complete\",\n"
           @"            pageMetaData: getPageMetaData(),\n"
           @"            displayLocation: getDisplayLocation()\n"
           @"        });\n"
           @"\n"
           @"        // close button clicks\n"
           @"        var closeButton = document.querySelector(\".close-button\");\n"
           @"        closeButton && closeButton.addEventListener(\"click\", function(e) {\n"
           @"            actionTaken({close: true});\n"
           @"            e.stopPropagation();\n"
           @"        }, true);\n"
           @"\n"
           @"        // image and button clicks\n"
           @"        var clickable = document.getElementsByClassName(\"iam-clickable\");\n"
           @"        console.log(clickable.length);\n"
           @"        for (var i = 0, n = clickable.length; i < n; i++) {\n"
           @"            var el = clickable[i];\n"
           @"            console.log(i);\n"
           @"            var attributes = getAttributes(el);\n"
           @"            if (attributes[\"data-action-payload\"]) {\n"
           @"                // use iife to close over the right element and value\n"
           @"                (function(element, value, label) {\n"
           @"                    element.addEventListener(\"click\", function(e) {\n"
           @"                        actionTaken(value, label);\n"
           @"                        e.stopPropagation();\n"
           @"                    }, true);\n"
           @"                })(el, JSON.parse(attributes[\"data-action-payload\"]), attributes[\"data-action-label\"]);\n"
           @"            }\n"
           @"        }\n"
           @"    };\n"
           @"\n"
           @"    window.onresize = function () {\n"
           @"        postMessageToNative({\n"
           @"            type: \"resize\",\n"
           @"            pageMetaData: getPageMetaData(),\n"
           @"            displayLocation: getDisplayLocation()\n"
           @"        });\n"
           @"    }\n"
           @"</script>\n"
           @"<style>.close-button {\n"
           @"    right: -8px;\n"
           @"    top: -8px;\n"
           @"    width: 48px;\n"
           @"    height: 48px;\n"
           @"    position: absolute;\n"
           @"    display: flex;\n"
           @"    justify-content: center;\n"
           @"    flex-direction: column;\n"
           @"    align-items: center;\n"
           @"}#title {\n"
           @"  font-size: 24;\n"
           @"  color: #000000;\n"
           @"  text-align: center;\n"
           @"}\n"
           @"#body {\n"
           @"  font-size: 8;\n"
           @"  color: #342713;\n"
           @"  margin-top: 0px;\n"
           @"  text-align: center;\n"
           @"}\n"
           @"#img-bg-div-image {\n"
           @"    flex-shrink: 9999; /* Chrome 30 bug workaround to shrink down to min-height when needed */\n"
           @"    min-height: 10px;\n"
           @"\n"
           @"    margin-bottom: 10px;\n"
           @"\n"
           @"    background-size: contain;\n"
           @"    background-position: center;\n"
           @"    background-repeat: no-repeat;\n"
           @"    background-image: url(https://img.onesignal.com/i/b13388b2-44bc-4765-bd0b-919a3c44f65f);\n"
           @"}\n"
           @"\n"
           @"#img-invisible-image {\n"
           @"    width: 100%;\n"
           @"    min-height: 10px; /* Keep img from growing outside of parent div. */\n"
           @"    opacity: 0; /* Invisible - Only using as source for height. */\n"
           @"}\n"
           @"#button {\n"
           @"  font-size: 24;\n"
           @"  color: #FFF;\n"
           @"  background-color: #1f8feb;\n"
           @"  text-align: center;\n"
           @"  width: 100%;\n"
           @"  margin-bottom: 24px;\n"
           @"  padding: 12px;\n"
           @"  border-width: 0;\n"
           @"  border-radius: 4px;\n"
           @"}\n"
           @"\n"
           @"</style>\n"
           @"</head>\n"
           @"<body>\n"
           @"    \n"
           @"    <div class=\"close-button\">\n"
           @"        <svg width=\"10\" height=\"10\" viewBox=\"0 0 8 8\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\">\n"
           @"            <path d=\"M7.80309 1.14768C8.06564 0.885137 8.06564 0.459453 7.80309 0.196909C7.54055 -0.0656362 7.11486 -0.0656362 6.85232 0.196909L4 3.04923L1.14768 0.196909C0.885137 -0.0656362 0.459453 -0.0656362 0.196909 0.196909C-0.0656362 0.459453 -0.0656362 0.885137 0.196909 1.14768L3.04923 4L0.196909 6.85232C-0.0656362 7.11486 -0.0656362 7.54055 0.196909 7.80309C0.459453 8.06564 0.885137 8.06564 1.14768 7.80309L4 4.95077L6.85232 7.80309C7.11486 8.06564 7.54055 8.06564 7.80309 7.80309C8.06564 7.54055 8.06564 7.11486 7.80309 6.85232L4.95077 4L7.80309 1.14768Z\" fill=\"#111111\"/>\n"
           @"        </svg>\n"
           @"    </div>\n"
           @"\n"
           @"    <div class=\"flex-container\" data-displaylocation=\"center_modal\">\n"
           @"        <div class=\"title-container\">\n"
           @"            <h1 id=\"title\">IAM V2 Bug Bash</h1>\n"
           @"        </div>\n"
           @"        <div class=\"body-container\">\n"
           @"            <p id=\"body\">•</p>\n"
           @"        </div>\n"
           @"\n"
           @"\n"
           @"        <div id=\"img-bg-div-image\" class=\"image-container\">\n"
           @"           <img id=\"img-invisible-image\" class=\"iam-image iam-clickable\" src=\"https://img.onesignal.com/i/b13388b2-44bc-4765-bd0b-919a3c44f65f\" alt=\"main image\" data-action-payload='{\"url\":\"\",\"url_target\":\"browser\",\"close\":false,\"id\":\"53d4d64c-a340-4aa8-9743-05ba21c48bd8\"}' data-action-label=\"image\">\n"
           @"        </div>\n"
           @"\n"
           @"        <div class=\"button-container\">\n";

    NSString *suffix =
           @"       </div>\n"
           @"       <!-- Used to find the height of the content so the SDK can set the correct view port height. -->\n"
           @"       <div id=\"last-element\" />\n"
           @"   </div>\n"
           @"</body>\n"
           @"</html>";

    // Tags Button
    if (OneSignal.iamV2Tags && ![OneSignal.iamV2Tags isEqualToString:@""]) {
        NSArray *tagSplit = [OneSignal.iamV2Tags componentsSeparatedByString:@","];
        NSMutableDictionary *tagsToAdd = [NSMutableDictionary new];
        NSMutableArray *tagsToRemove = [NSMutableArray new];
        for (var i = 0; i < tagSplit.count; i++) {
            NSString *tag = [tagSplit objectAtIndex:i];
            NSArray *splitTag = [tag componentsSeparatedByString:@":"];
            NSString *tagKey = [splitTag objectAtIndex:0];

            if (splitTag.count == 2) {
                NSString *tagValue = [splitTag objectAtIndex:1];
                if ([tagValue isEqualToString:@""]) {
                    [tagsToRemove addObject:tagKey];
                }
                else {
                    tagsToAdd[tagKey] = tagValue;
                }
            } else if (splitTag.count == 1) {
                [tagsToRemove addObject:tagKey];
            }
        }
        NSString* tagButton = [self addTagsButtonToHtml:tagsToAdd removes:tagsToRemove];
        NSLog(tagButton);
        html = [html stringByAppendingString:tagButton];
    }

    // Outcomes Button
    if (OneSignal.iamV2Outcomes && ![OneSignal.iamV2Outcomes isEqualToString:@""]) {
        NSArray *outcomeSplit = [OneSignal.iamV2Outcomes componentsSeparatedByString:@","];
        NSMutableArray *outcomesToSend = [NSMutableArray new];
        for (var i = 0; i < outcomeSplit.count; i++) {
            NSString *outcome = [outcomeSplit objectAtIndex:i];
            NSArray *splitOutcome = [outcome componentsSeparatedByString:@":"];
            NSString *outcomeKey = [splitOutcome objectAtIndex:0];

            if (splitOutcome.count == 1) {
                [outcomesToSend addObject:@{
                    @"name" : outcomeKey
                }];
            } else if (splitOutcome.count == 2) {
                NSString* outcomeValue = [splitOutcome objectAtIndex:1];
                if ([outcomeValue isEqualToString:@"true"] || [outcomeValue isEqualToString:@"false"]) {
                    [outcomesToSend addObject:@{
                        @"name" : outcomeKey,
                        @"unique" : @([outcomeValue boolValue])
                    }];
                }
                else {
                    [outcomesToSend addObject:@{
                        @"name" : outcomeKey,
                        @"weight" : @([outcomeValue floatValue])
                    }];
                }
            }
        }
        NSString* outcomeButton = [self addOutcomesButtonToHtml:outcomesToSend];
        NSLog(outcomeButton);
        html = [html stringByAppendingString:outcomeButton];
    }

    // Push Prompt Button
    if ([OneSignal.iamV2Prompting containsObject:@"push"]) {
        NSString *pushButton = [self addPushPromptingButtonToHtml];
        NSLog(pushButton);
        html = [html stringByAppendingString:pushButton];
    }

    // Location Prompt Button
    if ([OneSignal.iamV2Prompting containsObject:@"location"]) {
        NSString *locationButton = [self addLocationPromptingButtonToHtml];
        NSLog(locationButton);
        html = [html stringByAppendingString:locationButton];
    }

    html = [html stringByAppendingString:suffix];

    dispatch_sync(dispatch_get_main_queue(), ^{
     NSLog(@"222222 [self.webView loadHTMLString:html baseURL:url];");
     [self.webView loadHTMLString:html baseURL:url];
    });
}

- (NSString*)addTagsButtonToHtml:(NSDictionary *)adds removes:(NSArray *)removes {
    NSString *dismiss = OneSignal.iamV2ShouldDismiss ? @"true" : @"false";

    NSError* error = nil;
    NSData *addsJsonData = [NSJSONSerialization dataWithJSONObject:adds options:NSJSONWritingPrettyPrinted error:&error];
    NSString *addsJsonString = [[NSString alloc] initWithData:addsJsonData encoding:NSUTF8StringEncoding];
    NSLog(addsJsonString.description);
    if (error)
        NSLog(error.description);
    error = nil;

    NSData *removesJsonData = [NSJSONSerialization dataWithJSONObject:removes options:NSJSONWritingPrettyPrinted error:&error];
    NSString *removesJsonString = [[NSString alloc] initWithData:removesJsonData encoding:NSUTF8StringEncoding];
    NSLog(removesJsonString.description);
    if (error)
        NSLog(error.description);

    return [[NSString alloc] initWithFormat:
             @"<button type=\"button\" id=\"button\" class=\"iam-button iam-clickable\""
             @"   data-action-payload='{"
             @"       \"url_target\":\"browser\","
             @"       \"close\":%@,"
             @"       \"url\":\"\","
             @"       \"tags\":{"
             @"           \"adds\":%@,"
             @"           \"removes\":%@"
             @"       }"
             @"   }'"
             @"   data-action-label=\"button\">Send Tags</button>\n"
             @"\n",
             dismiss, addsJsonString, removesJsonString];
   }

- (NSString*)addOutcomesButtonToHtml:(NSArray*) outcomeJson {
       NSString *dismiss = OneSignal.iamV2ShouldDismiss ? @"true" : @"false";

        NSError* error = nil;
        NSData *outcomesJsonData = [NSJSONSerialization dataWithJSONObject:outcomeJson options:NSJSONWritingPrettyPrinted error:&error];
        NSString *outcomesJsonString = [[NSString alloc] initWithData:outcomesJsonData encoding:NSUTF8StringEncoding];
        NSLog(outcomesJsonString.description);
        if (error)
            NSLog(error.description);

        return [[NSString alloc] initWithFormat:
             @"<button type=\"button\" id=\"button\" class=\"iam-button iam-clickable\""
             @"   data-action-payload='{"
             @"       \"url_target\":\"browser\","
             @"       \"close\":%@,"
             @"       \"url\":\"\","
             @"       \"outcomes\":%@"
             @"   }'"
             @"   data-action-label=\"button\">Send Outcomes</button>\n"
             @"\n",
             dismiss, outcomesJsonString];
   }

- (NSString*)addPushPromptingButtonToHtml {
    NSString *dismiss = OneSignal.iamV2ShouldDismiss ? @"true" : @"false";

    return [[NSString alloc] initWithFormat:
             @"<button type=\"button\" id=\"button\" class=\"iam-button iam-clickable\""
             @"   data-action-payload='{"
             @"       \"url_target\":\"browser\","
             @"       \"close\":%@,"
             @"       \"url\":\"\","
             @"       \"prompts\":[\"push\"]"
             @"   }'"
             @"   data-action-label=\"button\">Push Prompt</button>\n"
             @"\n",
             dismiss];
}

- (NSString*)addLocationPromptingButtonToHtml {
   NSString *dismiss = OneSignal.iamV2ShouldDismiss ? @"true" : @"false";

   return [[NSString alloc] initWithFormat:
            @"<button type=\"button\" id=\"button\" class=\"iam-button iam-clickable\""
            @"   data-action-payload='{"
            @"       \"url_target\":\"browser\","
            @"       \"close\":%@,"
            @"       \"url\":\"\","
            @"       \"prompts\":[\"location\"]"
            @"   }'"
            @"   data-action-label=\"button\">Location Prompt</button>\n"
            @"\n",
            dismiss];
}

- (void)setupWebviewWithMessageHandler:(id<WKScriptMessageHandler>)handler {
    let configuration = [WKWebViewConfiguration new];
    [configuration.userContentController addScriptMessageHandler:handler name:@"iosListener"];
    
    CGFloat marginSpacing = [OneSignalViewHelper sizeToScale:MESSAGE_MARGIN];
    
    // WebView should use mainBounds as frame since we need to make sure it spans full possible screen size
    // to prevent text wrapping while obtaining true height of message from JS
    CGRect mainBounds = UIScreen.mainScreen.bounds;
    mainBounds.size.width -= (2.0 * marginSpacing);
    
    // Setup WebView, delegates, and disable scrolling inside of the WebView
    self.webView = [[WKWebView alloc] initWithFrame:mainBounds configuration:configuration];
    
    [self addSubview:self.webView];
    
    [self layoutIfNeeded];
}

/*
 Method for resetting the height of the WebView so the JS can calculate the new height
 WebView will have margins accounted for on width, but height just needs to be phone height or larger
 The issue is that text wrapping can cause incorrect height issues so width is the real concern here
 */
- (void)resetWebViewToMaxBoundsAndResizeHeight:(void (^) (NSNumber *newHeight)) completion {
    [self.webView removeConstraints:[self.webView constraints]];
    
    CGFloat marginSpacing = [OneSignalViewHelper sizeToScale:MESSAGE_MARGIN];
    CGRect mainBounds = UIScreen.mainScreen.bounds;
    mainBounds.size.width -= (2.0 * marginSpacing);
    
    [self.webView setFrame:mainBounds];
    [self.webView layoutIfNeeded];
    
    // Evaluate JS getPageMetaData() method to obtain the updated height for the messageView to contain the webView contents
    [self.webView evaluateJavaScript:OS_JS_GET_PAGE_META_DATA_METHOD completionHandler:^(NSDictionary *result, NSError *error) {
        if (error) {
            NSString *errorMessage = [NSString stringWithFormat:@"Javascript Method: %@ Evaluated with Error: %@", OS_JS_GET_PAGE_META_DATA_METHOD, error];
            [OneSignal onesignal_Log:ONE_S_LL_ERROR message:errorMessage];
            return;
        }
        NSString *successMessage = [NSString stringWithFormat:@"Javascript Method: %@ Evaluated with Success: %@", OS_JS_GET_PAGE_META_DATA_METHOD, result];
        [OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:successMessage];
        
        [self setupWebViewConstraints];

        // Extract the height from the result and pass it to the current messageView
        NSNumber *height = [self extractHeightFromMetaDataPayload:result];
        completion(height);
    }];
}

- (NSNumber *)extractHeightFromMetaDataPayload:(NSDictionary *)result {
    return @([result[@"rect"][@"height"] intValue]);
}

- (void)setupWebViewConstraints {
    [OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"Setting up In-App Message WebView Constraints"];
    
    [self.webView removeConstraints:[self.webView constraints]];
    
    self.webView.translatesAutoresizingMaskIntoConstraints = false;
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.scrollEnabled = false;
    
    self.webView.layer.cornerRadius = 10.0f;
    self.webView.layer.masksToBounds = true;
    
    if (@available(iOS 11, *))
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    [self.webView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = true;
    [self.webView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = true;
    [self.webView.topAnchor constraintEqualToAnchor:self.topAnchor].active = true;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = true;
    
    [self layoutIfNeeded];
}

/*
 Make sure to call this method when the message view gets dismissed
 Otherwise a memory leak will occur and the entire view controller will be leaked
 */
- (void)removeScriptMessageHandler {
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"iosListener"];
}

- (void)loadReplacementURL:(NSURL *)url {
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark WKWebViewNavigationDelegate Methods
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // WebView finished loading
    if (self.loaded)
        return;
    
    self.loaded = true;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView
                          withView:(UIView *)view {
    // Disable pinch zooming
    if (scrollView.pinchGestureRecognizer)
        scrollView.pinchGestureRecognizer.enabled = false;
}

@end
