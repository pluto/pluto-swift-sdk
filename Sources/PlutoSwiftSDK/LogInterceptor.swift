import Foundation

/// Swift implementation of log interceptor
public class LogInterceptor {
    private var stdoutPipe: Pipe
    private var stderrPipe: Pipe
    private var logCallback: ((String) -> Void)?

    // Store original file descriptors to restore them later
    private var originalStdout: Int32 = -1
    private var originalStderr: Int32 = -1

    // Flag to track if we're currently intercepting
    private var isIntercepting = false

    /// Initialize a new log interceptor with a callback for log messages
    /// - Parameter callback: A closure that will be called with each log message
    public init(callback: @escaping (String) -> Void) {
        self.stdoutPipe = Pipe()
        self.stderrPipe = Pipe()
        self.logCallback = callback

        // Set up signal handler for SIGPIPE
        signal(SIGPIPE) { _ in
            print("SIGPIPE received, pipe may have been closed")
        }
    }

    /// Start intercepting log messages
    public func redirectLogs() {
        // Prevent multiple redirections
        guard !isIntercepting else { return }

        // Store original file descriptors
        originalStdout = dup(STDOUT_FILENO)
        originalStderr = dup(STDERR_FILENO)

        // Make sure file handles are open
        stdoutPipe = Pipe()
        stderrPipe = Pipe()

        // Set pipes to non-blocking
        setNonblockingPipe(stdoutPipe)
        setNonblockingPipe(stderrPipe)

        // Redirect stdout and stderr
        dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // Capture the logs
        captureOutput(from: stdoutPipe)
        captureOutput(from: stderrPipe)

        isIntercepting = true
    }

    private func setNonblockingPipe(_ pipe: Pipe) {
        let fileDescriptor = pipe.fileHandleForReading.fileDescriptor
        var flags = fcntl(fileDescriptor, F_GETFL)
        flags |= O_NONBLOCK
        fcntl(fileDescriptor, F_SETFL, flags)
    }

    private func captureOutput(from pipe: Pipe) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }

            do {
                let data = handle.availableData
                if data.count > 0, let log = String(data: data, encoding: .utf8), !log.isEmpty {
                    self.logCallback?(log)
                }
            } catch {
                print("Error reading from pipe: \(error)")
            }
        }
    }

    /// Stop intercepting log messages
    public func stopRedirecting() {
        guard isIntercepting else { return }

        // Remove readability handlers first
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        // Flush any pending output
        fflush(stdout)
        fflush(stderr)

        // Restore original file descriptors if they were saved
        if originalStdout != -1 {
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
            originalStdout = -1
        }

        if originalStderr != -1 {
            dup2(originalStderr, STDERR_FILENO)
            close(originalStderr)
            originalStderr = -1
        }

        isIntercepting = false
    }

    deinit {
        stopRedirecting()
    }

    /// Simple test function to demonstrate the log interceptor
    public static func runTest() {
        print("Starting LogInterceptor test...")

        // Create a log interceptor
        let interceptor = LogInterceptor { message in
            print("🔍 Intercepted: \(message)", terminator: "")
        }

        // Start redirecting logs
        interceptor.redirectLogs()

        // Generate some test output
        print("This is a test message to stdout")
        print("Another test message with a number: \(42)")
        fputs("This is a test message to stderr\n", stderr)

        // Small delay to ensure logs are processed
        Thread.sleep(forTimeInterval: 0.5)

        // Stop redirecting
        interceptor.stopRedirecting()

        print("\n--- Test Complete ---")
    }
}
