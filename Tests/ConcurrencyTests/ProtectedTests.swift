@testable import Concurrency
import XCTest

@available(iOS 13.0, *)
final class ProtectedTests: XCTestCase {

    struct Subject {
        var value: Int = 0
    }

    var metrics: [XCTMetric] {
        [XCTClockMetric()]
    }

    func checkThreadSafety(iterations: Int = 100, _ block: @escaping (Int) -> Void) {
        let queue = DispatchQueue(label: "works.dan.Utilities.Concurrency.ProtectedTests", qos: .default, attributes: .concurrent)
        let group = DispatchGroup()
        let exp = expectation(description: "group")
        for iteration in 0..<iterations {
            group.enter()
            queue.async {
                block(iteration)
                group.leave()
            }
        }
        group.notify(queue: queue) {
            exp.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }

    func testReadWriteSingleValue() {
        @Protected var subject = Subject()
        XCTAssertEqual(subject.value, 0)
        subject.value = 1
        XCTAssertEqual(subject.value, 1)
        $subject.write { $0.value = 2 }
        XCTAssertEqual($subject.read { $0.value }, 2)
    }

    func testReadWriteSingleValueBenchmark() {
        measure(metrics: metrics, options: .default, block: testReadWriteSingleValue)
    }

    func testReadWriteThreadSafety() {
        @Protected var subject = Subject()
        checkThreadSafety { _ in
            $subject.write { $0.value += 1 }
        }
        XCTAssertEqual(subject.value, 100)
    }

    func testReadWriteThreadSafetyBenchmark() {
        measure(metrics: metrics, options: .default, block: testReadWriteThreadSafety)
    }

    func testRangeReplaceableValue() {
        @Protected var subject = Array(0..<10)
        checkThreadSafety { iteration in
            $subject.append(contentsOf: Array(repeating: iteration, count: 10))
        }
        XCTAssertEqual(subject.count, 1010)
    }

    func testRangeReplaceableValueBenchmark() {
        measure(metrics: metrics, options: .default, block: testRangeReplaceableValue)
    }
}
