local errors = require("projects.utils.errors")
local fmt = require("projects.utils.fmt")
local path = require("projects.utils.path")

local PERSISTED_STATE_PATH = "projects.nvim/persisted-state.json"

---@class projects.State
---@field state_path projects.Path
---@field resolved boolean
local State = {
  __tostring = function(self) return fmt.class_string(self, "projects.State", "state_path", "resolved") end,
}

function State.init()
  local self = setmetatable({}, State)
  self.state_path = path.stdpath("data"):join(PERSISTED_STATE_PATH)
  self.resolved = false
  return self
end

---@param opts? projects.UserConfig
function State:resolve(opts) errors.TODO("State.resolve", self, opts) end

---@param opts projects.AddProjectOpts
function State:add_project(opts) errors.TODO("State.add_project", self, opts) end

---@param opts projects.DeleteProjectOpts
function State:delete_project(opts) errors.TODO("State.delete_project", self, opts) end

return State
