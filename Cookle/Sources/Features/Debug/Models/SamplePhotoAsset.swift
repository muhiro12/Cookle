import Foundation

enum SamplePhotoAsset: CaseIterable {
    case spaghettiCarbonara1
    case spaghettiCarbonara2
    case beefStew1
    case beefStew2
    case chickenStirFry1
    case chickenStirFry2
    case vegetableSoup1
    case vegetableSoup2
    case pancakes1
    case pancakes2

    var fileName: String {
        switch self {
        case .spaghettiCarbonara1:
            "SpaghettiCarbonara1.png"
        case .spaghettiCarbonara2:
            "SpaghettiCarbonara2.png"
        case .beefStew1:
            "BeefStew1.png"
        case .beefStew2:
            "BeefStew2.png"
        case .chickenStirFry1:
            "ChickenStirFry1.png"
        case .chickenStirFry2:
            "ChickenStirFry2.png"
        case .vegetableSoup1:
            "VegetableSoup1.png"
        case .vegetableSoup2:
            "VegetableSoup2.png"
        case .pancakes1:
            "Pancakes1.png"
        case .pancakes2:
            "Pancakes2.png"
        }
    }

    var fallbackSystemImageName: String {
        switch self {
        case .spaghettiCarbonara1:
            "frying.pan"
        case .spaghettiCarbonara2:
            "oval.portrait"
        case .beefStew1:
            "fork.knife"
        case .beefStew2:
            "wineglass"
        case .chickenStirFry1:
            "bird"
        case .chickenStirFry2:
            "tree"
        case .vegetableSoup1:
            "cup.and.saucer"
        case .vegetableSoup2:
            "carrot"
        case .pancakes1:
            "birthday.cake"
        case .pancakes2:
            "mug"
        }
    }

    var remoteImageURL: URL? {
        .init(
            string: "https://raw.githubusercontent.com/muhiro12/Cookle/main/.Resources/\(fileName)"
        )
    }
}
