-- ============================================
-- SkyNetCMS - Dev Server Management Module
-- ============================================
-- Manages the on-demand Vite dev server lifecycle:
-- - Starts dev server when /sn_admin/dev/ is accessed
-- - Supports dynamic worktree directories
-- - Tracks activity for idle shutdown
-- - Auto-stops after 5 minutes of inactivity
-- - Restarts if the worktree changes
--
-- This is a thin wrapper over the shared serverlifecycle controller. The public
-- API (get_status, start_server, wait_for_ready, needs_restart, stop_server,
-- stop_if_idle, update_activity, get_last_activity, get_current_directory,
-- IDLE_TIMEOUT) is preserved for existing callers in default.conf and nginx.conf.

local lifecycle = require("serverlifecycle")

local DEV_PORT = 5173

local svc = lifecycle.new({
    name = "devserver",
    port = DEV_PORT,
    pid_file = "/tmp/vite-dev.pid",
    dir_file = "/tmp/vite-dev.dir",
    dict_name = "dev_server",
    log_file = "/tmp/vite-dev.log",
    default_dir = "/data/website",
    idle_timeout = 300,       -- 5 minutes
    startup_timeout = 30,
    stop_script = "/scripts/stop-vite.sh",
    start_cmd = function(directory, cfg)
        -- Run via sudo wrapper: nginx worker is www-data but Vite needs write
        -- access to node_modules. nohup + & detaches; echo $! returns the PID.
        return string.format(
            "nohup sudo /scripts/start-vite.sh %d /sn_admin/dev/ %s > %s 2>&1 & echo $!",
            cfg.port,
            directory,
            cfg.log_file
        )
    end,
})

-- Preserve the legacy module fields/constants some callers may reference
svc.DEV_PORT = DEV_PORT
svc.PID_FILE = "/tmp/vite-dev.pid"
svc.DIR_FILE = "/tmp/vite-dev.dir"
svc.WEBSITE_DIR = "/data/website"

return svc
