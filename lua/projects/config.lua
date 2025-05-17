local errors = require("projects.utils.errors")
local path = require("projects.utils.path")

local M = {}

---@class projects.UserConfig
---@field data_dir? string|fun(): string  Determines where the plugin stores its persistent state.

---@class projects.ResolvedConfig: projects.UserConfig
---@field data_dir projects.Path

---@type projects.UserConfig
local DEFAULT_CONFIG = {
  data_dir = vim.fn.stdpath("data") .. "/projects.nvim",
}

---@type table<string, fun(opts: projects.UserConfig, resolved: projects.ResolvedConfig)>
local FIELD_RESOLVERS = {
  data_dir = function(opts, resolved)
    local opts_data_dir = assert(opts.data_dir, "value is required")
    local resolved_data_dir = path.join(type(opts_data_dir) == "string" and opts_data_dir or opts_data_dir())
    assert(resolved_data_dir:make_directory(), string.format("error making directory: %s", tostring(resolved_data_dir)))
    resolved.data_dir = resolved_data_dir
  end,
}

---@param opts? projects.UserConfig
---@return projects.ResolvedConfig
function M.resolve_opts(opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), opts or {})
  local resolved = {}
  local resolve_errors = {}
  for field, resolver in pairs(FIELD_RESOLVERS) do
    local ok, err = pcall(resolver, opts, resolved)
    if not ok then
      table.insert(resolve_errors, string.format("invalid %s = %s: %s", field, vim.inspect(opts[field]), tostring(err)))
    end
  end
  assert(#resolve_errors == 0, string.format("failed to resolve UserConfig: %s", errors.join(resolve_errors)))
  ---@cast resolved projects.ResolvedConfig
  return resolved
end

return M
