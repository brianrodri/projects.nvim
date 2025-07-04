local formats = require("projects.utils.formats")

---@class projects.Path
---@field path string
local Path = {}

Path.__index = Path
Path.__tostring = function(self) return self.path end
Path.__eq = function(self, obj) return Path.is_path_obj(self) and Path.is_path_obj(obj) and self.path == obj.path end

---@param obj any
---@return boolean is_path_obj
function Path.is_path_obj(obj) return getmetatable(obj) == Path end

--- Constructs a new `projects.Path`. Wrapper around |vim.fs.joinpath()|.
---
---@param base projects.Path|string   An absolute or relative path.
---@param ... projects.Path|string|?  Zero or more relative paths. `nil`s are skipped.
---@return projects.Path new_path
function Path.new(base, ...)
    assert(
        type(base) == "string" or Path.is_path_obj(base),
        formats.call_error("base not a path", "Path.new", base, ...)
    )
    if type(base) ~= "string" and select("#", ...) == 0 then return base end
    local self = setmetatable({}, Path)
    self.path = vim.iter({ ... }):map(tostring):fold(tostring(base), vim.fs.joinpath)
    return self
end

--- Wrapper around |nvim_buf_get_name|.
---
---@param buffer_id? integer  Use 0 for current buffer (defaults to 0).
---@return projects.Path buffer_path
function Path.of_buffer(buffer_id) return Path.new(vim.api.nvim_buf_get_name(buffer_id or 0)) end

--- Wrapper around |stdpath|.
---
---@param what
---| "cache"        Cache directory: arbitrary temporary storage for plugins, etc.
---| "config"       User configuration directory. |init.vim| is stored here.
---| "config_dirs"  Other configuration directories.
---| "data"         User data directory.
---| "data_dirs"    Other data directories.
---| "log"          Logs directory (for use by plugins too).
---| "run"          Run directory: temporary, local storage for sockets, named pipes, etc.
---| "state"        Session state directory: storage for file drafts, swap, undo, |shada|.
---
---@overload fun(what: "cache" | "config" | "data" | "log" | "run" | "state"): stdpath: projects.Path
---@overload fun(what: "config_dirs" | "data_dirs"): stdpaths: projects.Path[]
function Path.stdpath(what)
    local result = vim.fn.stdpath(what)
    return type(result) == "table" and vim.tbl_map(Path.new, result) or Path.new(result)
end

--- Wrapper around |vim.fs.basename()|.
---
---@return string basename
function Path:basename() return vim.fs.basename(self.path) end

--- Returns the |vim.fs.basename()| without its final extension.
---
---@return string|? stem
function Path:stem()
    local basename = self:basename()
    return basename and string.match(basename, "^(.+)%.[^%.]+$") or basename
end

--- Wrapper around |vim.fs.dirname()|.
---
---@return projects.Path|? dirname
function Path:dirname() return Path.new(vim.fs.dirname(self.path)) end

--- Wrapper around |vim.fs.normalize()|.
---
---@param opts? vim.fs.normalize.Opts
---
---@return projects.Path normalized_path
function Path:normalize(opts) return Path.new(vim.fs.normalize(self.path, opts)) end

--- Wrapper around |fs_stat()|.
---
---@return boolean exists
function Path:exists() return vim.uv.fs_stat(self.path) ~= nil end

--- Wrapper around |fs_realpath()|.
---
---@return projects.Path resolved_path
function Path:resolve()
    local realpath, err = vim.uv.fs_realpath(self.path)
    if not realpath then error(formats.call_error(err, "fs_realpath", self.path), 0) end
    return Path.new(realpath)
end

--- Wrapper around |io.open()| that ensures |file:close()| is always called.
---
---@generic T
---@param file_mode openmode
---@param callback fun(file: file*): ...: T  Called after |io.open()| succeeds. IMPORTANT: THIS MUST NOT CLOSE THE FILE!
---@return T ...
function Path:with_file(file_mode, callback)
    local file, open_err = io.open(self.path, file_mode)
    assert(file, formats.call_error(open_err, "io.open", self.path, file_mode))
    local pcall_results = table.pack(pcall(callback, file))
    local close_ok, close_err, close_err_code = file:close()
    local aggregate_error = formats.merge_lines({
        not close_ok and formats.call_error(formats.err_code(close_err, close_err_code), "file.close", file),
        not pcall_results[1] and formats.call_error(pcall_results[2], "callback", file),
    })
    assert(not aggregate_error, aggregate_error)
    return unpack(pcall_results, 2)
end

--- Wrapper around |vim.fs.parents|.
---
---@return (fun(state: nil, cur: projects.Path): projects.Path|?) iter_next, nil iter_state, projects.Path|nil iter_init
function Path:parents()
    local iter_next, iter_state, iter_init = vim.fs.parents(self.path)
    local path_iter_next = function(state, curr)
        local next_parent = iter_next(state, curr.path)
        if next_parent then return Path.new(next_parent) end
    end
    return path_iter_next, iter_state, iter_init and Path.new(iter_init)
end

--- Wrapper around |vim.fs.parents|.
---
---@param path projects.Path
function Path:is_parent_of(path)
    return vim.iter(path:parents()):any(function(p) return p.path == self.path end)
end

--- Wrapper around |uv.fs_stat()|.
function Path:stat() return vim.uv.fs_stat(self.path) end

--- Wrapper around |uv.fs_stat()|.
function Path:isfile()
    local stat = self:stat()
    return stat ~= nil and stat.type == "file"
end

--- Wrapper around |uv.fs_stat()|.
function Path:isdir()
    local stat = self:stat()
    return stat ~= nil and stat.type == "directory"
end

--- Wrapper around |mkdir()|.
---
---@return boolean success
function Path:mkdir() return vim.fn.isdirectory(self.path) == 1 or vim.fn.mkdir(self.path, "p") == 1 end

--- Wrapper around |vim.fs.root()|.
---
---@param marker
---| string                             A marker to search for.
---| string[]                           A list of markers to search for.
---| fun(path: projects.Path): boolean  A function that returns true if matched.
---@return projects.Path|? root_path
function Path:find_root(marker)
    local marker_wrapper = vim.is_callable(marker) and function(_, path) return marker(Path.new(path)) end or marker
    local root = vim.fs.root(self.path, marker_wrapper)
    return root and Path.new(root) or nil
end

return Path
