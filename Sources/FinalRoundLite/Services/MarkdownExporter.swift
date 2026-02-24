import Foundation

enum MarkdownExporter {
    static func export(context: ContextCard, transcript: String, suggestion: CoachSuggestion) -> String {
        var lines: [String] = []

        lines.append("# FinalRound Lite Session")
        lines.append("")
        lines.append("## Context Card")
        lines.append("")
        lines.append("- Problema: \(context.problem)")
        lines.append("- Usuarios: \(context.users)")
        lines.append("- Escala: \(context.scale)")
        lines.append("- Datos: \(context.data)")
        lines.append("- SLOs: \(context.slos)")
        lines.append("- Restricciones: \(context.constraints)")
        lines.append("- Stack preferido: \(context.preferredStack)")
        lines.append("")
        lines.append("## Coach Suggestion")
        lines.append("")
        if !suggestion.currentQuestion.isEmpty {
            lines.append("**Pregunta actual:** \(suggestion.currentQuestion)")
            lines.append("")
        }
        if !suggestion.shortScript.isEmpty {
            lines.append("**Guion corto:**")
            lines.append("")
            lines.append(suggestion.shortScript)
            lines.append("")
        }
        if !suggestion.clarifyingQuestions.isEmpty {
            lines.append("**Clarificaciones:**")
            for q in suggestion.clarifyingQuestions { lines.append("- \(q)") }
            lines.append("")
        }
        if !suggestion.tradeoffs.isEmpty {
            lines.append("**Tradeoffs:**")
            for t in suggestion.tradeoffs { lines.append("- \(t)") }
            lines.append("")
        }
        if !suggestion.nextSteps.isEmpty {
            lines.append("**Siguientes pasos:**")
            for s in suggestion.nextSteps { lines.append("- \(s)") }
            lines.append("")
        }
        lines.append("## Transcript")
        lines.append("")
        lines.append(transcript.isEmpty ? "…" : transcript)

        return lines.joined(separator: "\n")
    }
}

