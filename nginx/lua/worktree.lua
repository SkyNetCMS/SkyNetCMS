-- ============================================
-- SkyNetCMS - Worktree Detection Module
-- ============================================
-- Detects and manages git worktrees for the dev server:
-- - Finds worktrees in OpenCode's data directory
-- - Returns most recently modified worktree
-- - Supports override via query parameter

local _M = {}

-- Configuration
-- OpenCode stores worktrees at: $XDG_DATA_HOME/opencode/worktree/<project-id>/
-- In the container, XDG_DATA_HOME is set to /data so worktrees are at /data/opencode/worktree/
-- This allows both OpenCode (root) and nginx (www-data) to access worktrees.
_M.OPENCODE_DATA_DIR = "/data/opencode"
_M.MAIN_WEBSITE_DIR = "/data/website"

-- Get the project ID from the main website directory
-- OpenCode uses a hash of the directory path as project ID
local function get_project_id()
    -- OpenCode generates project ID as a hash - we need to find it by scanning
    -- the worktree directory for any project that has worktrees
    local worktree_base = _M.OPENCODE_DATA_DIR .. "/worktree"
    
    -- Check if worktree directory exists
    local handle = io.popen("ls -1 " .. worktree_base .. " 2>/dev/null")
    if not handle then
        return nil
    end
    
    local projects = {}
    for line in handle:lines() do
        if line and line ~= "" then
            table.insert(projects, line)
        end
    end
    handle:close()
    
    -- Return the first project with worktrees (typically only one in single-tenant)
    if #projects > 0 then
        return projects[1]
    end
    
    return nil
end

-- Get list of worktrees for the project
-- Returns table of {name, directory, mtime}
local function list_worktrees()
    local project_id = get_project_id()
    if not project_id then
        return {}
    end
    
    local worktree_dir = _M.OPENCODE_DATA_DIR .. "/worktree/" .. project_id
    
    -- List directories and get their modification times
    local cmd = string.format(
        "find %s -maxdepth 1 -mindepth 1 -type d -exec stat -c '%%Y %%n' {} \\; 2>/dev/null | sort -rn",
        worktree_dir
    )
    
    local handle = io.popen(cmd)
    if not handle then
        return {}
    end
    
    local worktrees = {}
    for line in handle:lines() do
        local mtime, path = line:match("^(%d+)%s+(.+)$")
        if mtime and path then
            local name = path:match("([^/]+)$")
            if name then
                table.insert(worktrees, {
                    name = name,
                    directory = path,
                    mtime = tonumber(mtime)
                })
            end
        end
    end
    handle:close()
    
    return worktrees
end

-- Find a worktree by name
-- Returns directory path or nil
function _M.find_worktree(name)
    if not name or name == "" then
        return nil
    end
    
    local worktrees = list_worktrees()
    for _, wt in ipairs(worktrees) do
        if wt.name == name then
            return wt.directory
        end
    end
    
    return nil
end

-- Get the most recently modified worktree
-- Returns {name, directory, mtime} or nil
function _M.get_most_recent()
    local worktrees = list_worktrees()
    
    if #worktrees == 0 then
        return nil
    end
    
    -- Already sorted by mtime descending
    return worktrees[1]
end

-- Get all worktrees
-- Returns table of {name, directory, mtime}
function _M.list_all()
    return list_worktrees()
end

-- Determine which directory the dev server should use
-- Priority:
-- 1. Query param override (?worktree=name)
-- 2. Most recently modified worktree
-- 3. Fallback to main website directory
function _M.get_dev_directory()
    -- Check for query param override
    local args = ngx.req.get_uri_args()
    local worktree_param = args["worktree"]
    
    if worktree_param and worktree_param ~= "" then
        local dir = _M.find_worktree(worktree_param)
        if dir then
            ngx.log(ngx.INFO, "worktree: Using override worktree '", worktree_param, "' at ", dir)
            return dir, worktree_param
        else
            ngx.log(ngx.WARN, "worktree: Requested worktree '", worktree_param, "' not found, using fallback")
        end
    end
    
    -- Try most recent worktree
    local recent = _M.get_most_recent()
    if recent then
        ngx.log(ngx.INFO, "worktree: Using most recent worktree '", recent.name, "' at ", recent.directory)
        return recent.directory, recent.name
    end
    
    -- Fallback to main website
    ngx.log(ngx.INFO, "worktree: No worktrees found, using main website at ", _M.MAIN_WEBSITE_DIR)
    return _M.MAIN_WEBSITE_DIR, nil
end

-- Check if a directory is a valid worktree (has node_modules, package.json, etc.)
function _M.is_valid_worktree(directory)
    if not directory then
        return false
    end
    
    -- Check for package.json
    local f = io.open(directory .. "/package.json", "r")
    if f then
        f:close()
        return true
    end
    
    return false
end

return _M
