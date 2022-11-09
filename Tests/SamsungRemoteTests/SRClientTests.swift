//
//  SRClientTests.swift
//
//
//  Created by Wilson Desimini on 11/2/22.
//

import XCTest
import Starscream
@testable import SamsungRemote

final class SRClientTests: XCTestCase {
    private let app = "SamsungRemoteApp"
    private let ipAddress = "192.168.0.21"
    private var client: SRClient!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        client = nil
    }

    private func injectMockEvents(_ events: [WebSocketEvent]) {
        client = .init(
            app: app,
            ipAddress: ipAddress,
            websocketFactory: SRWebSocketMockFactory(
                events: events
            )
        )
    }

    func testAuthAllowed() async throws {
        // given
        injectMockEvents([
            .viabilityChanged(true),
            .connectedMock,
            try .textMock("auth_approved"),
            .cancelled,
        ])
        // when
        let token = try await client.auth()
        // then
        XCTAssertEqual(token, "11111111")
    }

    func testAuthCancelled() async throws {
        // given
        injectMockEvents([
            .viabilityChanged(true),
            .connectedMock,
            try .textMock("auth_cancelled"),
            .cancelled,
        ])
        // when
        var authError: Error?
        do { let _ = try await client.auth() }
        catch { authError = error }
        // then
        if case let .channelEvent(event) = authError as? SRError {
            XCTAssertEqual(event, .timeout)
        } else {
            XCTFail()
        }
    }

    func testAuthDenied() async throws {
        // given
        injectMockEvents([
            .viabilityChanged(true),
            .connectedMock,
            try .textMock("auth_denied"),
            .cancelled,
        ])
        // when
        var authError: Error?
        do { let _ = try await client.auth() }
        catch { authError = error }
        // then
        if case let .channelEvent(event) = authError as? SRError {
            XCTAssertEqual(event, .unauthorized)
        } else {
            XCTFail()
        }
    }
}