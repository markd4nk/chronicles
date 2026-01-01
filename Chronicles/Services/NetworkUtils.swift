//
//  NetworkUtils.swift
//  Chronicles
//
//  Network utility functions for timeout and retry handling
//

import Foundation

// MARK: - Errors

/// Error thrown when an operation times out
struct TimeoutError: Error, LocalizedError {
    let seconds: TimeInterval
    
    var errorDescription: String? {
        "Operation timed out after \(Int(seconds)) seconds"
    }
}

/// Error thrown when all retry attempts fail
struct RetryError: Error, LocalizedError {
    let attempts: Int
    let lastError: Error
    
    var errorDescription: String? {
        "Operation failed after \(attempts) attempts: \(lastError.localizedDescription)"
    }
}

// MARK: - Timeout

/// Execute an async operation with a timeout
/// - Parameters:
///   - seconds: Maximum time to wait before timing out
///   - operation: The async operation to execute
/// - Returns: The result of the operation
/// - Throws: TimeoutError if the operation doesn't complete in time, or the operation's error
func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the main operation
        group.addTask {
            try await operation()
        }
        
        // Add the timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError(seconds: seconds)
        }
        
        // Return the first result (either success or timeout)
        guard let result = try await group.next() else {
            throw TimeoutError(seconds: seconds)
        }
        
        // Cancel remaining tasks
        group.cancelAll()
        
        return result
    }
}

// MARK: - Retry with Exponential Backoff

/// Execute an async operation with automatic retry and exponential backoff
/// - Parameters:
///   - maxRetries: Maximum number of retry attempts (default: 3)
///   - initialDelay: Initial delay between retries in seconds (default: 1.0)
///   - maxDelay: Maximum delay between retries in seconds (default: 10.0)
///   - operation: The async operation to execute
/// - Returns: The result of the operation
/// - Throws: RetryError if all attempts fail
func withRetry<T>(
    maxRetries: Int = 3,
    initialDelay: TimeInterval = 1.0,
    maxDelay: TimeInterval = 10.0,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error = RetryError(attempts: 0, lastError: NSError(domain: "", code: 0))
    var currentDelay = initialDelay
    
    for attempt in 1...maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            // Don't delay after the last attempt
            if attempt < maxRetries {
                // Check if error is retryable
                if isRetryableError(error) {
                    print("[NetworkUtils] Attempt \(attempt) failed, retrying in \(currentDelay)s: \(error.localizedDescription)")
                    try? await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                    
                    // Exponential backoff with cap
                    currentDelay = min(currentDelay * 2, maxDelay)
                } else {
                    // Non-retryable error, throw immediately
                    throw error
                }
            }
        }
    }
    
    throw RetryError(attempts: maxRetries, lastError: lastError)
}

/// Combined timeout and retry - retry with timeout on each attempt
/// - Parameters:
///   - timeout: Timeout for each individual attempt
///   - maxRetries: Maximum number of retry attempts
///   - operation: The async operation to execute
/// - Returns: The result of the operation
func withTimeoutAndRetry<T: Sendable>(
    timeout: TimeInterval = 5.0,
    maxRetries: Int = 3,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withRetry(maxRetries: maxRetries) {
        try await withTimeout(seconds: timeout, operation: operation)
    }
}

// MARK: - Helper Functions

/// Check if an error is retryable (network errors, timeouts, etc.)
private func isRetryableError(_ error: Error) -> Bool {
    // Timeout errors are retryable
    if error is TimeoutError {
        return true
    }
    
    // Check NSError codes for network errors
    let nsError = error as NSError
    
    // Common retryable network error codes
    let retryableCodes: Set<Int> = [
        NSURLErrorTimedOut,                    // -1001
        NSURLErrorCannotFindHost,              // -1003
        NSURLErrorCannotConnectToHost,         // -1004
        NSURLErrorNetworkConnectionLost,       // -1005
        NSURLErrorNotConnectedToInternet,      // -1009
        NSURLErrorSecureConnectionFailed,      // -1200
    ]
    
    if nsError.domain == NSURLErrorDomain && retryableCodes.contains(nsError.code) {
        return true
    }
    
    // Firebase/Firestore specific errors (typically in domain "FIRFirestoreErrorDomain")
    // Error code 14 = Unavailable (network issues)
    if nsError.code == 14 {
        return true
    }
    
    return false
}

