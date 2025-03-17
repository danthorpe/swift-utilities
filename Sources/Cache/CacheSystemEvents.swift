import AsyncAlgorithms
import Dependencies
import DependenciesMacros
import Dispatch
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

enum SystemEvent: Equatable, Sendable {
  enum MemoryPressure: Equatable, Sendable {
    case warning, normal
  }
  case applicationWillSuspend
  case applicationDidReceiveMemoryPressure(MemoryPressure)
}

@DependencyClient
struct CacheSystemEvents {
  var stream: @Sendable () -> AsyncStream<SystemEvent> = { .never }
}

extension CacheSystemEvents: DependencyKey {
  static let liveValue = liveValueWithNotificationCenter(.default)

  static func liveValueWithNotificationCenter(_ center: NotificationCenter) -> CacheSystemEvents {
    CacheSystemEvents {
      let memoryPressure = AsyncStream { continuation in
        let queue = DispatchQueue(label: "dan.works.swift-utilities.cache.memory-pressure")
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: queue)
        source.setEventHandler {
          var event = source.data
          event.formIntersection([.critical, .warning, .normal])
          if event.contains([.warning, .critical]) {
            continuation.yield(SystemEvent.applicationDidReceiveMemoryPressure(.warning))
          } else {
            continuation.yield(.applicationDidReceiveMemoryPressure(.normal))
          }
        }
      }

      let willResign = AsyncStream { continuation in
        Task {
          for await _ in center.notifications(named: .willResignActiveNotification) {
            continuation.yield(SystemEvent.applicationWillSuspend)
          }
        }
      }

      let willTerminate = AsyncStream { continuation in
        Task {
          for await _ in center.notifications(named: .willTerminateNotification) {
            continuation.yield(SystemEvent.applicationWillSuspend)
          }
        }
      }

      #if os(iOS)
      let additionalMemoryWarning = AsyncStream { continuation in
        Task {
          for await notification in center.notifications(named: UIApplication.didReceiveMemoryWarningNotification) {
            continuation.yield(SystemEvent.applicationDidReceiveMemoryPressure(.warning))
          }
        }
      }
      let stream = merge(memoryPressure, willResign, willTerminate, additionalMemoryWarning).erase()
      #else
      let stream = merge(memoryPressure, willResign, willTerminate)
      #endif

      return AsyncStream { continuation in
        Task {
          for await event in stream {
            continuation.yield(event)
          }
        }
      }
    }
  }

  static let testValue = CacheSystemEvents()
}

extension DependencyValues {
  var systemEvents: CacheSystemEvents {
    get { self[CacheSystemEvents.self] }
    set { self[CacheSystemEvents.self] = newValue }
  }
}

extension Notification.Name {
  static let willResignActiveNotification: Self = {
    #if canImport(AppKit)
    return NSApplication.willResignActiveNotification
    #elseif canImport(UIKit)
    return UIApplication.willResignActiveNotification
    #endif
  }()

  static let willTerminateNotification: Self = {
    #if canImport(AppKit)
    return NSApplication.willTerminateNotification
    #elseif canImport(UIKit)
    return UIApplication.willTerminateNotification
    #endif
  }()
}
