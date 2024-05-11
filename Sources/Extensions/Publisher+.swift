#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
import Combine
import Foundation

extension Publisher {
  public func flatMap<NewOutput>(
    _ transform: @escaping (Output) async -> NewOutput
  ) -> Publishers.FlatMap<Future<NewOutput, Never>, Self> {
    flatMap { value in
      Future { promise in
        Task {
          let output = await transform(value)
          promise(.success(output))
        }
      }
    }
  }

  public func flatMap<NewOutput>(
    _ transform: @escaping (Output) async throws -> NewOutput
  ) -> Publishers.FlatMap<Future<NewOutput, Error>, Self> {
    flatMap { value in
      Future { promise in
        Task {
          do {
            let output = try await transform(value)
            promise(.success(output))
          } catch {
            promise(.failure(error))
          }
        }
      }
    }
  }
}
#endif
