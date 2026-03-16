-- ============================================
-- SkyNetCMS - Dev Preview HTML Rewriter
-- ============================================
-- Rewrites absolute paths in HTML responses from the dev server
-- so that user-authored links like /pricing become /sn_admin/dev/pricing.
--
-- Only called for text/html responses (controlled by body_filter in nginx).
-- Skips paths that:
-- - Already start with /sn_admin/ (admin routes, already-prefixed assets)
-- - Start with /@ (dev server internals like /@vite/, /@fs/)
-- - Start with // (protocol-relative URLs)

local _M = {}

local DEV_BASE = "/sn_admin/dev/"

-- Prefixes that must NOT be rewritten
local SKIP_PREFIXES = {
    "/sn_admin/",
    "/@",
    "//",
}

-- HTML attributes to rewrite
local ATTRS = { "href", "src", "action" }

-- Check if a path should be skipped
local function should_skip(path)
    for _, prefix in ipairs(SKIP_PREFIXES) do
        if path:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

-- Rewrite occurrences of attr="/path" in the body for a single attribute name.
-- Handles both double and single quoted values.
local function rewrite_attr(body, attr)
    for _, q in ipairs({'"', "'"}) do
        -- Pattern: attr="/<path>"  (case-insensitive attr via both cases)
        -- Capture group 1: everything up to and including the opening quote
        -- Capture group 2: the /path including closing quote
        local pattern = "(" .. attr .. "%s*=%s*" .. q .. ")(/[^" .. q .. "]*" .. q .. ")"
        body = body:gsub(pattern, function(prefix, path_with_quote)
            -- path_with_quote example: /pricing" or /sn_admin/oc/"
            local path = path_with_quote:sub(1, -2)   -- strip closing quote
            local closing = path_with_quote:sub(-1)    -- the closing quote char

            if should_skip(path) then
                return prefix .. path_with_quote  -- unchanged
            end

            -- /pricing -> /sn_admin/dev/pricing
            return prefix .. DEV_BASE .. path:sub(2) .. closing
        end)
    end

    return body
end

--- Rewrite absolute paths in an HTML body string.
-- @param body string  The full HTML response body
-- @return string  The rewritten HTML
function _M.rewrite_html(body)
    if not body or body == "" then
        return body
    end

    for _, attr in ipairs(ATTRS) do
        body = rewrite_attr(body, attr)
    end

    return body
end

return _M
