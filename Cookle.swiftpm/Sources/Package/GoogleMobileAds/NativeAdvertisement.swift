//
//  NativeAdvertisement.swift
//  Incomes
//
//  Created by Hiromu Nakano on 2022/01/15.
//  Copyright © 2022 Hiromu Nakano. All rights reserved.
//

import SwiftUI

struct NativeAdvertisement {
    @Environment(CookleGoogleMobileAds.self) private var googleMobileAds

    enum Size: String {
        case small = "Small"
        case medium = "Medium"

        var width: CGFloat {
            switch self {
            case .small:
                return 360

            case .medium:
                return 360
            }
        }

        var height: CGFloat {
            switch self {
            case .small:
                return 120

            case .medium:
                return 320
            }
        }
    }

    let size: Size
}

extension NativeAdvertisement: View {
    var body: some View {
        googleMobileAds(size.rawValue)
            .frame(maxWidth: size.width,
                   minHeight: size.height)
    }
}

#Preview {
    NativeAdvertisement(size: .medium)
}
