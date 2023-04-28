--[[
    PingsEncrypt.
    Made by Lexize#0765
    Source: https://github.com/lexize/PingsEncrypt
]]
local stream = {}

---@class ByteStream
local byteStream = {};

---@return integer|nil
function byteStream:read()
    local pos = self.__pos;
    local b = self.__source[pos+1];
    if (b ~= nil) then self.__pos = pos + 1; end
    return b;
end

function byteStream:reset()
    self.__pos = 0;
end

local byteStreamMetatable = {};

function byteStreamMetatable:__index(k)
    return byteStream[k]
end

---@param ... ... Source
---@return ByteStream
function stream.createByteStream(...)
    local stream = {};
    stream.__source = {...};
    stream.__pos = 0;
    return setmetatable(stream, byteStreamMetatable);
end

return setmetatable({}, {__index = stream, __newindex = function ()
    
end});