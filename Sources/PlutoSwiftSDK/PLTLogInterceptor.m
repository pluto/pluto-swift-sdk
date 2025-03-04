#import "PLTLogInterceptor.h"
#include <unistd.h>

@implementation PLTLogInterceptor {
    NSPipe *_stdoutPipe;
    NSPipe *_stderrPipe;
    PLTLogCallback _logCallback;

    int _originalStdout;
    int _originalStderr;
    BOOL _isRedirecting;
}

- (instancetype)initWithCallback:(PLTLogCallback)callback {
    self = [super init];
    if (self) {
        _logCallback = callback;
        _stdoutPipe = [NSPipe pipe];
        _stderrPipe = [NSPipe pipe];
        _isRedirecting = NO;

        // Save original file descriptors
        _originalStdout = -1;
        _originalStderr = -1;
    }
    return self;
}

- (void)redirectLogs {
    // Prevent multiple redirections
    if (_isRedirecting) {
        return;
    }

    // Save original stdout and stderr
    _originalStdout = dup(STDOUT_FILENO);
    _originalStderr = dup(STDERR_FILENO);

    // Create fresh pipes
    _stdoutPipe = [NSPipe pipe];
    _stderrPipe = [NSPipe pipe];

    // Redirect stdout and stderr
    dup2([_stdoutPipe fileHandleForWriting].fileDescriptor, STDOUT_FILENO);
    dup2([_stderrPipe fileHandleForWriting].fileDescriptor, STDERR_FILENO);

    // Capture the logs
    [self captureOutput:_stdoutPipe];
    [self captureOutput:_stderrPipe];

    _isRedirecting = YES;
}

- (void)captureOutput:(NSPipe *)pipe {
    pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = [handle availableData];
        if (data.length > 0) {
            NSString *log = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (log.length > 0 && self->_logCallback) {
                self->_logCallback(log);
            }
        }
    };
}

- (void)stopRedirecting {
    if (!_isRedirecting) {
        return;
    }

    // Remove readability handlers
    _stdoutPipe.fileHandleForReading.readabilityHandler = nil;
    _stderrPipe.fileHandleForReading.readabilityHandler = nil;

    // Flush output
    fflush(stdout);
    fflush(stderr);

    // Restore original file descriptors
    if (_originalStdout != -1) {
        dup2(_originalStdout, STDOUT_FILENO);
        close(_originalStdout);
        _originalStdout = -1;
    }

    if (_originalStderr != -1) {
        dup2(_originalStderr, STDERR_FILENO);
        close(_originalStderr);
        _originalStderr = -1;
    }

    _isRedirecting = NO;
}

- (void)dealloc {
    [self stopRedirecting];
}

@end
