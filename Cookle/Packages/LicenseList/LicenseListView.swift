//
//  SwiftUIView.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/05.
//

import SwiftUI
import LicenseList

public struct LicenseListView: View {
    public init() {}

    public var body: some View {
        LicenseList.LicenseListView()
            .licenseListViewStyle(.withRepositoryAnchorLink)
    }
}

#Preview {
    NavigationStack {
        LicenseListView()
    }
}
