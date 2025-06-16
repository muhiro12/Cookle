//
//  AppIntentsNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Codex on $(date +%Y/%m/%d).
//

import SwiftUI

struct AppIntentsNavigationView: View {
    var body: some View {
        NavigationStack {
            AppIntentsListView()
        }
    }
}

#Preview {
    CooklePreview { _ in
        AppIntentsNavigationView()
    }
}
