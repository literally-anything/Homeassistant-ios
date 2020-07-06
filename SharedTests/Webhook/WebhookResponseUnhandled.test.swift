import Foundation
@testable import Shared
import XCTest
import PromiseKit

class WebhookResponseUnhandledTests: XCTestCase {
    private var api: HomeAssistantAPI!

    enum TestError: Error {
        case any
    }

    override func setUp() {
        super.setUp()

        api = HomeAssistantAPI(
            connectionInfo: .init(
                externalURL: nil,
                internalURL: nil,
                cloudhookURL: nil,
                remoteUIURL: nil,
                webhookID: "id",
                webhookSecret: nil,
                internalSSIDs: nil
            ), tokenInfo: .init(
                accessToken: "atoken",
                refreshToken: "refreshtoken",
                expiration: Date()
            )
        )
    }

    func testReplacement() throws {
        let request1 = WebhookRequest(type: "any", data: [:])
        let request2 = WebhookRequest(type: "any", data: [:])
        let request3 = WebhookRequest(type: "any2", data: [:])

        XCTAssertFalse(WebhookResponseUnhandled.shouldReplace(request: request1, with: request2))
        XCTAssertFalse(WebhookResponseUnhandled.shouldReplace(request: request2, with: request3))
        XCTAssertFalse(WebhookResponseUnhandled.shouldReplace(request: request3, with: request1))
    }
}
