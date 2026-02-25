import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var apiKeyDraft = ""

    var body: some View {
        Form {
            Section("OpenAI") {
                SecureField("OPENAI_API_KEY", text: $apiKeyDraft)
                    .textContentType(.password)

                HStack {
                    Button("Guardar") {
                        model.saveAPIKey(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines))
                        apiKeyDraft = ""
                    }
                    Button("Borrar") { model.clearAPIKey() }
                }

                Text("El audio se enviara a OpenAI solo si activas el toggle en el panel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(model.hasAPIKey ? "API key guardada en Keychain." : "Sin API key.")
                    .font(.caption)
                    .foregroundStyle(model.hasAPIKey ? .green : .orange)
            }

            Section("Modelos") {
                TextField("Transcription model", text: $model.transcriptionModel)
                TextField("Coach model", text: $model.coachModel)
                TextField("Language (ISO-639-1)", text: $model.languageCode)
            }

            Section("Persistencia local") {
                Toggle("Guardar sesiones en disco (JSON)", isOn: $model.persistSessionsLocally)
                Text("Desactivado por defecto. Si esta activo, se guarda un JSON por sesion en Application Support.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Stepper(value: $model.sessionRetentionLimit, in: 1...200) {
                    Text("Retencion maxima: \(model.sessionRetentionLimit) sesiones")
                }

                HStack(spacing: 8) {
                    Button("Elegir carpeta…") {
                        model.chooseSessionsDirectory()
                    }
                    Button("Usar carpeta por defecto") {
                        model.resetSessionsDirectoryToDefault()
                    }
                    .disabled(model.usesDefaultSessionsDirectory)
                    Button("Abrir carpeta") {
                        model.revealSessionsDirectoryInFinder()
                    }
                }
                .buttonStyle(.bordered)

                if model.usesDefaultSessionsDirectory {
                    Text("Carpeta actual: Application Support/FinalRoundLite/sessions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(model.customSessionsDirectoryPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section("Historial local") {
                HStack(spacing: 10) {
                    Button("Recargar") {
                        model.refreshSavedSessions()
                    }
                    if model.isLoadingSavedSessions {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if model.savedSessions.isEmpty {
                    Text("No hay sesiones guardadas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(model.savedSessions.prefix(8))) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.savedAt, format: .dateTime.year().month().day().hour().minute())
                                .font(.caption.bold())
                            Text(session.jsonURL.lastPathComponent)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)

                            HStack(spacing: 8) {
                                Button("Abrir JSON") {
                                    model.openSavedSessionJSON(session)
                                }
                                Button("Abrir Markdown") {
                                    model.openSavedSessionMarkdown(session)
                                }
                                .disabled(session.markdownURL == nil)
                                Button("Mostrar en Finder") {
                                    model.revealSavedSessionInFinder(session)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }

                    if model.savedSessions.count > 8 {
                        Text("Mostrando las 8 sesiones mas recientes.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Telemetria local") {
                Text("Sesiones procesadas: \(model.telemetrySessionCount)")
                Text(
                    "Tiempo promedio de procesamiento: \(model.telemetryAverageProcessingSeconds, format: .number.precision(.fractionLength(2))) s"
                )
                .foregroundStyle(.secondary)
            }

            Section("Context Card (System Design)") {
                TextField("Problema", text: $model.contextCard.problem, axis: .vertical)
                TextField("Usuarios", text: $model.contextCard.users, axis: .vertical)
                TextField("Escala (QPS/DAU)", text: $model.contextCard.scale, axis: .vertical)
                TextField("Datos", text: $model.contextCard.data, axis: .vertical)
                TextField("SLOs", text: $model.contextCard.slos, axis: .vertical)
                TextField("Restricciones", text: $model.contextCard.constraints, axis: .vertical)
                TextField("Stack preferido", text: $model.contextCard.preferredStack, axis: .vertical)
            }
        }
        .padding(16)
        .frame(width: 560)
        .task {
            model.refreshSavedSessions()
        }
    }
}
