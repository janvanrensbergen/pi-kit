// RTK OMP extension — rewrites bash commands to rtk equivalents before execution.
// Delegates rewrite rules to `rtk rewrite`.

const REWRITE_TIMEOUT_MS = 2000;
const MIN_SUPPORTED_RTK_MINOR = 23;

function parseSemver(raw) {
  const match = raw.trim().match(/(\d+)\.(\d+)\.(\d+)/);
  if (!match) return null;
  return [Number.parseInt(match[1], 10), Number.parseInt(match[2], 10), Number.parseInt(match[3], 10)];
}

async function rewriteCommand(pi, command, signal) {
  const result = await pi.exec("rtk", ["rewrite", command], {
    timeout: REWRITE_TIMEOUT_MS,
    signal,
  });

  if (result.killed) return null;
  if (result.code !== 0 && result.code !== 3) return null;
  return result.stdout.trim() || null;
}

export default async function rtkHook(pi) {
  const version = await pi.exec("rtk", ["--version"], { timeout: REWRITE_TIMEOUT_MS });
  if (version.code !== 0) {
    console.warn("[rtk] rtk binary not found in PATH — extension disabled");
    return;
  }

  const parsed = parseSemver(version.stdout.replace(/^rtk\s+/, ""));
  if (parsed) {
    const [major, minor] = parsed;
    if (major === 0 && minor < MIN_SUPPORTED_RTK_MINOR) {
      console.warn(`[rtk] ${version.stdout.trim()} is too old (need >= 0.23.0) — extension disabled`);
      return;
    }
  }

  pi.on("tool_call", async (event, ctx) => {
    try {
      if (event.toolName !== "bash") return;

      const command = event.input?.command;
      if (typeof command !== "string" || command.trim() === "") return;
      if (command.startsWith("rtk ")) return;
      if (process.env.RTK_DISABLED === "1") return;

      const rewritten = await rewriteCommand(pi, command, ctx.signal);
      if (!rewritten || rewritten === command) return;

      return {
        input: {
          ...event.input,
          command: rewritten,
        },
      };
    } catch (err) {
      console.warn("[rtk] unexpected error in tool_call handler; passing through command", err);
      return;
    }
  });
}
