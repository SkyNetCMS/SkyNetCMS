-- ============================================
-- SkyNetCMS - Authentication Helper Module
-- ============================================

local _M = {}

-- Path to htpasswd file
_M.HTPASSWD_PATH = "/data/.htpasswd"

-- Check if admin credentials are configured
-- Returns true if htpasswd file exists and is non-empty
function _M.is_admin_configured()
    local file = io.open(_M.HTPASSWD_PATH, "r")
    if not file then
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    -- Check if file has actual content (not just whitespace)
    if content and content:match("%S") then
        return true
    end
    
    return false
end

-- Get client IP address (handles proxies)
function _M.get_client_ip()
    local headers = ngx.req.get_headers()
    
    -- Check X-Forwarded-For first (for proxied requests)
    local xff = headers["X-Forwarded-For"]
    if xff then
        -- Get first IP in the chain
        local ip = xff:match("^([^,]+)")
        if ip then
            return ip:match("^%s*(.-)%s*$") -- trim whitespace
        end
    end
    
    -- Check X-Real-IP
    local xri = headers["X-Real-IP"]
    if xri then
        return xri
    end
    
    -- Fall back to direct connection IP
    return ngx.var.remote_addr
end

-- Rate limiting check using shared dictionary
-- Returns true if request should be allowed, false if rate limited
function _M.check_rate_limit(dict_name, key, max_requests, window_seconds)
    local dict = ngx.shared[dict_name]
    if not dict then
        ngx.log(ngx.ERR, "Rate limit dict not found: ", dict_name)
        return true -- Allow if dict not configured
    end
    
    local current_time = ngx.now()
    local window_key = key .. ":" .. math.floor(current_time / window_seconds)
    
    local count, err = dict:incr(window_key, 1, 0, window_seconds)
    if err then
        ngx.log(ngx.ERR, "Rate limit error: ", err)
        return true -- Allow on error
    end
    
    return count <= max_requests
end

return _M
