#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Block type for receiving log messages
typedef void (^PLTLogCallback)(NSString *logMessage);

/// Objective-C implementation of log interceptor that redirects stdout and stderr
@interface PLTLogInterceptor : NSObject

/// Initialize a new log interceptor with a callback block
/// @param callback Block that will be called with each log message
- (instancetype)initWithCallback:(PLTLogCallback)callback;

/// Start redirecting stdout and stderr
- (void)redirectLogs;

/// Stop redirecting stdout and stderr
- (void)stopRedirecting;

@end

NS_ASSUME_NONNULL_END
