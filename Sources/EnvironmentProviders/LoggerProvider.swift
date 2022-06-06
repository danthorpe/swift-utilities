import Foundation
import os.log

public enum LoggerProvider {
    @TaskLocal
    public static var logger: Logger?
}
