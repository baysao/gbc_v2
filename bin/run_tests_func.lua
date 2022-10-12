--[[

Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]
local os_execute = os.execute
local os_remove = os.remove
local string_format = string.format
local string_lower = string.lower
local string_sub = string.sub

package.path =
    ROOT_DIR .. "/gbc/src/?.lua;" .. ROOT_DIR .. "/src/?.lua;" .. SITE_DIR .. "/apps/tests/?.lua;" .. package.path

require("framework.init")
cc.DEBUG = cc.DEBUG_VERBOSE

local json = cc.import("#json")
local Factory = cc.import("#gbc").Factory

-- local mbrutil = require "mbutil"
-- local _print = mbrutil.print
-- local inspect = require "inspect"
-- declare Tests class

local Tests = cc.class("Tests")
local _CURL_PATTERN = "curl -s -k --no-keepalive -o - '%s'"

if TEST_DOMAIN then
    _CURL_PATTERN = "curl -s -k -H 'Host: " .. TEST_DOMAIN .. "' --no-keepalive -o - '%s'"
end

local _TEST_PATH = "/__tests/"
if TEST_PATH then
    _TEST_PATH = TEST_PATH
end

local _TEST_SCHEME = "https"
if TEST_SCHEME then
    _TEST_SCHEME = TEST_SCHEME
end

local _CURL_PATH = string_format(_TEST_SCHEME .. "://127.0.0.1" .. _TEST_PATH .. "?action=%%s")

local _parseargs, _findtests
local _testsrv, _testcli
local _help

function Tests:ctor(appConfig, appRootPath)
    -- _print(inspect(appConfig))
    -- _print(inspect(appRootPath))
    -- self._url = string_format("https://127.0.0.1:%s/tests/?action=%%s", tostring(appConfig.server.nginx.port))
    self._url = _CURL_PATH
    self._config = appConfig
    self._root = appRootPath
end

function Tests:run(args)
    local opts, err = _parseargs(args)
    if not opts then
        _help()
        return
    end

    if #opts.tests == 0 then
        local casesDir = self._root .. "/actions"
        opts.tests = _findtests(casesDir)
    end

    local pass
    for _, casename in ipairs(opts.tests) do
        if string_sub(casename, -6) ~= "Action" then
            -- casename passed from command line arguments
            casename = string.ucfirst(string.lower(casename)) .. "Action"
        end

        local ok, testCaseClass = pcall(require, "actions." .. casename)
        if not ok then
            -- testCaseClass is error message
            cc.printf("ERR: not found test '%s'\n\n%s", casename, testCaseClass)
            break
        end
        if type(testCaseClass) ~= "table" then
            cc.printf("ERR: '%s' isn't module", casename)
            break
        end

        local actionPackageName = string_lower(string_sub(casename, 1, -7))
        local tests = {}
        for methodName, _2 in pairs(testCaseClass) do
            if string_sub(methodName, -6) == "Action" then
                tests[#tests + 1] = actionPackageName .. "." .. string_lower(string_sub(methodName, 1, -7))
            end
        end

        table.sort(tests)

        print(string_format("## Test Case : %s", actionPackageName))

        for _3, action in ipairs(tests) do
            if opts.testsrv then
                pass = self:_runtest(_testsrv, {action}, "SERVER " .. action)
                if (not pass) and (not opts.continue) then
                    break
                end
            end

            if opts.testcli then
                pass = self:_runtest(_testcli, {action}, "CLI    " .. action)
                if (not pass) and (not opts.continue) then
                    break
                end
            end
        end

        print("")

        if (not pass) and (not opts.continue) then
            break
        end
    end
end

function Tests:_runtest(testfun, arg, action)
    local result
    local err

    local ok, contents =
        xpcall(
        function()
            return testfun(self, unpack(arg))
        end,
        function(_err)
            err = _err .. debug.traceback("", 4)
        end
    )

    if contents == true then
        result = {ok = true}
    elseif type(contents) == "table" then
        result = contents
    else
        result = json.decode(tostring(contents))
        if type(result) ~= "table" then
            contents = tostring(contents)
            contents = string.gsub(contents, "\\n", "\n")
            contents = string.gsub(contents, '\\"', '"')
            result = {err = err}
        end
    end

    if result.err then
        print(string_format("[%s] \27[31mfailed\27[0m: %s", action, result.err))
    elseif tostring(result.ok) == "true" or tostring(result.result) == "true" then
        print(string_format("[%s] \27[32mok\27[0m", action))
        return true
    else
        print(string_format("[%s] \27[33minvalid result\27[0m: %s", action, contents))
    end
end

-- private

_parseargs = function(args)
    local opts = {
        continue = false,
        testsrv = true,
        testcli = true,
        tests = {}
    }
    for _, arg in ipairs(string.split(args, " ")) do
        if arg == "-h" then
            return
        elseif arg == "-c" then
            opts.continue = true
        elseif arg == "-ns" then
            opts.testsrv = false
        elseif arg == "-nc" then
            opts.testcli = false
        elseif string.sub(arg, 1, 1) == "-" then
            print("Invalid options")
            return
        else
            opts.tests[#opts.tests + 1] = arg
        end
    end

    return opts
end

_findtests = function(rootdir)
    local cmd = string_format('ls "%s"', rootdir)
    local h = io.popen(cmd)
    local res = h:read("*a")
    h:close()

    local cases = {}
    for _, file in ipairs(string.split(res, "\n")) do
        if string.sub(file, -10) == "Action.lua" then
            cases[#cases + 1] = string.sub(file, 1, -5)
        end
    end

    table.sort(cases)

    return cases
end

_testsrv = function(self, action)
    local url = string_format(self._url, action)
    local cmd = string_format(_CURL_PATTERN, url)
    print(cmd)
    local h = io.popen(cmd)
    local res = h:read("*a")
    h:close()
    return res
end

_testcli = function(self, action)
    local config = table.copy(self._config)
    config.app.package = "actions"
    local cmd = Factory.create(config, "CommandLineInstance", arg)
    return cmd:runAction(action)
end

_help = function()
    print [[

$ run_tests.sh [options] [test case name ...]

options:
-h: show help
-c: continue when test failed
-ns: skip server tests
-nc: skip cli tests

examples:

# run JobsTestCase and RedisTestCase
run_tests.sh jobs redis

]]
end

-- bootstrap

-- _print("ROOT_DIR:" .. ROOT_DIR)
local appKeys = dofile(ROOT_DIR .. "/tmp/app_keys.lua")
local globalConfig = dofile(ROOT_DIR .. "/tmp/config.lua")
local appConfigs = Factory.makeAppConfigs(appKeys, globalConfig, package.path)
-- _print("appConfigs:" .. inspect(appConfigs))

local appRootPath = SITE_DIR .. "/apps/tests"
local appConfig = appConfigs[appRootPath]
-- _print("appConfig:" .. inspect(appConfig))
cc.exports.runTests = function(arg)
    local tests = Tests:new(appConfig, appRootPath)
    tests:run(arg)
end
