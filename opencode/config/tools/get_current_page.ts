/**
 * SkyNetCMS global tool: get_current_page
 *
 * Returns the page the user is currently viewing in the website preview iframe
 * (URL path, query string, page title, and draft/live mode). The dashboard
 * pushes this state to nginx (POST /sn_admin/page-context); this tool reads it
 * back from the loopback-only endpoint.
 *
 * Use this before making edits scoped to a specific page or route so you edit
 * the correct source file under src/.
 *
 * NOTE: Defined as a plain tool object (no `@opencode-ai/plugin` import). The
 * `tool()` helper triggers a background npm install of a version-pinned
 * `@opencode-ai/plugin` that is not published for the SkyNetCMS fork, which
 * fails and breaks the whole tool registry. A plain object avoids that.
 */
export default {
  description:
    "Get the page the user is currently viewing in the website preview " +
    "(URL path, query string, page title, and draft/live mode). Call this " +
    "before making edits scoped to a specific page or route to determine " +
    "which source file under src/ to edit.",
  args: {},
  async execute() {
    try {
      const res = await fetch("http://127.0.0.1/sn_admin/page-context-read")
      if (!res.ok) {
        return `Page context unavailable (HTTP ${res.status}). The user may not have the preview open yet.`
      }
      const ctx = await res.json()
      if (!ctx || (!ctx.path && !ctx.title)) {
        return "No page context recorded yet. The user may not have opened or navigated the preview."
      }
      return JSON.stringify(ctx)
    } catch (e) {
      return `Page context unavailable: ${String(e)}`
    }
  },
}
