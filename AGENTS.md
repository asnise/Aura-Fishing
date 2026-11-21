# Agent instructions (Antigravity / any coding agent)

1. Read `docs/HANDOFF_ANTIGRAVITY.md` first — current state, hard rules, next tasks, tools, Figma node ids.
2. Then `CLAUDE.md` (project guide: layout, architecture rules, tooling, how to add content) and `docs/TASKS.md` (task list + Thai test steps; update it after every finished piece of work).
   How to work (written from real sessions): `docs/AGENT_PLAYBOOK.md` (request reading, priorities, task loop, tools, pitfalls) and `docs/AGENT_RUNBOOKS.md` (step-by-step runbook per kind of task: coding Part A, Figma design Part B). Pick the runbook that matches the user's message.
   Screens / windows: `docs/MENU_MANAGER.md` (which screens may be open together, how to register a new one, open hand-off tasks M1-M6).
3. Talk to the user in Thai; code and comments in English.
4. Fast Code-First Workflow:
   - For all gameplay logic, bug fixes, UI tweaks, and config changes: edit the code directly and run type check immediately. Finish in one swift turn (under 10s).
   - NEVER overwrite or rebuild Figma sections automatically. The user manually designs and tweaks Figma; never overwrite the user's manual design work unless explicitly asked to rebuild Figma.
   - Do NOT run heavy background image uploads or dump screenshots unless explicitly requested.
5. Type check must be clean after every change:
   `D:\tools\rojo\rojo.exe sourcemap default.project.json -o sourcemap.json` then
   `luau-lsp analyze --definitions=D:/tools/luau-defs/globalTypes.d.luau --sourcemap=sourcemap.json src`
6. Strict Character Rule: NEVER use "✓", "•", or emojis anywhere in UI text, code, or Figma design elements.
7. Currency & Rates: Pearls display as standard integers without decimals (`Format.Number`). Idle income rates display per second ("+X/s", never "/min").
8. Figma art and UI: Use only existing Aura Fishing artwork and icons from the project. Never generate, draw, or invent new image art, including temporary art. Inspect the relevant existing Figma screen before designing. Reuse its UI components, layout conventions, and Cozy Lake visual system. If an asset is missing, leave the slot empty or reuse an existing project placeholder.
9. Native UI backgrounds: Do not add black overlays or darkening backdrops to game UI unless the user explicitly changes this rule. Use a transparent input shield when a modal needs to block interaction with the UI behind it.
