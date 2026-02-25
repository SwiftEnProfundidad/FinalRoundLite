import Foundation

struct ImportedAudioPreflightResult: Sendable, Equatable {
    var filename: String
    var contentType: String
    var fileSizeBytes: Int
}

enum ImportedAudioPreflightError: Error, Sendable, Equatable {
    case notAFile
    case unsupportedFileType(String)
    case emptyFile
    case fileTooLarge(fileSizeBytes: Int, maxBytes: Int)
    case unreadableFile
}

enum ImportedAudioPreflight {
    static let defaultMaxBytes = 25 * 1024 * 1024
    static let supportedExtensions = ["wav", "mp3", "mpga", "mpeg", "m4a", "mp4", "webm", "ogg"]

    static func validate(fileURL: URL, maxBytes: Int = defaultMaxBytes) throws -> ImportedAudioPreflightResult {
        guard fileURL.isFileURL else {
            throw ImportedAudioPreflightError.notAFile
        }

        let ext = fileURL.pathExtension.lowercased()
        guard let contentType = contentType(forExtension: ext) else {
            throw ImportedAudioPreflightError.unsupportedFileType(ext)
        }

        let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .nameKey])
        guard values.isRegularFile == true else {
            throw ImportedAudioPreflightError.notAFile
        }
        guard let fileSize = values.fileSize else {
            throw ImportedAudioPreflightError.unreadableFile
        }
        guard fileSize > 0 else {
            throw ImportedAudioPreflightError.emptyFile
        }
        guard fileSize <= maxBytes else {
            throw ImportedAudioPreflightError.fileTooLarge(fileSizeBytes: fileSize, maxBytes: maxBytes)
        }

        let filename = values.name ?? fileURL.lastPathComponent
        return ImportedAudioPreflightResult(
            filename: filename.isEmpty ? "audio" : filename,
            contentType: contentType,
            fileSizeBytes: fileSize
        )
    }

    private static func contentType(forExtension ext: String) -> String? {
        switch ext {
        case "wav":
            return "audio/wav"
        case "mp3", "mpeg", "mpga":
            return "audio/mpeg"
        case "m4a":
            return "audio/m4a"
        case "mp4":
            return "audio/mp4"
        case "webm":
            return "audio/webm"
        case "ogg":
            return "audio/ogg"
        default:
            return nil
        }
    }
}

enum ImportedAudioErrorPresenter {
    static func message(for error: Error) -> String {
        if let preflightError = error as? ImportedAudioPreflightError {
            return message(for: preflightError)
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return "Timeout al analizar el audio. Reintenta con una conexion estable."
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "No hay conexion de red para analizar el audio importado."
            default:
                return "Error de red al analizar el audio importado."
            }
        }

        if let clientError = error as? OpenAIClient.ClientError {
            switch clientError {
            case .missingOutputText:
                return "OpenAI no devolvio transcripcion para este audio."
            case .invalidResponse:
                return "OpenAI devolvio una respuesta invalida para el audio importado."
            case .invalidURL:
                return "Configuracion de endpoint invalida para transcripcion."
            case let .apiError(message):
                return "OpenAI rechazo la solicitud: \(message)"
            }
        }

        if let cocoaError = error as? CocoaError,
           [.fileReadNoSuchFile, .fileReadCorruptFile, .fileReadNoPermission].contains(cocoaError.code) {
            return "No se pudo leer el archivo de audio seleccionado."
        }

        return "No se pudo analizar el audio importado. Intenta con otro archivo."
    }

    private static func message(for error: ImportedAudioPreflightError) -> String {
        switch error {
        case .notAFile:
            return "Selecciona un archivo de audio valido."
        case .unsupportedFileType:
            let supported = ImportedAudioPreflight.supportedExtensions.joined(separator: ", ")
            return "Formato no soportado. Usa uno de estos: \(supported)."
        case .emptyFile:
            return "El archivo seleccionado esta vacio."
        case let .fileTooLarge(_, maxBytes):
            let maxMB = max(1, maxBytes / (1024 * 1024))
            return "El archivo supera el tamano maximo permitido de \(maxMB) MB."
        case .unreadableFile:
            return "No se pudo leer metadata del archivo seleccionado."
        }
    }
}
