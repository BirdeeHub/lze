-- https://zserge.com/posts/minimal-testing/

---@class GambiarraConstructedSpyType
---@field off? fun()
---@field called table[]
---@field errors table[]
---@field called_with fun(...): boolean
---@operator call(...): any

---@class GambiarraSpyType
---@field on fun(t: table, k: any): GambiarraConstructedSpyType
---@operator call(function): GambiarraConstructedSpyType

---@class GambiarraTestEnv
---@field ok fun(cond: boolean, msg?: string, should_fail?: boolean)
---@field spy GambiarraSpyType
---@field eq fun(a: any, b: any): boolean

---@type GambiarraSpyType
_G.spy = nil
---@type fun(cond: boolean, msg?: string, should_fail?: boolean)
_G.ok = nil
---@type fun(a: any, b: any): boolean
_G.eq = nil

local function deepeq(a, b, visited)
    visited = visited or {}
    -- cycle detection
    if type(a) == "table" and type(b) == "table" then
        if visited[a] and visited[a] == b then
            return true
        end
        visited[a] = b
    end
    -- Different types: false
    if type(a) ~= type(b) then
        return false
    end
    -- Functions
    if type(a) == "function" then
        return string.dump(a) == string.dump(b)
    end
    -- Primitives and equal pointers
    if a == b then
        return true
    end
    -- Only both as tables could have passed previous tests
    if type(a) ~= "table" then
        return false
    end
    for k, v in pairs(a) do
        if b[k] == nil or not deepeq(v, b[k], visited) then
            return false
        end
    end
    -- ones in b not in a
    for k in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

-- Compatibility for Lua 5.1 and Lua 5.2
local function args(...)
    return { n = select("#", ...), ... }
end

local function mkspy(...)
    local mkspyargs = args(...)
    local f, t, k = mkspyargs[1], mkspyargs[2], mkspyargs[3]
    local sp = {}
    if mkspyargs.n > 1 then
        function sp.off()
            t[k] = f
        end
    end
    sp.called = {}
    sp.errors = {}
    setmetatable(sp, {
        __index = function(self, key)
            if key == "called_with" then
                return function(...)
                    local a = { ... }
                    for _, v in ipairs(self.called) do
                        if deepeq(v, a) then
                            return true
                        end
                    end
                    return false
                end
            end
        end,
        __call = function(s, ...)
            s.called = s.called or {}
            local a = args(...)
            table.insert(s.called, { ... })
            if f then
                local r
                r = args(pcall(f, (unpack or table.unpack)(a, 1, a.n)))
                if not r[1] then
                    s.errors = s.errors or {}
                    s.errors[#s.called] = r[2]
                else
                    return (unpack or table.unpack)(r, 2, r.n)
                end
            end
        end,
    })
    if mkspyargs.n > 1 then
        t[k] = function(...)
            sp(...)
        end
    end
    return sp
end
local spy = setmetatable({}, {
    __index = {
        on = function(t, k)
            return mkspy(t[k], t, k)
        end,
    },
    __call = function(_, f)
        return mkspy(f)
    end,
})

local pendingtests = {}
local await_callbacks = {}
---@type GambiarraTestEnv|any
local env = _G

local function runpending()
    if pendingtests[1] ~= nil then
        pendingtests[1](runpending)
    else
        for _, f in ipairs(await_callbacks) do
            f()
        end
        await_callbacks = {}
    end
end

local function cwd()
    local sep = package.config:sub(1, 1)
    local info = debug.getinfo(1, "S")
    local source = info.source
    if source:sub(1, 1) == "@" then
        local realpath = ((vim or {}).uv or (vim or {}).loop or {}).fs_realpath
        if not realpath then
            local ok, luv = pcall(require, "luv")
            if ok then
                realpath = luv.fs_realpath
            end
        end
        local path = source:sub(2)
        path = realpath and realpath(path) or path
        local dir, file = path:match("^(.*[" .. sep .. "])([^" .. sep .. "]+)$")
        return dir or ("." .. sep), file
    end
    return "." .. sep, nil
end

local function read_dir(dir, filter)
    local uv = (vim or {}).uv or (vim or {}).loop
    if not uv then
        local ok, luv = pcall(require, "luv")
        if ok then
            uv = luv
        end
    end
    if uv then
        local files = {}
        local handle = uv.fs_scandir(dir)
        while handle do
            local name, ty = uv.fs_scandir_next(handle)
            if not name then
                break
            end
            local path = dir .. name
            ty = ty or (uv.fs_stat(path) or {}).type
            if ty == "file" or ty == "link" then
                if not filter or filter(name) then
                    table.insert(files, name)
                end
            end
        end
        return files
    end

    local ok, lfs = pcall(require, "lfs")
    if ok then
        local files = {}
        for name in lfs.dir(dir) do
            if name ~= "." and name ~= ".." then
                local path = dir .. name
                local attr = lfs.attributes(path)

                if attr and (attr.mode == "file" or attr.mode == "link") then
                    if not filter or filter(name) then
                        table.insert(files, name)
                    end
                end
            end
        end
        return files
    end

    local command = package.config:sub(1, 1) == "\\" and ('dir "' .. dir .. '" /b') or ('ls -1 "' .. dir .. '"')
    local handle = io.popen(command)
    local files = {}
    if not handle then
        return files
    end
    for filename in handle:lines() do
        if not filter or filter(filename) then
            table.insert(files, filename)
        end
    end
    handle:close()
    return files
end

return setmetatable({
    read_dir = read_dir,
    cwd = cwd,
    icons = {
        pass = "[32m✔[0m",
        fail = "[31m✘[0m",
        except = "[35m‼[0m",
        begin = "[36m▶[0m",
        _end = "[36m◀[0m",
    },
    tests_passed = 0,
    tests_failed = 0,
    gambiarrahandler = function(self, e, async, desc, msg, err)
        local suffix = (async and (desc .. " ") or "")
            .. tostring(msg)
            .. (err and "\n   (with error: " .. err .. ")" or "")
        if e == "pass" then
            io.stdout:write("\n   " .. self.icons.pass .. " " .. suffix)
        elseif e == "fail" then
            io.stdout:write("\n   " .. self.icons.fail .. " " .. suffix)
        elseif e == "except" then
            io.stdout:write("\n " .. self.icons.except .. " " .. suffix)
        elseif e == "begin" then
            io.stdout:write("\n " .. self.icons.begin .. " " .. desc .. " " .. self.icons.begin)
            -- elseif e == "end" then
            --     io.stdout:write("\n " .. self.icons._end .. " " .. desc .. " " .. self.icons._end)
        end
    end,
}, {
    __index = function(self, key)
        if key == "reset_count" then
            return function()
                self.tests_passed = 0
                self.tests_failed = 0
            end
        elseif key == "report" then
            return function()
                io.stdout:write(
                    "\n "
                        .. self.icons.begin
                        .. " Tests ran: "
                        .. tostring((self.tests_failed or 0) + (self.tests_passed or 0))
                        .. "\n"
                )
                io.stdout:write(" " .. self.icons.pass .. " Tests passed: " .. tostring(self.tests_passed) .. "\n")
                if (self.tests_failed or 0) > 0 then
                    io.stdout:write(" " .. self.icons.fail .. " Tests failed: " .. tostring(self.tests_failed) .. "\n")
                end
            end
        elseif key == "await" then
            return function(f)
                if #pendingtests == 0 then
                    f(self)
                else
                    table.insert(await_callbacks, function()
                        f(self)
                    end)
                end
            end
        elseif key == "pending" then
            return #pendingtests
        end
    end,
    __call = function(self, name, f, async)
        if type(name) == "function" then
            self.gambiarrahandler = name
            env = f or _G
            return
        end

        local testfn = function(next)
            local prev = {
                ok = env.ok,
                spy = env.spy,
                eq = env.eq,
            }

            local handler = function(...)
                local e = ({ ... })[2]
                if e == "pass" then
                    self.tests_passed = (self.tests_passed or 0) + 1
                elseif e == "end" then
                    self.tests_passed = (self.tests_passed or 0) + 1
                elseif e == "fail" then
                    self.tests_failed = (self.tests_failed or 0) + 1
                elseif e == "except" then
                    self.tests_failed = (self.tests_failed or 0) + 1
                end
                self.gambiarrahandler(...)
            end
            local was_restored = false
            local function restore()
                was_restored = true
                env.ok = prev.ok
                env.spy = prev.spy
                env.eq = prev.eq
                table.remove(pendingtests, 1)
                if next then
                    next()
                end
            end
            local usernext = function(fn, ...)
                if fn then
                    local res = args(pcall(fn, ...))
                    if res[1] then
                        return (unpack or table.unpack)(res, 2, res.n)
                    else
                        handler(self, "except", async, name, res[2])
                    end
                else
                    handler(self, "end", async, name)
                end
                restore()
            end

            env.eq = function(a, b)
                return deepeq(a, b)
            end
            env.spy = spy
            env.ok = function(cond, msg, should_fail)
                if not msg then
                    msg = debug.getinfo(2, "S").short_src .. ":" .. debug.getinfo(2, "l").currentline
                end
                if type(cond) == "function" then
                    local ok, value = pcall(cond)
                    if should_fail and not ok or not should_fail and ok then
                        handler(self, "pass", async, name, msg)
                    else
                        handler(
                            self,
                            "fail",
                            async,
                            name,
                            msg,
                            not should_fail and tostring(value)
                                or "Task failed successfully. No error, that is the problem."
                        )
                    end
                elseif should_fail and not cond or not should_fail and cond then
                    handler(self, "pass", async, name, msg)
                else
                    handler(self, "fail", async, name, msg)
                end
            end

            handler(self, "begin", async, name)
            local ok, err
            if async then
                ok, err = pcall(f, usernext)
            else
                ok, err = pcall(f)
            end
            if not ok then
                handler(self, "except", async, name, err)
                if async and not was_restored then
                    restore()
                end
            elseif not async then
                handler(self, "end", async, name)
            end

            if not async then
                env.ok = prev.ok
                env.spy = prev.spy
                env.eq = prev.eq
            end
        end

        if async then
            table.insert(pendingtests, testfn)
            if #pendingtests == 1 then
                runpending()
            end
        else
            testfn()
        end
    end,
})
