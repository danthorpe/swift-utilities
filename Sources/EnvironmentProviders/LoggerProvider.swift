import Foundation
import os.log

@available(iOS 14.0, *)
@available(macOS 11.0, *)
public enum LoggerProvider {
    @TaskLocal
    public static var logger: Logger?
}
