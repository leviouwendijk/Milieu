/// Near matches between environment names, ranked:
/// case-only difference, reordered `_` segments, small edit distance,
/// then names containing every segment of a multi-segment query.
enum SymbolSimilarity {
    static func closest(
        to query: String,
        in candidates: Set<String>,
        limit: Int
    ) -> [String] {
        let wanted = query.uppercased()
        let wantedSegments = segments(wanted)
        let tolerance = wanted.count < 5 ? 1 : 2

        var ranked: [(rank: Int, distance: Int, name: String)] = []
        for name in candidates where name != query {
            let candidate = name.uppercased()
            if candidate == wanted {
                ranked.append((0, 0, name))
                continue
            }
            let candidateSegments = segments(candidate)
            if wantedSegments.count > 1, candidateSegments.sorted() == wantedSegments.sorted() {
                ranked.append((1, 0, name))
                continue
            }
            if abs(candidate.count - wanted.count) <= tolerance {
                let distance = editDistance(Array(wanted), Array(candidate))
                if distance <= tolerance {
                    ranked.append((2, distance, name))
                    continue
                }
            }
            if wantedSegments.count > 1, Set(wantedSegments).isSubset(of: candidateSegments) {
                ranked.append((3, candidate.count - wanted.count, name))
            }
        }

        return ranked
            .sorted { ($0.rank, $0.distance, $0.name) < ($1.rank, $1.distance, $1.name) }
            .prefix(limit)
            .map(\.name)
    }

    private static func segments(_ name: String) -> [String] {
        name.split(separator: "_").map(String.init)
    }

    /// Optimal string alignment: insertions, deletions, substitutions and
    /// adjacent transpositions each cost one.
    private static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var before = [Int](repeating: 0, count: b.count + 1)
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    current[j] = min(current[j], before[j - 2] + 1)
                }
            }
            (before, previous, current) = (previous, current, before)
        }
        return previous[b.count]
    }
}
