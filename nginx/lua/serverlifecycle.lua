-- ============================================
-- SkyNetCMS - Generic Server Lifecycle Module
-- ============================================
-- Shared on-demand process lifecycle controller used by both the Vite dev
-- server (devserver.lua) and the OpenCode backend (ocserver.lua).
--
-- Responsibilities:
-- - Lazy start a background process via a sudo wrapper script
-- - Track PID and working directory in /tmp files
-- - Report status (stopped/starting/running) via TCP readiness probe
-- - Auto-stop after an idle timeout, with an optional "is_busy" guard
--
-- Process management notes:
-- - The nginx worker runs as www-data, but managed processes run as root.
--   `kill -0` returns a false "not running" (EPERM) when www-data probes a
--   root-owned PID, so liveness is checked via /proc/<pid>/status instead.
-- - www-data cannot signal a root process directly, so stops go through a
--   sudo wrapper script (config.stop_script).
--
-- Usage:
--   local lifecycle = require("serverlifecycle")
--   local svc = lifecycle.new({
--       name = "devserver",
--       port = 5173,
--       pid_file = "/tmp/vite-dev.pid",
--       dir_file = "/tmp/vite-dev.dir",
--       dict_name = "dev_server",
--       log_file = "/tmp/vite-dev.log",
--       default_dir = "/data/website",
--       idle_timeout = 300,
--       startup_timeout = 30,
--       start_cmd = function(directory, cfg)
--           return string.format(
--               "nohup sudo /scripts/start-vite.sh %d /sn_admin/dev/ %s > %s 2>&1 & echo $!",
--               cfg.port, directory, cfg.log_file)
--       end,
--       stop_script = "/scripts/stop-vite.sh",
--       is_busy = nil,  -- optional function() -> boolean
--   })

local _M = {}

-- Read PID from file
local function read_pid(cfg)
    local file = io.open(cfg.pid_file, "r")
    if not file then return nil end
    local pid = file:read("*n")
    file:close()
    return pid
end

-- Write PID to file
local function write_pid(cfg, pid)
    local file = io.open(cfg.pid_file, "w")
    if not file then
        ngx.log(ngx.ERR, cfg.name, ": Failed to write PID file ", cfg.pid_file)
        return false
    end
    file:write(tostring(pid))
    file:close()
    return true
end

-- Remove PID file
local function remove_pid(cfg)
    os.remove(cfg.pid_file)
end

-- Read current working directory from file
local function read_current_dir(cfg)
    local file = io.open(cfg.dir_file, "r")
    if not file then return nil end
    local dir = file:read("*l")
    file:close()
    return dir
end

-- Write current working directory to file
local function write_current_dir(cfg, dir)
    local file = io.open(cfg.dir_file, "w")
    if not file then
        ngx.log(ngx.ERR, cfg.name, ": Failed to write DIR file ", cfg.dir_file)
        return false
    end
    file:write(dir)
    file:close()
    return true
end

-- Remove directory file
local function remove_dir_file(cfg)
    os.remove(cfg.dir_file)
end

-- Check if a process with given PID is running.
-- Uses /proc/<pid>/status rather than `kill -0`: the nginx worker (www-data)
-- gets EPERM (false "not running") when probing a root-owned PID with kill -0.
local function is_process_running(pid)
    if not pid then return false end
    local file = io.open("/proc/" .. tostring(pid) .. "/status", "r")
    if not file then
        return false
    end
    file:close()
    return true
end

-- Build a controller instance bound to the given config table.
function _M.new(config)
    assert(config, "serverlifecycle.new: config table required")
    assert(config.name, "serverlifecycle.new: config.name required")
    assert(config.port, "serverlifecycle.new: config.port required")
    assert(config.pid_file, "serverlifecycle.new: config.pid_file required")
    assert(config.dir_file, "serverlifecycle.new: config.dir_file required")
    assert(config.dict_name, "serverlifecycle.new: config.dict_name required")
    assert(config.start_cmd, "serverlifecycle.new: config.start_cmd required")
    assert(config.stop_script, "serverlifecycle.new: config.stop_script required")

    config.idle_timeout = config.idle_timeout or 300
    config.startup_timeout = config.startup_timeout or 30
    config.default_dir = config.default_dir or "/data/website"

    local svc = {}
    local cfg = config

    -- Expose select config values for callers/JSON status
    svc.PORT = cfg.port
    svc.IDLE_TIMEOUT = cfg.idle_timeout
    svc.STARTUP_TIMEOUT = cfg.startup_timeout

    local function get_dict()
        local dict = ngx.shared[cfg.dict_name]
        if not dict then
            ngx.log(ngx.ERR, cfg.name, ": Shared dict '", cfg.dict_name, "' not found")
        end
        return dict
    end

    -- Check if the service port is accepting TCP connections
    local function is_port_ready()
        local sock = ngx.socket.tcp()
        sock:settimeout(1000)
        local ok = sock:connect("127.0.0.1", cfg.port)
        if ok then
            sock:close()
            return true
        end
        return false
    end

    -- Get current status: "stopped", "starting", "running"
    function svc.get_status()
        local dict = get_dict()

        local pid = read_pid(cfg)
        if not pid then
            if dict then dict:set("status", "stopped") end
            return "stopped"
        end

        if not is_process_running(pid) then
            remove_pid(cfg)
            remove_dir_file(cfg)
            if dict then dict:set("status", "stopped") end
            return "stopped"
        end

        if is_port_ready() then
            if dict then dict:set("status", "running") end
            return "running"
        end

        -- Process alive but port not ready yet
        return "starting"
    end

    function svc.get_current_directory()
        return read_current_dir(cfg)
    end

    -- Does the running server need a restart to serve a different directory?
    function svc.needs_restart(target_dir)
        local status = svc.get_status()
        if status == "stopped" then
            return false
        end
        local current_dir = read_current_dir(cfg)
        if not current_dir then
            return false
        end
        return current_dir ~= target_dir
    end

    -- Start the server in a specific directory.
    -- Returns true if started (or already running/starting), false on error.
    function svc.start_server(directory)
        directory = directory or cfg.default_dir

        local status = svc.get_status()

        if status == "running" and svc.needs_restart(directory) then
            ngx.log(ngx.INFO, cfg.name, ": Restarting for different directory: ", directory)
            svc.stop_server()
            status = "stopped"
        end

        if status == "running" then
            ngx.log(ngx.INFO, cfg.name, ": Already running in ", read_current_dir(cfg) or "unknown")
            return true
        end

        if status == "starting" then
            ngx.log(ngx.INFO, cfg.name, ": Already starting")
            return true
        end

        local dict = get_dict()
        if dict then dict:set("status", "starting") end

        local cmd = cfg.start_cmd(directory, cfg)
        ngx.log(ngx.INFO, cfg.name, ": Starting with command: ", cmd)

        local handle = io.popen(cmd)
        if not handle then
            ngx.log(ngx.ERR, cfg.name, ": Failed to execute start command")
            if dict then dict:set("status", "stopped") end
            return false
        end

        local pid_str = handle:read("*a")
        handle:close()

        local pid = tonumber(pid_str:match("%d+"))
        if not pid then
            ngx.log(ngx.ERR, cfg.name, ": Failed to get PID from output: ", pid_str)
            if dict then dict:set("status", "stopped") end
            return false
        end

        ngx.log(ngx.INFO, cfg.name, ": Started with PID ", pid, " in directory ", directory)
        write_pid(cfg, pid)
        write_current_dir(cfg, directory)
        svc.update_activity()

        return true
    end

    -- Wait for the server port to become ready. Returns true if ready.
    function svc.wait_for_ready(timeout)
        timeout = timeout or cfg.startup_timeout
        local start_time = ngx.now()

        while (ngx.now() - start_time) < timeout do
            if is_port_ready() then
                local dict = get_dict()
                if dict then dict:set("status", "running") end
                ngx.log(ngx.INFO, cfg.name, ": Ready after ", ngx.now() - start_time, " seconds")
                return true
            end

            local pid = read_pid(cfg)
            if pid and not is_process_running(pid) then
                ngx.log(ngx.ERR, cfg.name, ": Process died during startup")
                remove_pid(cfg)
                remove_dir_file(cfg)
                local dict = get_dict()
                if dict then dict:set("status", "stopped") end
                return false
            end

            ngx.sleep(0.5)
        end

        ngx.log(ngx.ERR, cfg.name, ": Timeout waiting for server to be ready")
        return false
    end

    function svc.update_activity()
        local dict = get_dict()
        if dict then dict:set("last_activity", ngx.now()) end
    end

    function svc.get_last_activity()
        local dict = get_dict()
        if dict then return dict:get("last_activity") end
        return nil
    end

    -- Stop the server via the sudo wrapper script (www-data cannot signal root).
    function svc.stop_server()
        local pid = read_pid(cfg)
        if not pid then
            ngx.log(ngx.INFO, cfg.name, ": No PID file, server not running")
            return true
        end

        if not is_process_running(pid) then
            ngx.log(ngx.INFO, cfg.name, ": Process already stopped")
            remove_pid(cfg)
            remove_dir_file(cfg)
            return true
        end

        ngx.log(ngx.INFO, cfg.name, ": Stopping server with PID ", pid)
        os.execute(string.format("sudo %s %d TERM 2>/dev/null", cfg.stop_script, pid))

        ngx.sleep(1)

        if is_process_running(pid) then
            ngx.log(ngx.WARN, cfg.name, ": Force killing PID ", pid)
            os.execute(string.format("sudo %s %d KILL 2>/dev/null", cfg.stop_script, pid))
        end

        remove_pid(cfg)
        remove_dir_file(cfg)

        local dict = get_dict()
        if dict then dict:set("status", "stopped") end

        return true
    end

    -- Stop the server if idle past the timeout.
    -- If config.is_busy is set and returns true, the server is considered active
    -- regardless of timer and the activity clock is reset (fail-safe keep-alive).
    function svc.stop_if_idle()
        local status = svc.get_status()
        if status == "stopped" then
            return
        end

        local dict = get_dict()
        if not dict then return end

        local last_activity = dict:get("last_activity")
        if not last_activity then
            ngx.log(ngx.INFO, cfg.name, ": No activity recorded, stopping")
            svc.stop_server()
            return
        end

        local idle_time = ngx.now() - last_activity
        if idle_time <= cfg.idle_timeout then
            return
        end

        -- Past idle threshold: consult the busy guard before stopping.
        if cfg.is_busy then
            local ok, busy = pcall(cfg.is_busy)
            if not ok then
                ngx.log(ngx.WARN, cfg.name, ": is_busy check failed (", tostring(busy),
                    "), keeping server alive to be safe")
                svc.update_activity()
                return
            end
            if busy then
                ngx.log(ngx.INFO, cfg.name, ": Idle ", idle_time,
                    "s but work in progress, keeping alive")
                svc.update_activity()
                return
            end
        end

        ngx.log(ngx.INFO, cfg.name, ": Idle for ", idle_time, " seconds, stopping")
        svc.stop_server()
    end

    return svc
end

return _M
