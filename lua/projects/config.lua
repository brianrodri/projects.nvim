local Path = require("projects.models.path")
local formats = require("projects.utils.formats")

local M = {}

---@class projects.Config
--- NOTE: Individual fields are defined in the |CONFIG RESOLVER DEFINITIONS| section.
local DEFAULT_CONFIG = {}

---@class projects.Config.Resolvers: { [string]: fun(opts?: projects.SetupOpts): unknown }
---@private
---
-- Each function receives user-provided options and returns a value for the corresponding field, or `nil` to fallback to
-- the default value. Otherwise, throws an error message describing the issue(s) that could not be safely resolved.
---
--- NOTE: Individual functions are defined in the |CONFIG RESOLVER DEFINITIONS| section.
local CONFIG_RESOLVERS = {}

--- Returns a valid config from the user-provided options. Otherwise, throws an error message describing the issue(s).
---
---@param setup_opts projects.SetupOpts|?
---@return projects.Config
function M.from_setup_opts(setup_opts)
    local resolved_config = {} ---@type projects.Config|{}
    local resolve_errors = {} ---@type string[]

    for field_name, default in pairs(DEFAULT_CONFIG) do
        local ok, result = pcall(function() return CONFIG_RESOLVERS[field_name](setup_opts) end)
        resolved_config[field_name] = ok and result or default
        if not ok then table.insert(resolve_errors, formats.call_error(result, "resolve_field", field_name)) end
    end
    assert(#resolve_errors == 0, formats.call_error(formats.merge_lines(resolve_errors), "from_setup_opts", setup_opts))
    ---@cast resolved_config -{}

    return resolved_config
end

------------------------------------------------------------------------------------------------------------------------
-- CONFIG RESOLVER DEFINITIONS
------------------------------------------------------------------------------------------------------------------------

--- The directory used to persist state between Neovim sessions.
DEFAULT_CONFIG.data_dir = Path.new(vim.fn.stdpath("data"), "projects-nvim")

---@param opts? projects.SetupOpts
---@return projects.Path|?
CONFIG_RESOLVERS.data_dir = function(opts)
    local user_value = opts and opts.data_dir
    if not user_value then return nil end
    if type(user_value) == "function" or vim.is_callable(user_value) then user_value = user_value() end
    local data_dir = Path.new(user_value):normalize()
    assert(data_dir:mkdir(), "failed to access directory")
    return data_dir
end

return M
