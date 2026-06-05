/**
 * SkyNetCMS global tool: get_current_page
 *
 * Returns the page the user is currently viewing in the website preview iframe
 * (URL path, query string, page title, draft/live mode) AND any elements the
 * user has visually selected in the preview (`selectedElements`: a labeled set
 * of { label, selector, text, tag }). The dashboard pushes this state to nginx
 * (POST /sn_admin/page-context); this tool reads it back from the loopback-only
 * endpoint.
 *
 * Use this before making edits scoped to a specific page or route so you edit
 * the correct source file under src/, and whenever the user refers to selected
 * elements ("this", "these", "#1"). The user can navigate or change the
 * selection between messages, so the result can change at any time — call it
 * fresh whenever you need it (once per request is enough), never reuse an older
 * value.
 *
 * NOTE: Defined as a plain tool object (no `@opencode-ai/plugin` import). The
 * `tool()` helper triggers a background npm install of a version-pinned
 * `@opencode-ai/plugin` that is not published for the SkyNetCMS fork, which
 * fails and breaks the whole tool registry. A plain object avoids that.
 */
export default {
  description:
    "Get the page the user is currently viewing in the website preview " +
    "(URL path, query string, page title, draft/live mode) and any elements " +
    "they have visually selected (selectedElements: a labeled set of " +
    "{ label, selector, text, tag }). The user may navigate or change the " +
    "selection between messages, so this can change at any time — call it fresh " +
    "whenever you need the current page or selection rather than relying on a " +
    "value from an earlier message. Calling it once per request is sufficient. " +
    "Use it before making edits scoped to a specific page/route, and whenever " +
    "the user refers to selected elements (\"this\", \"these\", \"#1\").",
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
