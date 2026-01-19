-- ============================================
-- SkyNetCMS - Registration Handler
-- ============================================
-- Handles POST requests to /sn_admin/register
-- Creates htpasswd file with admin credentials

local auth = require("auth")
local cjson = require("cjson.safe")

-- Configuration
local HTPASSWD_PATH = "/data/auth/.htpasswd"
local RATE_LIMIT_MAX = 5      -- max attempts
local RATE_LIMIT_WINDOW = 60  -- per 60 seconds

-- Helper: Send JSON response
local function json_response(status, data)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode(data))
    ngx.exit(status)
end

-- Helper: Validate username
local function validate_username(username)
    if not username or username == "" then
        return false, "Username is required"
    end
    
    if #username < 3 then
        return false, "Username must be at least 3 characters"
    end
    
    if #username > 32 then
        return false, "Username must be at most 32 characters"
    end
    
    -- Only allow alphanumeric, underscore, hyphen
    if not username:match("^[a-zA-Z0-9_-]+$") then
        return false, "Username can only contain letters, numbers, underscores, and hyphens"
    end
    
    return true
end

-- Helper: Validate password
local function validate_password(password, confirm_password)
    if not password or password == "" then
        return false, "Password is required"
    end
    
    if #password < 8 then
        return false, "Password must be at least 8 characters"
    end
    
    if #password > 128 then
        return false, "Password must be at most 128 characters"
    end
    
    if password ~= confirm_password then
        return false, "Passwords do not match"
    end
    
    return true
end

-- Helper: Create htpasswd file using htpasswd command
local function create_htpasswd(username, password)
    -- Escape special characters for shell
    local function shell_escape(s)
        return "'" .. s:gsub("'", "'\\''") .. "'"
    end
    
    local escaped_user = shell_escape(username)
    local escaped_pass = shell_escape(password)
    local escaped_path = shell_escape(HTPASSWD_PATH)
    
    -- Use htpasswd with bcrypt (-B) and create new file (-c)
    local cmd = string.format(
        "htpasswd -cbB %s %s %s 2>&1",
        escaped_path,
        escaped_user,
        escaped_pass
    )
    
    local handle = io.popen(cmd)
    if not handle then
        return false, "Failed to execute htpasswd command"
    end
    
    local result = handle:read("*a")
    local success, exit_type, exit_code = handle:close()
    
    if not success or exit_code ~= 0 then
        ngx.log(ngx.ERR, "htpasswd failed: ", result)
        return false, "Failed to create credentials"
    end
    
    return true
end

-- Main handler
local function handle_registration()
    -- Only allow POST
    if ngx.req.get_method() ~= "POST" then
        json_response(405, { success = false, error = "Method not allowed" })
    end
    
    -- Check if admin is already configured
    if auth.is_admin_configured() then
        json_response(403, { success = false, error = "Admin already configured" })
    end
    
    -- Rate limiting
    local client_ip = auth.get_client_ip()
    local rate_key = "register:" .. client_ip
    
    if not auth.check_rate_limit("rate_limit", rate_key, RATE_LIMIT_MAX, RATE_LIMIT_WINDOW) then
        json_response(429, { 
            success = false, 
            error = "Too many attempts. Please wait a minute and try again." 
        })
    end
    
    -- Read POST body
    ngx.req.read_body()
    local args, err = ngx.req.get_post_args()
    
    if not args then
        ngx.log(ngx.ERR, "Failed to get POST args: ", err)
        json_response(400, { success = false, error = "Invalid request" })
    end
    
    local username = args.username
    local password = args.password
    local confirm_password = args.confirmPassword
    
    -- Validate username
    local valid, err = validate_username(username)
    if not valid then
        json_response(400, { success = false, error = err })
    end
    
    -- Validate password
    valid, err = validate_password(password, confirm_password)
    if not valid then
        json_response(400, { success = false, error = err })
    end
    
    -- Create htpasswd file
    local success, err = create_htpasswd(username, password)
    if not success then
        json_response(500, { success = false, error = err })
    end
    
    ngx.log(ngx.INFO, "Admin account created for user: ", username)
    
    json_response(200, { 
        success = true, 
        message = "Admin account created successfully" 
    })
end

-- Execute handler
handle_registration()
