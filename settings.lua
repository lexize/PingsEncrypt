--[[
    PingsEncrypt.
    Made by Lexize#0765
    Source: https://github.com/lexize/PingsEncrypt
]]

---@class PingsKey
---@field secret integer

---@class PingsSettings
---@field keys table<string, PingsKey>
---@field replace_pings boolean
---@field builtin_pings_variable string
---@field encrypted_pings_variable string
local settings = {};
settings.keys = {};
settings.replace_pings = true;
settings.builtin_pings_variable = "native_pings";
settings.encrypted_pings_variable = "encrypted_pings";
settings.default_key = "world";

local allowed_fields = {
    replace_pings = {"boolean"},
    builtin_pings_variable = {"string"},
    encrypted_pings_variable = {"string"},
    default_key = {"string", "nil"}
}

local settings_metatable = {};

function settings_metatable:__index(k)
    return settings[k];
end

function settings_metatable:__newindex(k, v)
    local allowedTypes = allowed_fields[k];
    if (allowedTypes ~= nil) then
        for _, allowedType in ipairs(allowedTypes) do
            if (type(v) == allowedType) then
                settings[k] = v;
                return;
            end
        end
        error(string.format("Error while changing value. "..
                "\"%s\" expect value to be one of these types: [%s], got %s", k, table.concat(allowedTypes, ", "), type(v)));
    end
end

return setmetatable({}, settings_metatable) --[[@as PingsSettings]]