import XCTest
@testable import Mise

final class DeviceSessionDecodingTests: XCTestCase {
    func testSessionListDecodesFullWireShape() throws {
        let response = try MiseJSON.decoder().decode(
            SessionListResponse.self,
            from: Data(
                """
                {
                  "sessions": [
                    {
                      "id": "sess_current",
                      "device": {
                        "name": "Kevin’s iPhone",
                        "platform": "ios",
                        "app_version": "1.0"
                      },
                      "created_at": "2026-07-01T12:00:00Z",
                      "last_seen_at": "2026-07-13T14:15:16Z",
                      "expires_at": "2026-07-31T12:00:00Z",
                      "is_current": true,
                      "revoked_at": null
                    },
                    {
                      "id": "sess_old",
                      "device": {"name": null, "platform": null, "app_version": null},
                      "created_at": "2026-06-01T12:00:00Z",
                      "last_seen_at": null,
                      "expires_at": "2026-06-30T12:00:00Z",
                      "is_current": false,
                      "revoked_at": "2026-06-20T09:30:00Z"
                    }
                  ]
                }
                """.utf8
            )
        )

        XCTAssertEqual(response.sessions.map(\.id), ["sess_current", "sess_old"])

        let current = response.sessions[0]
        XCTAssertEqual(current.device.name, "Kevin’s iPhone")
        XCTAssertEqual(current.device.platform, "ios")
        XCTAssertEqual(current.device.appVersion, "1.0")
        XCTAssertEqual(
            current.createdAt,
            try Self.date("2026-07-01T12:00:00Z")
        )
        XCTAssertEqual(
            current.lastSeenAt,
            try Self.date("2026-07-13T14:15:16Z")
        )
        XCTAssertEqual(
            current.expiresAt,
            try Self.date("2026-07-31T12:00:00Z")
        )
        XCTAssertTrue(current.isCurrent)
        XCTAssertNil(current.revokedAt)

        let old = response.sessions[1]
        XCTAssertNil(old.device.name)
        XCTAssertNil(old.device.platform)
        XCTAssertNil(old.device.appVersion)
        XCTAssertNil(old.lastSeenAt)
        XCTAssertFalse(old.isCurrent)
        XCTAssertEqual(old.revokedAt, try Self.date("2026-06-20T09:30:00Z"))
    }

    func testSessionDecodingDefaultsAbsentCurrentFlagAndOptionalFields() throws {
        let response = try MiseJSON.decoder().decode(
            SessionListResponse.self,
            from: Data(
                """
                {
                  "sessions": [
                    {
                      "id": "sess_minimal",
                      "device": {},
                      "created_at": "2026-07-01T12:00:00Z",
                      "expires_at": "2026-07-31T12:00:00Z"
                    }
                  ]
                }
                """.utf8
            )
        )

        let session = try XCTUnwrap(response.sessions.first)
        XCTAssertEqual(session.id, "sess_minimal")
        XCTAssertNil(session.device.name)
        XCTAssertNil(session.device.platform)
        XCTAssertNil(session.device.appVersion)
        XCTAssertNil(session.lastSeenAt)
        XCTAssertFalse(session.isCurrent)
        XCTAssertNil(session.revokedAt)
    }

    func testSessionDecodingIgnoresUnknownFields() throws {
        let response = try MiseJSON.decoder().decode(
            SessionListResponse.self,
            from: Data(
                """
                {
                  "sessions": [
                    {
                      "id": "sess_future",
                      "device": {"name": "iPad", "future_device_field": 7},
                      "created_at": "2026-07-01T12:00:00Z",
                      "expires_at": "2026-07-31T12:00:00Z",
                      "is_current": true,
                      "future_session_field": "ignored"
                    }
                  ],
                  "future_response_field": true
                }
                """.utf8
            )
        )

        let session = try XCTUnwrap(response.sessions.first)
        XCTAssertEqual(session.id, "sess_future")
        XCTAssertEqual(session.device.name, "iPad")
        XCTAssertTrue(session.isCurrent)
    }

    private static func date(_ value: String) throws -> Date {
        try MiseJSON.decoder().decode(Date.self, from: Data("\"\(value)\"".utf8))
    }
}
