local errors = require("projects.utils.errors")
local state = require("projects.state")

local M = {
  --- Global plugin state.
  ---
  ---@private
  ---@type projects.State
  global_state = state.init(),
}

---@param opts? projects.UserConfig
function M.setup(opts) M.global_state:resolve(opts) end

---@param opts projects.AddProjectOpts
---@return boolean ok, unknown|? err
function M.add_project(opts) return pcall(M.global_state.add_project, M.global_state, opts) end

---@param opts projects.DeleteProjectOpts
---@return boolean ok, unknown|? err
function M.delete_project(opts) return pcall(M.global_state.delete_project, M.global_state, opts) end

---@param opts projects.EnterProjectDirectoryOpts|?
---@return boolean ok, unknown|? err
function M.enter_project_directory(opts) return errors.TODO("API.enter_project_directory", opts) end

---@param opts projects.GetRecentProjectsOpts|?
---@return boolean ok, unknown|? err
function M.get_recent_projects(opts) return errors.TODO("API.get_recent_projects", opts) end

return M
