#import "ATServerHostSelector.h"


static void ShowToast(NSString *text) {
    UIFont *font = [UIFont systemFontOfSize:18];
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(280, 60) options:0 attributes:@{NSFontAttributeName: font} context:nil].size;
//    CGSize textSize = [text sizeWithFont:font constrainedToSize:CGSizeMake(280, 60)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, textSize.width + 10, textSize.height + 10)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = font;
    label.text = text;
    label.numberOfLines = 1;
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(1, 1);

    UIView *v = [UIView new];
    v.frame = CGRectMake(0, 0, textSize.width + 20, textSize.height + 20);
    label.center = CGPointMake(v.frame.size.width / 2, v.frame.size.height / 2);
    [v addSubview:label];

    v.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    v.layer.cornerRadius = 5;

    UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];

    CGFloat offsetLeft = 0, offsetTop = 0;

    CGPoint point = CGPointMake(window.frame.size.width/2, window.frame.size.height/2);
    point = CGPointMake(point.x + offsetLeft, point.y + offsetTop);
    v.center = point;

    [window addSubview:v];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            v.alpha = 0;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    });
}

@implementation ATServerHostSelector

- (instancetype)initWithProductionURL:(NSURL *)productionURL stagingURL:(NSURL *)stagingURL defaultDevelopmentURL:(NSURL *)defaultDevelopmentURL {
    self = [super init];
    if (self) {
        _productionURL = [productionURL copy];
        _stagingURL = [stagingURL copy];
        _defaultDevelopmentURL = [defaultDevelopmentURL copy];

        if (self.hostType != APIHostTypeProduction) {
            // delay because this code may run too early on startup
            dispatch_async(dispatch_get_main_queue(), ^{
                ShowToast([NSString stringWithFormat:@"Server: %@", self.hostTypeName]);
            });
         }
    }
    return self;
}

- (NSURL *)effectiveDevelopmentURL {
    return self.customDevelopmentURL ?: self.defaultDevelopmentURL;
}


- (NSURL *)customDevelopmentURL {
    return [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"api.debug.customDevelopmentURL"]];
}

- (void)setCustomDevelopmentURL:(NSURL *)customDevelopmentURL {
    if (customDevelopmentURL)
        [[NSUserDefaults standardUserDefaults] setObject:[customDevelopmentURL absoluteString] forKey:@"api.debug.customDevelopmentURL"];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"api.debug.customDevelopmentURL"];
}

- (NSString *)customDevelopmentURLString {
    return [self.customDevelopmentURL absoluteString] ?: @"";
}

- (void)setCustomDevelopmentURLString:(NSString *)customDevelopmentURLString {
    customDevelopmentURLString = [customDevelopmentURLString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (customDevelopmentURLString.length > 0) {
        if ([customDevelopmentURLString rangeOfString:@"://"].location == NSNotFound) {
            customDevelopmentURLString = [@"http://" stringByAppendingString:customDevelopmentURLString];
        }
        self.customDevelopmentURL = [NSURL URLWithString:customDevelopmentURLString];
    } else {
        self.customDevelopmentURL = nil;
    }
}

- (ATServerHostType)hostType {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"api.debug.hostType"]; // defaults to 0, which is APIHostTypeProduction
}

- (NSString *)hostTypeName {
    switch (self.hostType) {
        case APIHostTypeProduction:  return @"Production";
        case APIHostTypeStaging:     return @"Staging";
        case APIHostTypeDevelopment: return @"Development";
        default: abort();
    }
}

- (void)setHostType:(ATServerHostType)hostType {
    if (hostType == 0)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"api.debug.hostType"];
    else
        [[NSUserDefaults standardUserDefaults] setInteger:hostType forKey:@"api.debug.hostType"];
}

- (NSURL *)effectiveURL {
    switch (self.hostType) {
        case APIHostTypeProduction:  return self.productionURL;
        case APIHostTypeStaging:     return self.stagingURL;
        case APIHostTypeDevelopment: return self.effectiveDevelopmentURL;
        default: abort();
    }
}

- (void)toggleHostType {
    if (self.hostType == APIHostTypeDevelopment)
        self.hostType = APIHostTypeProduction;
    else
        self.hostType = self.hostType + 1;
}

@end
