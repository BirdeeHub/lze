#!/usr/bin/env lua

---@class ConstructedSpyType
---@field off? fun()
---@field called table[]
---@field errors table[]
---@field called_with fun(...): boolean
---@operator call(...): any

---@class SpyType
---@field on fun(t: table, k: any): ConstructedSpyType
---@operator call(function): ConstructedSpyType

---@class TestEnv
---@field ok fun(cond: boolean, msg?: string)
---@field spy SpyType
---@field eq fun(a: any, b: any): boolean

---@type SpyType
_G.spy = nil
---@type fun(cond: boolean, msg?: string)
_G.ok = nil
---@type fun(a: any, b: any): boolean
_G.eq = nil

package.preload.gambiarra = function()
    local function TERMINAL_HANDLER(e, test, msg)
        if e == "pass" then
            io.write("[32m✔[0m " .. test .. ": " .. msg .. "\n")
        elseif e == "fail" then
            io.write("[31m✘[0m " .. test .. ": " .. msg .. "\n")
        elseif e == "except" then
            io.write("[31m✘[0m " .. test .. ": " .. msg .. "\n")
        end
    end

    local function deepeq(a, b)
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
        -- Only equal tables could have passed previous tests
        if type(a) ~= "table" then
            return false
        end
        -- Compare tables field by field
        for k, v in pairs(a) do
            if b[k] == nil or not deepeq(v, b[k]) then
                return false
            end
        end
        for k, v in pairs(b) do
            if a[k] == nil or not deepeq(v, a[k]) then
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
    ---@type TestEnv|any
    local env = _G
    local gambiarrahandler = TERMINAL_HANDLER

    local function runpending()
        if pendingtests[1] ~= nil then
            pendingtests[1](runpending)
        end
    end

    return function(name, f, async)
        if type(name) == "function" then
            gambiarrahandler = name
            env = f or _G
            return
        end

        local testfn = function(next)
            local prev = {
                ok = env.ok,
                spy = env.spy,
                eq = env.eq,
            }

            local restore = function()
                env.ok = prev.ok
                env.spy = prev.spy
                env.eq = prev.eq
                gambiarrahandler("end", name)
                table.remove(pendingtests, 1)
                if next then
                    next()
                end
            end

            local handler = gambiarrahandler

            env.eq = deepeq
            env.spy = spy
            env.ok = function(cond, msg)
                if not msg then
                    msg = debug.getinfo(2, "S").short_src .. ":" .. debug.getinfo(2, "l").currentline
                end
                if cond then
                    handler("pass", name, msg)
                else
                    handler("fail", name, msg)
                end
            end

            handler("begin", name)
            local ok, err = pcall(f, restore)
            if not ok then
                handler("except", name, err)
            end

            if not async then
                handler("end", name)
                env.ok = prev.ok
                env.spy = prev.spy
                env.eq = prev.eq
            end
        end

        if not async then
            testfn()
        else
            table.insert(pendingtests, testfn)
            if #pendingtests == 1 then
                runpending()
            end
        end
    end
end

local tests_passed = 0
local tests_failed = 0
require("gambiarra")(function(e, test, msg)
    if e == "pass" then
        io.write("[32m✔[0m " .. test .. ": " .. msg .. "\n")
        tests_passed = tests_passed + 1
    elseif e == "fail" then
        io.write("[31m✘[0m " .. test .. ": " .. msg .. "\n")
        tests_failed = tests_failed + 1
    elseif e == "except" then
        io.write("[31m✘[0m " .. test .. ": " .. msg .. "\n")
        tests_failed = tests_failed + 1
    end
end)

local function cwd()
    local sep = package.config:sub(1, 1)
    local info = debug.getinfo(1, "S")
    local source = info.source
    if source:sub(1, 1) == "@" then
        local path = source:sub(2)
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

local dir, filter
if select("#", ...) == 2 then
    dir, filter = ...
else
    dir = cwd()
    filter = function(filename)
        return filename:match("_test%.lua$")
    end
end

local files = read_dir(dir, filter)
local test = require("gambiarra")
for _, file in ipairs(files) do
    local success, msg = pcall(loadfile, dir .. file)
    if success then
        ---@cast msg function
        success, msg = pcall(msg, test)
    end
    io.write((success and "[32m✔[0m " or "[31m✘[0m ") .. file .. (msg and ": " .. tostring(msg) or "") .. "\n")
end

if tests_failed > 0 then
    os.exit(1)
else
    os.exit(0)
end
