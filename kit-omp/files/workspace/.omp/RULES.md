# Hard rules (apply to every agent, including subagents)

- Before reading or editing code in a subdirectory, search it and its parents up to the workspace root for
  `AGENTS.md` and read every one found. Nested files refine these rules for their directory.
- Never commit, push, create releases or pull requests, or change issue state unless the user explicitly asks.
- Never print, copy, or commit credentials, tokens, or secret values.
- Never bypass or weaken sandbox or network policy. Report a blocked request with the exact host and response.
- Never run destructive filesystem, Git, Docker, database, or infrastructure commands without confirmation.
- Use `ketch` through `bash` for external information, not `curl`.
- Preserve uncommitted changes you did not make. Edit only the files assigned to you and stage nothing unless told to.
- Do not expand scope beyond the task. Report skipped verification instead of implying it ran.
