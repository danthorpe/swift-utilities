import Testing

@testable import Protected

@Suite struct ProtectedTests {

  struct Subject {
    var value: Int = 0
  }

  func checkThreadSafety(iterations: Int = 100, _ block: @escaping @Sendable (Int) -> Void) async {
    await withTaskGroup(of: Void.self) { group in
      for iteration in 0 ..< iterations {
        group.addTask {
          block(iteration)
        }
      }
    }
  }

  @Test func testReadWriteSingleValue() {
    @Protected var subject = Subject()
    #expect(subject.value == 0)
    subject.value = 1
    #expect(subject.value == 1)
    $subject.write { $0.value = 2 }
    #expect($subject.read { $0.value } == 2)
  }

  @Test func testReadWriteThreadSafety() async {
    @Protected var subject = Subject()
    await checkThreadSafety { _ in
      $subject.write { $0.value += 1 }
    }
    #expect(subject.value == 100)
  }

  @Test func testRangeReplaceableValue() async {
    @Protected var subject = Array(0 ..< 10)
    await checkThreadSafety { iteration in
      $subject.append(contentsOf: Array(repeating: iteration, count: 10))
    }
    #expect(subject.count == 1010)
  }
}
