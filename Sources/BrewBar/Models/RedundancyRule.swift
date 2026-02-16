import Foundation

struct RedundancyRule: Sendable {
    let toolName: String
    let description: String
    let icon: String
    let patterns: [Pattern]

    enum Pattern: Sendable {
        case prefix(String)
        case exact(String)

        func matches(_ name: String) -> Bool {
            switch self {
            case .prefix(let p): name.hasPrefix(p)
            case .exact(let e): name == e
            }
        }
    }
}

struct RedundantPackage: Identifiable, Sendable {
    var id: String { formula.name }
    let formula: Formula
    let rule: RedundancyRule
    let dependents: [String]
}

extension RedundancyRule {
    static let builtInRules: [RedundancyRule] = [
        // Python ecosystem
        RedundancyRule(
            toolName: "uv",
            description: "UV manages Python, packages & virtual environments",
            icon: "bolt.fill",
            patterns: [
                .prefix("python@"), .exact("pip"), .exact("pipx"),
                .exact("virtualenv"), .exact("poetry"), .exact("pipenv"),
                .exact("setuptools"),
            ]
        ),
        RedundancyRule(
            toolName: "pyenv",
            description: "pyenv manages Python versions",
            icon: "arrow.triangle.branch",
            patterns: [.prefix("python@")]
        ),

        // JavaScript/Node ecosystem
        RedundancyRule(
            toolName: "bun",
            description: "Bun replaces Node.js runtime & package managers",
            icon: "hare.fill",
            patterns: [
                .prefix("node@"), .exact("node"),
                .exact("pnpm"), .exact("yarn"), .exact("npm"),
            ]
        ),
        RedundancyRule(
            toolName: "fnm",
            description: "fnm manages Node.js versions",
            icon: "arrow.triangle.branch",
            patterns: [.prefix("node@"), .exact("node"), .exact("nvm")]
        ),
        RedundancyRule(
            toolName: "volta",
            description: "Volta manages Node.js & package manager versions",
            icon: "bolt.circle",
            patterns: [
                .prefix("node@"), .exact("node"),
                .exact("pnpm"), .exact("yarn"), .exact("npm"),
            ]
        ),
        RedundancyRule(
            toolName: "nvm",
            description: "nvm manages Node.js versions",
            icon: "arrow.triangle.branch",
            patterns: [.prefix("node@"), .exact("node")]
        ),

        // Ruby ecosystem
        RedundancyRule(
            toolName: "rbenv",
            description: "rbenv manages Ruby versions",
            icon: "arrow.triangle.branch",
            patterns: [.prefix("ruby@")]
        ),
        RedundancyRule(
            toolName: "chruby",
            description: "chruby manages Ruby versions",
            icon: "arrow.triangle.branch",
            patterns: [.prefix("ruby@")]
        ),

        // Rust ecosystem
        RedundancyRule(
            toolName: "rustup",
            description: "rustup manages Rust toolchains",
            icon: "gearshape.2",
            patterns: [.exact("rust")]
        ),

        // Go ecosystem
        RedundancyRule(
            toolName: "goenv",
            description: "goenv manages Go versions",
            icon: "arrow.triangle.branch",
            patterns: [.prefix("go@")]
        ),

        // Java ecosystem
        RedundancyRule(
            toolName: "jenv",
            description: "jenv manages Java versions",
            icon: "arrow.triangle.branch",
            patterns: [.prefix("openjdk@"), .exact("openjdk")]
        ),

        // Polyglot version managers
        RedundancyRule(
            toolName: "mise",
            description: "mise manages runtime versions (polyglot)",
            icon: "square.stack.3d.up",
            patterns: [
                .prefix("python@"), .prefix("node@"), .exact("node"),
                .prefix("ruby@"), .prefix("go@"), .prefix("openjdk@"),
                .exact("openjdk"),
                .exact("pyenv"), .exact("rbenv"), .exact("nodenv"),
                .exact("goenv"), .exact("jenv"), .exact("fnm"), .exact("nvm"),
            ]
        ),
    ]
}

func detectRedundancies(in formulae: [Formula]) -> [RedundantPackage] {
    let installedNames = Set(formulae.map(\.name))

    // Build reverse dependency map from existing formula data
    var reverseDeps: [String: [String]] = [:]
    for formula in formulae {
        for dep in formula.dependencies {
            reverseDeps[dep, default: []].append(formula.name)
        }
    }

    // Track which formula has already been claimed by a rule (first matching rule wins)
    var seen: Set<String> = []
    var results: [RedundantPackage] = []

    for rule in RedundancyRule.builtInRules {
        guard installedNames.contains(rule.toolName) else { continue }

        for formula in formulae {
            guard formula.name != rule.toolName else { continue }
            guard !seen.contains(formula.name) else { continue }

            if rule.patterns.contains(where: { $0.matches(formula.name) }) {
                seen.insert(formula.name)
                results.append(RedundantPackage(
                    formula: formula,
                    rule: rule,
                    dependents: reverseDeps[formula.name, default: []]
                ))
            }
        }
    }

    return results
}
