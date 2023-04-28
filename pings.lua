--[[
    PingsEncrypt.
    Made by Lexize#0765
    Source: https://github.com/lexize/PingsEncrypt
]]

local path = ...;
---@type PingsSettings
local settings = require(#path > 0 and path..".settings" or "settings");
local util = require(#path > 0 and path..".util" or "util");
local serializer = require(#path > 0 and path..".serializer" or "serializer");
local stream = require(#path > 0 and path..".stream" or "stream");

local builtin_pings = pings;
local encrypted_pings = {};

if (settings.replace_pings) then
    _G[settings.builtin_pings_variable] = pings;
    pings = encrypted_pings;
else
    _G[settings.encrypted_pings_variable] = encrypted_pings;
end

local ping_invokers = {};

local encrypted_pings_metatable = {};

local function getHash(key_name)
    local k = settings.keys[key_name or settings.default_key];
    if (k == nil) then return nil end;
    return bit32.bxor(util.hashFromSource(k.secret)), k.secret;
end

local function createFunctionRunner(k)
    return function (...)
        ping_invokers:sendWithKey(k, nil, ...);
    end
end

local function createFunctionWrapper(func)
    return function (k, ...)
        if (k == nil) then
            func(...);
        else
            for key_name, _ in pairs(settings.keys) do
                local h, s = getHash(key_name);
                if (h == k) then
                    local secretBytes = {};
                    for _, v in ipairs({util.hashFromSource(s)}) do
                        for _, b in ipairs({util.numToBytes(v, 4)}) do
                            secretBytes[#secretBytes+1] = b;
                        end
                    end
                    local encryptedBytes = ...;
                    local bytes = {};
                    local rot = 0;
                    for i = 1, #encryptedBytes, 1 do
                        local b = string.byte(string.sub(encryptedBytes, i, i));
                        local sb = secretBytes[((i-1) % #secretBytes)+1]
                        rot = rot + sb;
                        bytes[#bytes+1] = util.byteRotate(b, -rot);
                        
                    end
                    local stream = stream.createByteStream(table.unpack(bytes));
                    local args = {serializer.deserialize(stream)};
                    func(table.unpack(args));
                    return;
                end
            end
        end
    end
end

function encrypted_pings_metatable:__index(k)
    return ping_invokers[k];
end

function encrypted_pings_metatable:__newindex(k, v)
    builtin_pings[k] = createFunctionWrapper(v);
    ping_invokers[k] = createFunctionRunner(k);
end

function ping_invokers:sendWithKey(ping_name, key_name, ...)
    local key, secret;
    if (key_name ~= false) then
        key, secret = getHash(key_name);
    end
    if (key == nil) then
        builtin_pings[ping_name](nil, ...);
    else
        local bytes = serializer.serialize(...);
        local secretBytes = {};
        for _, v in ipairs({util.hashFromSource(secret)}) do
            for _, b in ipairs({util.numToBytes(v, 4)}) do
                secretBytes[#secretBytes+1] = b;
            end
        end
        local encryptedBytes = "";
        local rot = 0;
        for i = 1, #bytes, 1 do
            local b = string.byte(string.sub(bytes, i, i));
            local sb = secretBytes[((i-1) % #secretBytes)+1]
            rot = rot + sb;
            encryptedBytes = encryptedBytes .. (string.char(util.byteRotate(b, rot)));
        end
        builtin_pings[ping_name](key, encryptedBytes);
    end
end

setmetatable(encrypted_pings, encrypted_pings_metatable);