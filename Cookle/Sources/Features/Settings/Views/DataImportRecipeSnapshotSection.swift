import Foundation
import MHUI
import SwiftUI

/// Shows one recipe version in full so current and file versions can be compared.
struct DataImportRecipeSnapshotSection: View {
    private enum Layout {
        static let photoHeight: CGFloat = 72
        static let photoCornerRadius: CGFloat = 8
    }

    let title: String
    let snapshot: CookleDataImportReview.RecipeSnapshot
    let footer: String?

    var body: some View {
        Section {
            LabeledContent("Name", value: snapshot.name)
            LabeledContent("Serving Size", value: numberText(snapshot.servingSize))
            LabeledContent("Cooking Time", value: numberText(snapshot.cookingTime))
            LabeledContent("Ingredients", value: ingredientsText)
                .mhKeyValueLayout(.vertical)
            LabeledContent("Steps", value: stepsText)
                .mhKeyValueLayout(.vertical)
            LabeledContent("Categories", value: listText(snapshot.categories))
            LabeledContent("Note", value: snapshot.note.isEmpty ? String(localized: "None") : snapshot.note)
                .mhKeyValueLayout(.vertical)
            photosRow
        } header: {
            Text(title)
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }
}

private extension DataImportRecipeSnapshotSection {
    var ingredientsText: String {
        guard snapshot.ingredients.isEmpty == false else {
            return String(localized: "None")
        }

        return snapshot.ingredients
            .map { ingredient in
                ingredient.amount.isEmpty ? ingredient.name : "\(ingredient.name)  \(ingredient.amount)"
            }
            .joined(separator: "\n")
    }

    var stepsText: String {
        guard snapshot.steps.isEmpty == false else {
            return String(localized: "None")
        }

        return snapshot.steps.enumerated()
            .map { index, step in
                "\(index + 1). \(step)"
            }
            .joined(separator: "\n")
    }

    @ViewBuilder var photosRow: some View {
        if snapshot.photos.isEmpty {
            LabeledContent("Photos", value: String(localized: "None"))
        } else {
            VStack(alignment: .leading) {
                Text("Photos: \(snapshot.photos.count)")
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(snapshot.photos.enumerated()), id: \.offset) { index, photo in
                            VStack {
                                CooklePhotoImage(
                                    data: photo.data,
                                    identity: .draft(photoIdentity(photo.digest)),
                                    size: .thumbnail
                                )
                                .frame(height: Layout.photoHeight)
                                .clipShape(.rect(cornerRadius: Layout.photoCornerRadius))
                                .accessibilityLabel(Text("Photo \(index + 1)"))
                                (PhotoSource(rawValue: photo.sourceID) ?? .defaultValue).sectionTitle
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }

    func numberText(_ value: Int) -> String {
        value == .zero ? String(localized: "Not set") : value.formatted()
    }

    func listText(_ values: [String]) -> String {
        values.isEmpty ? String(localized: "None") : values.formatted(.list(type: .and))
    }

    /// Derives a stable cache identity from the image digest, so the same
    /// image in both versions decodes once.
    func photoIdentity(_ digest: Data) -> UUID {
        var bytes = [UInt8](repeating: .zero, count: MemoryLayout<uuid_t>.size)
        for (index, byte) in digest.prefix(bytes.count).enumerated() {
            bytes[index] = byte
        }
        return bytes.withUnsafeBytes { buffer in
            UUID(uuid: buffer.loadUnaligned(as: uuid_t.self))
        }
    }
}
