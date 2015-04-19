#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ATServerHostType) {
    APIHostTypeProduction,
    APIHostTypeStaging,
    APIHostTypeDevelopment,
};

@interface ATServerHostSelector : NSObject

- (instancetype)initWithProductionURL:(NSURL *)productionURL stagingURL:(NSURL *)stagingURL defaultDevelopmentURL:(NSURL *)defaultDevelopmentURL;

@property(nonatomic, copy, readonly) NSURL *productionURL;
@property(nonatomic, copy, readonly) NSURL *stagingURL;
@property(nonatomic, copy, readonly) NSURL *defaultDevelopmentURL;
@property(nonatomic, copy, readonly) NSURL *effectiveDevelopmentURL;

@property(nonatomic, copy) NSURL *customDevelopmentURL;
@property(nonatomic, copy) NSString *customDevelopmentURLString; // never nil

@property(nonatomic) ATServerHostType hostType;
@property(nonatomic, readonly) NSString *hostTypeName;

@property(nonatomic, copy, readonly) NSURL *effectiveURL;

- (void)toggleHostType;

@end
