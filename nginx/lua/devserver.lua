-- ============================================
-- SkyNetCMS - Dev Server Management Module
-- ============================================
-- Manages on-demand Vite dev server lifecycle:
-- - Starts dev server when /sn_admin/dev/ is accessed
-- - Supports dynamic worktree directories
-- - Tracks activity for idle shutdown
-- - Auto-stops after 5 minutes of inactivity
-- - Restarts if worktree changes

local _M = {}

-- Configuration
_M.DEV_PORT = 5173
_M.PID_FILE = "/tmp/vite-dev.pid"
_M.DIR_FILE = "/tmp/vite-dev.dir"  -- Track which directory server is running in
_M.IDLE_TIMEOUT = 300  -- 5 minutes in seconds
_M.STARTUP_TIMEOUT = 30  -- Max seconds to wait for server to start
_M.WEBSITE_DIR = "/data/website"  -- Fallback directory

-- Get shared dictionary for state management
local function get_dict()
    return ngx.shared["dev_server"]
end

-- Check if a process with given PID is running
local function is_process_running(pid)
    if not pid then return false end
    local handle = io.popen("kill -0 " .. pid .. " 2>/dev/null && echo 'running'")
    if not handle then return false end
    local result = handle:read("*a")
    handle:close()
    return result:match("running") ~= nil
end

-- Check if dev server port is responding using TCP socket
local function is_port_ready()
    local sock = ngx.socket.tcp()
    sock:settimeout(1000)  -- 1 second timeout
    
    local ok, err = sock:connect("127.0.0.1", _M.DEV_PORT)
    if ok then
        sock:close()
        return true
    end
    return false
end

-- Read PID from file
local function read_pid()
    local file = io.open(_M.PID_FILE, "r")
    if not file then return nil end
    local pid = file:read("*n")
    file:close()
    return pid
end

-- Write PID to file
local function write_pid(pid)
    local file = io.open(_M.PID_FILE, "w")
    if not file then
        ngx.log(ngx.ERR, "devserver: Failed to write PID file")
        return false
    end
    file:write(tostring(pid))
    file:close()
    return true
end

-- Remove PID file
local function remove_pid()
    os.remove(_M.PID_FILE)
end

-- Read current directory from file
local function read_current_dir()
    local file = io.open(_M.DIR_FILE, "r")
    if not file then return nil end
    local dir = file:read("*l")
    file:close()
    return dir
end

-- Write current directory to file
local function write_current_dir(dir)
    local file = io.open(_M.DIR_FILE, "w")
    if not file then
        ngx.log(ngx.ERR, "devserver: Failed to write DIR file")
        return false
    end
    file:write(dir)
    file:close()
    return true
end

-- Remove directory file
local function remove_dir_file()
    os.remove(_M.DIR_FILE)
end

-- Get current dev server status
-- Returns: "stopped", "starting", "running"
function _M.get_status()
    local dict = get_dict()
    if not dict then
        ngx.log(ngx.ERR, "devserver: Shared dict 'dev_server' not found")
        return "stopped"
    end
    
    -- Check if we have a recorded PID
    local pid = read_pid()
    if not pid then
        dict:set("status", "stopped")
        return "stopped"
    end
    
    -- Check if process is actually running
    if not is_process_running(pid) then
        remove_pid()
        remove_dir_file()
        dict:set("status", "stopped")
        return "stopped"
    end
    
    -- Process is running, check if port is ready
    if is_port_ready() then
        dict:set("status", "running")
        return "running"
    end
    
    -- Process running but port not ready = starting
    return "starting"
end

-- Get the directory the dev server is currently running in
function _M.get_current_directory()
    return read_current_dir()
end

-- Check if we need to restart the server for a different directory
function _M.needs_restart(target_dir)
    local status = _M.get_status()
    if status == "stopped" then
        return false  -- Not running, no restart needed
    end
    
    local current_dir = read_current_dir()
    if not current_dir then
        return false  -- No record, assume OK
    end
    
    return current_dir ~= target_dir
end

-- Start the dev server in a specific directory
-- Returns: true if started (or already running), false on error
function _M.start_server(directory)
    directory = directory or _M.WEBSITE_DIR
    
    local status = _M.get_status()
    
    -- Check if we need to restart for a different directory
    if status == "running" and _M.needs_restart(directory) then
        ngx.log(ngx.INFO, "devserver: Restarting for different directory: ", directory)
        _M.stop_server()
        status = "stopped"
    end
    
    if status == "running" then
        ngx.log(ngx.INFO, "devserver: Already running in ", read_current_dir() or "unknown")
        return true
    end
    
    if status == "starting" then
        ngx.log(ngx.INFO, "devserver: Already starting")
        return true
    end
    
    local dict = get_dict()
    if dict then
        dict:set("status", "starting")
    end
    
    -- Start Vite with base path for our proxy location
    -- Using nohup and & to run in background, redirect output to log
    -- The nginx worker runs as www-data, but we need write access to node_modules
    -- so we use sudo to run the start-vite.sh wrapper as root
    local cmd = string.format(
        "nohup sudo /scripts/start-vite.sh %d /sn_admin/dev/ %s > /tmp/vite-dev.log 2>&1 & echo $!",
        _M.DEV_PORT,
        directory
    )
    
    ngx.log(ngx.INFO, "devserver: Starting with command: ", cmd)
    
    local handle = io.popen(cmd)
    if not handle then
        ngx.log(ngx.ERR, "devserver: Failed to execute start command")
        if dict then dict:set("status", "stopped") end
        return false
    end
    
    local pid_str = handle:read("*a")
    handle:close()
    
    local pid = tonumber(pid_str:match("%d+"))
    if not pid then
        ngx.log(ngx.ERR, "devserver: Failed to get PID from output: ", pid_str)
        if dict then dict:set("status", "stopped") end
        return false
    end
    
    ngx.log(ngx.INFO, "devserver: Started with PID ", pid, " in directory ", directory)
    write_pid(pid)
    write_current_dir(directory)
    
    -- Update activity timestamp
    _M.update_activity()
    
    return true
end

-- Wait for dev server to be ready
-- Returns: true if ready, false if timeout
function _M.wait_for_ready(timeout)
    timeout = timeout or _M.STARTUP_TIMEOUT
    local start_time = ngx.now()
    
    while (ngx.now() - start_time) < timeout do
        if is_port_ready() then
            local dict = get_dict()
            if dict then dict:set("status", "running") end
            ngx.log(ngx.INFO, "devserver: Ready after ", ngx.now() - start_time, " seconds")
            return true
        end
        
        -- Check if process died
        local pid = read_pid()
        if pid and not is_process_running(pid) then
            ngx.log(ngx.ERR, "devserver: Process died during startup")
            remove_pid()
            remove_dir_file()
            local dict = get_dict()
            if dict then dict:set("status", "stopped") end
            return false
        end
        
        ngx.sleep(0.5)
    end
    
    ngx.log(ngx.ERR, "devserver: Timeout waiting for server to be ready")
    return false
end

-- Update last activity timestamp
function _M.update_activity()
    local dict = get_dict()
    if dict then
        dict:set("last_activity", ngx.now())
    end
end

-- Get last activity timestamp
function _M.get_last_activity()
    local dict = get_dict()
    if dict then
        return dict:get("last_activity")
    end
    return nil
end

-- Stop the dev server
function _M.stop_server()
    local pid = read_pid()
    if not pid then
        ngx.log(ngx.INFO, "devserver: No PID file, server not running")
        return true
    end
    
    if not is_process_running(pid) then
        ngx.log(ngx.INFO, "devserver: Process already stopped")
        remove_pid()
        remove_dir_file()
        return true
    end
    
    ngx.log(ngx.INFO, "devserver: Stopping server with PID ", pid)
    
    -- Send SIGTERM to the process group (kills npm and vite)
    os.execute("kill -TERM -" .. pid .. " 2>/dev/null || kill -TERM " .. pid .. " 2>/dev/null")
    
    -- Wait a moment for graceful shutdown
    ngx.sleep(1)
    
    -- Force kill if still running
    if is_process_running(pid) then
        ngx.log(ngx.WARN, "devserver: Force killing PID ", pid)
        os.execute("kill -9 -" .. pid .. " 2>/dev/null || kill -9 " .. pid .. " 2>/dev/null")
    end
    
    remove_pid()
    remove_dir_file()
    
    local dict = get_dict()
    if dict then
        dict:set("status", "stopped")
    end
    
    return true
end

-- Check if server should be stopped due to idle timeout
-- Called periodically by timer
function _M.stop_if_idle()
    local status = _M.get_status()
    if status == "stopped" then
        return
    end
    
    local dict = get_dict()
    if not dict then return end
    
    local last_activity = dict:get("last_activity")
    if not last_activity then
        -- No activity recorded, stop the server
        ngx.log(ngx.INFO, "devserver: No activity recorded, stopping")
        _M.stop_server()
        return
    end
    
    local idle_time = ngx.now() - last_activity
    if idle_time > _M.IDLE_TIMEOUT then
        ngx.log(ngx.INFO, "devserver: Idle for ", idle_time, " seconds, stopping")
        _M.stop_server()
    end
end

return _M
