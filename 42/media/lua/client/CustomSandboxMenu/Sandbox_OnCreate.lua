-- Sandbox_OnCreate.lua

local LuaEvent = require "Starlit/LuaEvent"
local OnCreateSandboxOptions = {
    events = {},
}

function OnCreateSandboxOptions.addListener(pageName, func)
    OnCreateSandboxOptions.events[pageName] = OnCreateSandboxOptions.events[pageName] or LuaEvent.new()
    OnCreateSandboxOptions.events[pageName]:addListener(func)
end

return OnCreateSandboxOptions