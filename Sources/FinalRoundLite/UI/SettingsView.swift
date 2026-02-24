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
    }
}

