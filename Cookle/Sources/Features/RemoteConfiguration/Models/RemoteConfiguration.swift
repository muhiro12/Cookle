//
//  RemoteConfiguration.swift
//  Cookle
//
//  Created by Codex on 2025/06/17.
//

import Foundation

struct RemoteConfiguration: Decodable {
    struct ForceUpdate: Decodable {
        let minimumVersion: String
        let activatedAt: Date
        let expiresAt: Date
    }

    let forceUpdate: ForceUpdate?
}
