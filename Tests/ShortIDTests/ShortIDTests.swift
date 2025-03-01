import Testing

@testable import ShortID

@Suite struct ShortIDTests {

  @Test func test__shortIDs() {
    let count = 10_000
    let shortIDs: Set<ShortID> = (0 ..< count)
      .map { _ in ShortID() }
      .reduce(into: [], { $0.insert($1) })
    #expect(shortIDs.count == count)
  }

  @Test func test__incrementing_shortIDs() {
    let generator = ShortIDGenerator.incrementing
    let shortIDs: [String] = (0 ..< 100)
      .map { _ in generator().description }
    #expect(shortIDs[0] == "000001")
    #expect(shortIDs[1] == "000002")
    #expect(shortIDs[2] == "000003")
    #expect(shortIDs[3] == "000004")
    #expect(shortIDs[4] == "000005")
    #expect(shortIDs[5] == "000006")
  }
}
