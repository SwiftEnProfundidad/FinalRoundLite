import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var apiKeyDraft = ""
    @State private var historySearchQuery = ""
    @State private var sessionPendingDeletion: SavedSessionRecord?
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        Form {
            Section("OpenAI y practica") {
                SecureField("OPENAI_API_KEY", text: $apiKeyDraft)
                    .textContentType(.password)

                HStack {
                    Button("Guardar") {
                        model.saveAPIKey(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines))
                        apiKeyDraft = ""
                    }
                    Button("Eliminar") { model.clearAPIKey() }
                }

                Text("La transcripcion solo se enviara si activas 'Enviar audio a OpenAI (transcripcion)' en el panel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(model.hasAPIKey ? "API key guardada en Keychain." : "Sin API key.")
                    .font(.caption)
                    .foregroundStyle(model.hasAPIKey ? .green : .orange)
            }

            Section("Modelos") {
                TextField("Modelo de transcripcion", text: $model.transcriptionModel)
                TextField("Modelo de coach", text: $model.coachModel)
                TextField("Idioma de transcripcion (ISO-639-1)", text: $model.languageCode)
            }

            Section("Panel de menubar") {
                Text("Cierra el panel con 'Cerrar panel' y termina la app con 'Salir'.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Tip: usa 'Vista compacta' en el panel para sesiones largas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Persistencia local") {
                Toggle("Guardar sesiones locales en disco (JSON)", isOn: $model.persistSessionsLocally)
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
                    Button("Actualizar") {
                        model.refreshSavedSessions()
                    }
                    Button("Borrar todo…", role: .destructive) {
                        isConfirmingDeleteAll = true
                    }
                    .disabled(model.savedSessions.isEmpty)
                    if model.isLoadingSavedSessions {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                TextField("Buscar sesiones (archivo o fecha)", text: $historySearchQuery)

                if model.savedSessions.isEmpty {
                    Text("No hay sesiones guardadas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if filteredSavedSessions.isEmpty {
                    Text("No hay coincidencias para \"\(historySearchQuery)\".")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredSavedSessions) { session in
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
                                Button("Borrar…", role: .destructive) {
                                    sessionPendingDeletion = session
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }

                    if historySearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, model.savedSessions.count > 8 {
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
        .confirmationDialog("Borrar sesion local", isPresented: isDeleteSessionDialogPresented, titleVisibility: .visible) {
            Button("Borrar", role: .destructive) {
                guard let sessionPendingDeletion else { return }
                model.deleteSavedSession(sessionPendingDeletion)
                self.sessionPendingDeletion = nil
            }
            Button("Cancelar", role: .cancel) {
                sessionPendingDeletion = nil
            }
        } message: {
            if let sessionPendingDeletion {
                Text("Se borrara \(sessionPendingDeletion.jsonURL.lastPathComponent).")
            }
        }
        .confirmationDialog("Borrar todo el historial local", isPresented: $isConfirmingDeleteAll, titleVisibility: .visible) {
            Button("Borrar todo", role: .destructive) {
                model.deleteAllSavedSessions()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta accion elimina todos los JSON/Markdown guardados en disco.")
        }
    }

    private var filteredSavedSessions: [SavedSessionRecord] {
        model.filteredSavedSessions(matching: historySearchQuery, limit: 8)
    }

    private var isDeleteSessionDialogPresented: Binding<Bool> {
        Binding(
            get: { sessionPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    sessionPendingDeletion = nil
                }
            }
        )
    }
}
