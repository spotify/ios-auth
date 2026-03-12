import Foundation

final class FakeCoder: NSCoder {
    var objects: [String: Any] = [:]

    override var allowsKeyedCoding: Bool { true }

    override func encode(_ objv: Any?, forKey key: String) {
        objects[key] = objv
    }
}
