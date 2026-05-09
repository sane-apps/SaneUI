import Foundation

public enum SaneAppStorageError: LocalizedError, Equatable {
    case missingBaseDirectory(FileManager.SearchPathDirectory)

    public var errorDescription: String? {
        switch self {
        case .missingBaseDirectory(let directory):
            "macOS did not return a writable base directory for \(directory)."
        }
    }
}

public enum SaneAppStorage {
    public static func applicationSupportDirectory(
        appName: String,
        fileManager: FileManager = .default
    ) throws -> URL {
        try directory(
            base: .applicationSupportDirectory,
            appName: appName,
            fileManager: fileManager
        )
    }

    public static func cachesDirectory(
        appName: String,
        fileManager: FileManager = .default
    ) throws -> URL {
        try directory(
            base: .cachesDirectory,
            appName: appName,
            fileManager: fileManager
        )
    }

    public static func logsDirectory(
        appName: String,
        fileManager: FileManager = .default
    ) throws -> URL {
        guard let libraryDirectory = fileManager.urls(
            for: .libraryDirectory,
            in: .userDomainMask
        ).first else {
            throw SaneAppStorageError.missingBaseDirectory(.libraryDirectory)
        }

        let directory = libraryDirectory
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent(appName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func directory(
        base: FileManager.SearchPathDirectory,
        appName: String,
        fileManager: FileManager
    ) throws -> URL {
        guard let baseURL = fileManager.urls(for: base, in: .userDomainMask).first else {
            throw SaneAppStorageError.missingBaseDirectory(base)
        }

        let directory = baseURL.appendingPathComponent(appName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
