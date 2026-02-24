# AGENTS.md — Codex rules for this repository

## Skills: always enabled
- My GLOBAL skills live in: `~/.codex/skills/**`
- Reading from `~/.codex/skills/**` is ALWAYS allowed.
- Writing/modifying anything under `~/.codex/**` is NEVER allowed.

## Mandatory (every iteration)
Before taking any action:
1) Confirm workspace:
   - `pwd`
   - `git rev-parse --show-toplevel`
   - `git status`
2) Confirm you are not running from inside `~/.codex`.
3) Enumerate available skills (global + repo):
   - Prefer scanning skills directories for folders containing `SKILL.md`.
   - Keep an internal list of skill names.
4) Decide if one or more skills apply to the current user request.
   - If a skill applies, invoke it and follow its `SKILL.md` instructions.
   - If no skill applies, proceed normally.
5) Legacy automation checks:
   - Legacy gate/evidence checks are deprecated in this repository.
   - Do not block work on those checks.
6) Actualizar el estado real de refactor/estabilidad en el area de tracking de f actual (sin depender de artefactos de pilot0):
   - con el estado actual del proyecto, siguiendo el formato de ese documento.
   - cada vez que terminies una tarea la marcas como hecha con su emoji y marcas la siguiente que vas a hacer como en construccion, no es
  negociable

## Repo safety
- Make changes ONLY inside this repository.
- Avoid sweeping refactors unless explicitly requested.
- For destructive ops (delete/drop/apply/destroy), STOP and ask.

## Secrets
- Never print or log secrets (API keys, tokens, service role keys, credentials).
- If a secret is detected, report only file path + remediation (do not echo the value).

## Handoff protocol
When finishing any task, output:
- STATUS (DONE/BLOCKED)
- BRANCH
- FILES CHANGED
- COMMANDS RUN
- NEXT instruction

<!-- BEGIN CODEX SKILLS -->
## Codex Skills (local + vendorizado)

- Precedencia:
  - Manten la precedencia global ya definida en `AGENTS.md`.
  - Si no esta definida explicitamente, usa: `AGENTS.md > codex skills > prompts de fase`.
- Reoperativa:
  - Al inicio de cualquier fase, usa primero los archivos vendorizados en `docs/codex-skills/*.md` si existen.
  - Si no existen, intenta leer las rutas locales.
  - Aplica reglas de las skills siempre que no contradigan `AGENTS.md`.

- Skills:
  - `windsurf-rules-android`
    - Local: `/Users/juancarlosmerlosalbarracin/.codex/skills/public/windsurf-rules-android/SKILL.md`
    - Vendorizado: `docs/codex-skills/windsurf-rules-android.md`
  - `windsurf-rules-backend`
    - Local: `/Users/juancarlosmerlosalbarracin/.codex/skills/public/windsurf-rules-backend/SKILL.md`
    - Vendorizado: `docs/codex-skills/windsurf-rules-backend.md`
  - `windsurf-rules-frontend`
    - Local: `/Users/juancarlosmerlosalbarracin/.codex/skills/public/windsurf-rules-frontend/SKILL.md`
    - Vendorizado: `docs/codex-skills/windsurf-rules-frontend.md`
  - `windsurf-rules-ios`
    - Local: `/Users/juancarlosmerlosalbarracin/.codex/skills/public/windsurf-rules-ios/SKILL.md`
    - Vendorizado: `docs/codex-skills/windsurf-rules-ios.md`
  - `swift-concurrency`
    - Local: `/Users/juancarlosmerlosalbarracin/.codex/skills/swift-concurrency/SKILL.md`
    - Vendorizado: `docs/codex-skills/swift-concurrency.md`
  - `swiftui-expert-skill`
    - Local: `/Users/juancarlosmerlosalbarracin/.codex/skills/swiftui-expert-skill/SKILL.md`
    - Vendorizado: `docs/codex-skills/swiftui-expert-skill.md`

- Comando de sincronizacion: `./scripts/sync-codex-skills.sh`
<!-- END CODEX SKILLS -->

