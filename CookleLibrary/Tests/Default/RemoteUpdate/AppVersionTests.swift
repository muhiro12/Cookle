import CookleLibrary
import Testing

struct AppVersionTests {
    @Test
    func parsesOneToThreeASCIIIntegerComponents() {
        #expect(AppVersion("3") != nil)
        #expect(AppVersion("3.9") != nil)
        #expect(AppVersion("3.9.0") != nil)
        #expect(AppVersion("03.009.000") != nil)
    }

    @Test
    func normalizesMissingComponentsForEquality() throws {
        let shortVersion = try #require(AppVersion("3.9"))
        let fullVersion = try #require(AppVersion("3.9.0"))

        #expect(shortVersion == fullVersion)
        #expect(Set([shortVersion, fullVersion]).count == 1)
    }

    @Test
    func comparesComponentsNumerically() throws {
        let versionThreeNine = try #require(AppVersion("3.9"))
        let versionThreeTen = try #require(AppVersion("3.10"))
        let versionFour = try #require(AppVersion("4"))

        #expect(versionThreeNine < versionThreeTen)
        #expect(versionThreeTen < versionFour)
    }

    @Test
    func rejectsMalformedVersions() {
        let invalidValues = [
            "",
            ".",
            "3.",
            ".9",
            "3..9",
            "3.9.0.1",
            " 3.9",
            "3.9 ",
            "+3.9",
            "-3.9",
            "3.9-beta",
            "３.９",
            "999999999999999999999999999999999999"
        ]

        for invalidValue in invalidValues {
            #expect(AppVersion(invalidValue) == nil)
        }
    }
}
