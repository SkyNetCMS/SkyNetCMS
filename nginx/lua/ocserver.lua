-- ============================================
-- SkyNetCMS - OpenCode Server Management Module
-- ============================================
-- Manages the on-demand OpenCode backend lifecycle:
-- - Starts OpenCode when /sn_admin/oc/ is first accessed
-- - Tracks activity (any HTTP request / active WebSocket) for idle shutdown
-- - Auto-stops after 5 minutes of inactivity, BUT only when no session is busy
--
-- The "busy" guard queries OpenCode's own API (GET /session/status) and keeps
-- the server alive if any session is running/retrying, so a long AI generation
-- is never killed mid-stream. The query is fail-safe: on any error we assume
-- busy and keep the server alive.
--
-- Built on the shared serverlifecycle controller.

local lifecycle = require("serverlifecycle")

local OC_PORT = 3000

-- Query OpenCode's /session/status endpoint over a raw TCP socket and return
-- true if any session is busy (running) or retrying.
--
-- We use ngx.socket.tcp directly (no lua-resty-http dependency) since the
-- request is a trivial GET and the response is small JSON.
--
-- SessionStatus per OpenCode SDK: { type: "idle" | "busy" | "retry" }
-- /session/status returns: { [sessionID]: SessionStatus }
local function is_busy()
    local sock = ngx.socket.tcp()
    sock:settimeout(2000)  -- 2s connect+read budget

    local ok, err = sock:connect("127.0.0.1", OC_PORT)
    if not ok then
        ngx.log(ngx.WARN, "ocserver: is_busy connect failed: ", err)
        error("connect failed: " .. tostring(err))
    end

    -- OpenCode is served behind --base-path /sn_admin/oc
    local req = "GET /sn_admin/oc/session/status HTTP/1.1\r\n"
        .. "Host: 127.0.0.1\r\n"
        .. "Connection: close\r\n"
        .. "Accept: application/json\r\n"
        .. "\r\n"

    local bytes, send_err = sock:send(req)
    if not bytes then
        sock:close()
        ngx.log(ngx.WARN, "ocserver: is_busy send failed: ", send_err)
        error("send failed: " .. tostring(send_err))
    end

    -- Read the whole response (status line + headers + body) until close
    local data, read_err, partial = sock:receive("*a")
    sock:close()

    local body = data or partial
    if not body then
        ngx.log(ngx.WARN, "ocserver: is_busy receive failed: ", read_err)
        error("receive failed: " .. tostring(read_err))
    end

    -- Separate headers from body
    local _, header_end = body:find("\r\n\r\n", 1, true)
    local payload = header_end and body:sub(header_end + 1) or body

    local status_line = body:match("^HTTP/%d%.%d (%d+)")
    -- A 404 means this OpenCode build does not expose /session/status. In that
    -- case we cannot poll busy-state, so report not-busy and let connection
    -- activity (the UI's persistent SSE/WebSocket) protect in-progress work.
    -- Requires opencode >= 1.15.12-sn for the route to exist.
    if status_line == "404" then
        ngx.log(ngx.WARN, "ocserver: /session/status not available (404); ",
            "relying on connection activity for idle protection")
        return false
    end
    -- Any other non-2xx status: treat as uncertain -> busy (fail-safe keep-alive)
    if status_line and status_line ~= "200" then
        ngx.log(ngx.WARN, "ocserver: is_busy got HTTP ", status_line, ", assuming busy")
        return true
    end

    -- Detect an active session. SessionStatus.type is "busy" or "retry" when working.
    if payload:find('"type"%s*:%s*"busy"') or payload:find('"type"%s*:%s*"retry"') then
        return true
    end

    return false
end

local svc = lifecycle.new({
    name = "ocserver",
    port = OC_PORT,
    pid_file = "/tmp/opencode.pid",
    dir_file = "/tmp/opencode.dir",
    dict_name = "oc_server",
    log_file = "/tmp/opencode-dev.log",
    default_dir = "/data/website",
    idle_timeout = 300,       -- 5 minutes
    startup_timeout = 30,
    stop_script = "/scripts/stop-opencode.sh",
    start_cmd = function(directory, cfg)
        -- start-opencode.sh handles XDG env, working dir, and exec.
        -- nohup + & detaches; echo $! returns the PID.
        return string.format(
            "nohup sudo /scripts/start-opencode.sh > %s 2>&1 & echo $!",
            cfg.log_file
        )
    end,
    is_busy = is_busy,
})

return svc
