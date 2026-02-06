# Site Development

Static site built with Vite, served by nginx.

## Structure

- `src/` - source files (edit here)
- `dist/` - build output (never edit)

## Draft/Publish Workflow

This site uses a **draft/publish model** to protect users from seeing unfinished changes.

### How It Works

1. **Draft Mode**: You work in a git worktree (separate branch), changes are previewed at `/sn_admin/dev/`
2. **Live Site**: The main branch serves the public site at `/`
3. **Publish**: When user approves, merge draft to main and rebuild

### Starting a New Session

When starting work, **suggest creating a new worktree** for isolation:
- OpenCode's session UI has a worktree selector
- "Create new worktree" creates an isolated branch (e.g., `opencode/brave-falcon`)
- User can choose to work on main directly (their choice, but riskier)

### During Development

- Make changes in your current worktree
- User can preview via `/sn_admin/dev/` (Dev toggle in dashboard)
- Commit frequently with meaningful messages
- **Do NOT** run `npm run build` in draft worktree (preview uses Vite dev server)

### Publishing Changes

When user says "publish", "go live", "make it live", or similar:

1. Create a backup tag of current main state:
   ```bash
   git tag -a "pre-publish-$(date +%Y%m%d-%H%M%S)" -m "State before publish"
   ```

2. Switch to main and merge the draft branch:
   ```bash
   git checkout main
   git merge <draft-branch> -m "Publish: <description of changes>"
   ```

3. Build the site:
   ```bash
   npm run build
   ```

4. Confirm success to user:
   - "Your changes are now live at /"
   - Mention the backup tag in case rollback is needed

### Rollback

When user wants to undo a publish or restore previous version:

1. List available restore points:
   ```bash
   git tag -l "pre-publish-*" --sort=-creatordate
   ```

2. Reset to the desired tag:
   ```bash
   git reset --hard <tag-name>
   npm run build
   ```

3. Confirm to user what was restored

### Working Directly on Main (Not Recommended)

If user insists on working directly on main:
- Warn them that changes go live immediately after build
- Still create pre-change tags for safety
- Run `npm run build` after each meaningful change (unlike worktree mode)
- Commit after successful build

## Technical Details

### Build Command

```bash
npm run build
```

Compiles `src/` to `dist/`. 

**When to build:**
- In worktree: Only during publish (after merging to main)
- On main directly: After each meaningful change (goes live immediately)

### Preview (Draft)

The dev server (`/sn_admin/dev/`) runs Vite with HMR in the active worktree.
- Starts automatically when accessed
- Stops after 5 minutes of inactivity
- Shows real-time changes without building

### Constraints

- Static only (no server-side code)
- Vite ecosystem
- Plain HTML/CSS/JS preferred; add dependencies only when clearly beneficial

## Design Priorities

1. Responsive design (mobile-first)
2. Modern, clean visuals
3. SEO (semantic HTML, meta tags)

## First Edit

Replace welcome page entirely when user requests real content.
