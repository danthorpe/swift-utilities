import Foundation

@available(macOS 10.15, *)
public enum DateProvider {
    @TaskLocal public static var now: () -> Date = Date.init
}
