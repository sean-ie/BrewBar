import XCTest
@testable import BrewBar

// MARK: - BundleEntry

final class BundleEntryTests: XCTestCase {

    func test_isCheckable_onlyForBrewAndCask() {
        XCTAssertTrue(BundleEntry.EntryType.brew.isCheckable)
        XCTAssertTrue(BundleEntry.EntryType.cask.isCheckable)
        XCTAssertFalse(BundleEntry.EntryType.tap.isCheckable)
        XCTAssertFalse(BundleEntry.EntryType.mas.isCheckable)
        XCTAssertFalse(BundleEntry.EntryType.vscode.isCheckable)
        XCTAssertFalse(BundleEntry.EntryType.whalebrew.isCheckable)
    }

    func test_label() {
        XCTAssertEqual(BundleEntry.EntryType.brew.label, "formula")
        XCTAssertEqual(BundleEntry.EntryType.cask.label, "cask")
        XCTAssertEqual(BundleEntry.EntryType.tap.label, "tap")
        XCTAssertEqual(BundleEntry.EntryType.mas.label, "mas")
    }

    func test_id_isUniquePerTypeAndName() {
        let a = BundleEntry(type: .brew, name: "git", isInstalled: false)
        let b = BundleEntry(type: .cask, name: "git", isInstalled: false)
        XCTAssertEqual(a.id, "brew:git")
        XCTAssertEqual(b.id, "cask:git")
        XCTAssertNotEqual(a.id, b.id)
    }
}

// MARK: - BrewBundle

final class BrewBundleTests: XCTestCase {

    private func makeBundle(_ entries: [BundleEntry]) -> BrewBundle {
        BrewBundle(path: "/tmp/Brewfile", displayName: "Brewfile", entries: entries)
    }

    func test_counts_excludeNonCheckableEntries() {
        let bundle = makeBundle([
            BundleEntry(type: .brew, name: "git",         isInstalled: true),
            BundleEntry(type: .brew, name: "tree",        isInstalled: false),
            BundleEntry(type: .cask, name: "firefox",     isInstalled: true),
            BundleEntry(type: .tap,  name: "oven-sh/bun", isInstalled: true), // not checkable
        ])
        XCTAssertEqual(bundle.checkableCount, 3)
        XCTAssertEqual(bundle.installedCount, 2)
        XCTAssertEqual(bundle.missingCount,   1)
    }

    func test_emptyBundle() {
        let bundle = makeBundle([])
        XCTAssertEqual(bundle.installedCount, 0)
        XCTAssertEqual(bundle.missingCount,   0)
        XCTAssertEqual(bundle.checkableCount, 0)
    }

    func test_allInstalled() {
        let bundle = makeBundle([
            BundleEntry(type: .brew, name: "git",  isInstalled: true),
            BundleEntry(type: .cask, name: "zoom", isInstalled: true),
        ])
        XCTAssertEqual(bundle.missingCount,   0)
        XCTAssertEqual(bundle.installedCount, 2)
    }
}

// MARK: - FormulaJSON → Formula mapping

final class FormulaJSONTests: XCTestCase {

    private func makeJSON(
        name: String = "git",
        desc: String? = "Distributed version control",
        version: String = "2.43.0",
        outdated: Bool = false,
        pinned: Bool = false,
        installedOnRequest: Bool = true,
        dependencies: [String] = []
    ) -> FormulaJSON {
        FormulaJSON(
            name: name,
            full_name: name,
            desc: desc,
            homepage: "https://git-scm.com",
            installed: [FormulaJSON.FormulaInstalled(
                version: version,
                installed_on_request: installedOnRequest
            )],
            outdated: outdated,
            pinned: pinned,
            license: "LGPL-2.1-only",
            tap: "homebrew/core",
            dependencies: dependencies,
            build_dependencies: nil
        )
    }

    func test_basicFields() {
        let f = makeJSON().toFormula()
        XCTAssertEqual(f.name,        "git")
        XCTAssertEqual(f.version,     "2.43.0")
        XCTAssertEqual(f.description, "Distributed version control")
        XCTAssertFalse(f.outdated)
        XCTAssertFalse(f.pinned)
    }

    func test_installedOnRequest_isPreserved() {
        XCTAssertTrue(makeJSON(installedOnRequest: true).toFormula().installedOnRequest)
        XCTAssertFalse(makeJSON(installedOnRequest: false).toFormula().installedOnRequest)
    }

    func test_emptyInstalledArray_fallsBackGracefully() {
        let json = FormulaJSON(
            name: "ghost", full_name: "ghost", desc: nil, homepage: nil,
            installed: [], outdated: false, pinned: false,
            license: nil, tap: nil, dependencies: nil, build_dependencies: nil
        )
        XCTAssertEqual(json.toFormula().version, "unknown")
        XCTAssertTrue(json.toFormula().installedOnRequest) // safe default
    }

    func test_dependencies() {
        let f = makeJSON(dependencies: ["openssl@3", "zlib"]).toFormula()
        XCTAssertEqual(f.dependencies, ["openssl@3", "zlib"])
    }
}

// MARK: - ServiceJSON → BrewService mapping

final class ServiceJSONTests: XCTestCase {

    func test_startedStatus() {
        let svc = ServiceJSON(name: "postgresql@14", status: "started",
                              pid: 1234, exit_code: nil, user: "sean", file: nil).toService()
        XCTAssertEqual(svc.status, .started)
        XCTAssertEqual(svc.pid, 1234)
    }

    func test_stoppedStatus() {
        let svc = ServiceJSON(name: "nginx", status: "stopped",
                              pid: nil, exit_code: 0, user: nil, file: nil).toService()
        XCTAssertEqual(svc.status, .stopped)
    }

    func test_errorStatus() {
        let svc = ServiceJSON(name: "redis", status: "error",
                              pid: nil, exit_code: 1, user: nil, file: nil).toService()
        XCTAssertEqual(svc.status, .error)
    }

    func test_unknownStatus_forUnrecognisedString() {
        let svc = ServiceJSON(name: "mystery", status: "booting",
                              pid: nil, exit_code: nil, user: nil, file: nil).toService()
        XCTAssertEqual(svc.status, .unknown)
    }

    func test_nilStatus_becomesStopped() {
        // nil is treated the same as "none"/"stopped" — a service with no status is stopped, not unknown
        let svc = ServiceJSON(name: "x", status: nil,
                              pid: nil, exit_code: nil, user: nil, file: nil).toService()
        XCTAssertEqual(svc.status, .stopped)
    }

    func test_noneStatus_becomesStopped() {
        let svc = ServiceJSON(name: "x", status: "none",
                              pid: nil, exit_code: nil, user: nil, file: nil).toService()
        XCTAssertEqual(svc.status, .stopped)
    }
}
