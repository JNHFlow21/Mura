import Foundation

public struct WorkspaceRetentionPolicy: Equatable, Sendable {
    public var maxWallpaperRenders: Int
    public var maxPreviewRenders: Int
    public var maxBoardSnapshots: Int
    public var maxWallpaperSnapshots: Int
    public var maxAuditLogBytes: Int
    public var keepAuditLogTailBytes: Int

    public init(
        maxWallpaperRenders: Int = 12,
        maxPreviewRenders: Int = 2,
        maxBoardSnapshots: Int = 20,
        maxWallpaperSnapshots: Int = 20,
        maxAuditLogBytes: Int = 2 * 1024 * 1024,
        keepAuditLogTailBytes: Int = 512 * 1024
    ) {
        self.maxWallpaperRenders = max(1, maxWallpaperRenders)
        self.maxPreviewRenders = max(0, maxPreviewRenders)
        self.maxBoardSnapshots = max(1, maxBoardSnapshots)
        self.maxWallpaperSnapshots = max(1, maxWallpaperSnapshots)
        self.maxAuditLogBytes = max(1024, maxAuditLogBytes)
        self.keepAuditLogTailBytes = min(max(1024, keepAuditLogTailBytes), self.maxAuditLogBytes)
    }

    public static let `default` = WorkspaceRetentionPolicy()
}

public struct WorkspaceCleanupResult: Equatable, Sendable {
    public var deletedFiles: Int
    public var reclaimedBytes: Int64

    public init(deletedFiles: Int = 0, reclaimedBytes: Int64 = 0) {
        self.deletedFiles = deletedFiles
        self.reclaimedBytes = reclaimedBytes
    }

    public static var empty: WorkspaceCleanupResult { WorkspaceCleanupResult() }

    public mutating func merge(_ other: WorkspaceCleanupResult) {
        deletedFiles += other.deletedFiles
        reclaimedBytes += other.reclaimedBytes
    }
}

public struct WorkspaceMaintenance {
    public let layout: WorkspaceLayout
    public let fileManager: FileManager

    public init(layout: WorkspaceLayout, fileManager: FileManager = .default) {
        self.layout = layout
        self.fileManager = fileManager
    }

    @discardableResult
    public func prune(
        policy: WorkspaceRetentionPolicy = .default,
        additionalProtectedURLs: Set<URL> = []
    ) throws -> WorkspaceCleanupResult {
        var result = WorkspaceCleanupResult.empty
        let protected = normalizedProtectedURLs(additionalProtectedURLs)

        result.merge(try pruneDirectory(
            layout.rendersDirectory,
            keepNewest: policy.maxWallpaperRenders,
            protected: protected
        ) { url in
            url.pathExtension.lowercased() == "png"
                && url.lastPathComponent.hasPrefix("wallpaper-")
        })

        result.merge(try pruneDirectory(
            layout.previewsDirectory,
            keepNewest: policy.maxPreviewRenders,
            protected: protected
        ) { url in
            url.pathExtension.lowercased() == "png"
                && url.lastPathComponent != "app-preview.png"
        })

        result.merge(try pruneDirectory(
            layout.boardSnapshotsDirectory,
            keepNewest: policy.maxBoardSnapshots,
            protected: protected
        ) { url in
            url.pathExtension.lowercased() == "json"
        })

        result.merge(try pruneDirectory(
            layout.wallpaperSnapshotsDirectory,
            keepNewest: policy.maxWallpaperSnapshots,
            protected: protected
        ) { url in
            url.pathExtension.lowercased() == "json"
        })

        result.merge(try trimAuditLogIfNeeded(
            maxBytes: policy.maxAuditLogBytes,
            keepTailBytes: policy.keepAuditLogTailBytes
        ))

        return result
    }

    private func normalizedProtectedURLs(_ additional: Set<URL>) -> Set<URL> {
        var protected = Set(additional.map { $0.standardizedFileURL })
        protected.insert(layout.latestRenderURL.standardizedFileURL)
        protected.insert(layout.activeBoardURL.standardizedFileURL)
        protected.insert(layout.preferencesURL.standardizedFileURL)
        return protected
    }

    private func pruneDirectory(
        _ directory: URL,
        keepNewest: Int,
        protected: Set<URL>,
        matching predicate: (URL) -> Bool
    ) throws -> WorkspaceCleanupResult {
        guard fileManager.fileExists(atPath: directory.path) else { return .empty }

        let candidates = try fileManager
            .contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            .filter { url in
                predicate(url)
                    && !protected.contains(url.standardizedFileURL)
                    && ((try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? true)
            }
            .map { url -> CleanupCandidate in
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                return CleanupCandidate(
                    url: url,
                    modificationDate: values?.contentModificationDate ?? .distantPast,
                    size: Int64(values?.fileSize ?? 0)
                )
            }
            .sorted { lhs, rhs in
                if lhs.modificationDate == rhs.modificationDate {
                    return lhs.url.lastPathComponent > rhs.url.lastPathComponent
                }
                return lhs.modificationDate > rhs.modificationDate
            }

        guard candidates.count > keepNewest else { return .empty }

        var result = WorkspaceCleanupResult.empty
        for candidate in candidates.dropFirst(keepNewest) {
            try fileManager.removeItem(at: candidate.url)
            result.deletedFiles += 1
            result.reclaimedBytes += candidate.size
        }
        return result
    }

    private func trimAuditLogIfNeeded(maxBytes: Int, keepTailBytes: Int) throws -> WorkspaceCleanupResult {
        let url = layout.auditLogURL
        guard fileManager.fileExists(atPath: url.path) else { return .empty }

        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = values?.fileSize ?? 0
        guard fileSize > maxBytes else { return .empty }

        let originalData = try Data(contentsOf: url)
        guard originalData.count > keepTailBytes else { return .empty }

        var tail = Data(originalData.suffix(keepTailBytes))
        if let firstNewline = tail.firstIndex(of: 0x0A) {
            tail.removeSubrange(tail.startIndex...firstNewline)
        }
        try tail.write(to: url, options: [.atomic])

        return WorkspaceCleanupResult(
            deletedFiles: 0,
            reclaimedBytes: Int64(originalData.count - tail.count)
        )
    }
}

private struct CleanupCandidate {
    var url: URL
    var modificationDate: Date
    var size: Int64
}
