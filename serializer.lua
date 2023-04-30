--[[
    PingsEncrypt.
    Made by Lexize#0765
    Source: https://github.com/lexize/PingsEncrypt
]]

local path = ...;
local util = require(#path > 0 and path..".util" or "util");
require(#path > 0 and path..".stream" or "stream");

local serializer = {};

local types = {
    NIL = 0, -- IMPLEMENTED
    BOOL_FALSE = 1, -- IMPLEMENTED
    BOOL_TRUE = 2, -- IMPLEMENTED
    NINT_8 = 3, -- IMPLEMENTED
    NINT_16 = 4, -- IMPLEMENTED
    NINT_32 = 5, -- IMPLEMENTED
    PINT_8 = 7, -- IMPLEMENTED
    PINT_16 = 8, -- IMPLEMENTED
    PINT_32 = 9, -- IMPLEMENTED
    DOUBLE = 11, -- IMPLEMENTED

    STRING = 12, -- IMPLEMENTED
    LIST = 13, -- IMPLEMENTED
    TABLE = 14, -- IMPLEMENTED
    VEC_2 = 16, -- IMPLEMENTED
    VEC_3 = 17, -- IMPLEMENTED
    VEC_4 = 18, -- IMPLEMENTED
    MAT_2 = 19, -- IMPLEMENTED
    MAT_3 = 20, -- IMPLEMENTED
    MAT_4 = 21, -- IMPLEMENTED

    EMPTY_TABLE = 15, -- IMPLEMENTED
    ZERO_VEC_2 = 22, -- IMPLEMENTED
    ZERO_VEC_3 = 23, -- IMPLEMENTED
    ZERO_VEC_4 = 24, -- IMPLEMENTED
    ZERO_MAT_2 = 25, -- IMPLEMENTED
    ZERO_MAT_3 = 26, -- IMPLEMENTED
    ZERO_MAT_4 = 27, -- IMPLEMENTED

    END = 255 -- HELPER TAG
}
-- I took these three functions from idk where but they saved me and my sanity
local function grab_byte(v)
    return math.floor(v / 256), string.char(math.floor(v) % 256)
end

local function doubleToBytes(x)
    local sign = 0
    if x < 0 then 
       sign = 1; 
       x = -x 
    end
    local mantissa, exponent = math.frexp(x)
    if x == 0 then -- zero
       mantissa, exponent = 0, 0
    else
       mantissa = (mantissa * 2 - 1) * 4503599627370496 -- math.ldexp(0.5, 53)
       exponent = exponent + 1022
    end
    local v, byte = "" -- convert to bytes
    x = mantissa
    for i = 1,6 do
       x, byte = grab_byte(x); v = v..byte -- 47:0
    end
    x, byte = grab_byte(exponent * 16 + x); v = v..byte -- 55:48
    x, byte = grab_byte(sign * 128 + x); v = v..byte -- 63:56
    return string.byte(v, 1, #v);
end

local function bytesToDouble(x)
    local sign = 1
    local mantissa = string.byte(x, 7) % 16
    for i = 6, 1, -1 do 
       mantissa = mantissa * 256 + string.byte(x, i)
    end
    if string.byte(x, 8) > 127 then
       sign = -1
    end
    local exponent = (string.byte(x, 8) % 128) * 16 + math.floor(string.byte(x, 7) / 16)
    if exponent == 0 then 
       return 0 
    end
    mantissa = (math.ldexp(mantissa, -52) + 1) * sign
    return math.ldexp(mantissa, exponent - 1023)
end

local integerRangesToBytes = {
    {0, (2^8)-1, types.PINT_8, 1},
    {0, (2^16)-1, types.PINT_16, 2},
    {0, (2^32)-1, types.PINT_32, 4},

    {1-(2^8),  0, types.NINT_8, -1},
    {1-(2^16), 0, types.NINT_16, -2},
    {1-(2^32), 0, types.NINT_32, -4},
}
local serializationFunc = {};

function serializationFunc.number(val)
    if (val % 1 == 0) then
        for _, rng in ipairs(integerRangesToBytes) do
            if val >= rng[1] and val <= rng[2] then
                return rng[3], util.numToBytes(math.abs(val), math.abs(rng[4]));
            end
        end
    end
    return types.DOUBLE, doubleToBytes(val);
end

serializationFunc["nil"] = function ()
    return types.NIL;
end

---@param v boolean
---@return integer
function serializationFunc.boolean(v)
    return v and types.BOOL_TRUE or types.BOOL_FALSE
end

---@param tbl table
---@return ...integer
function serializationFunc.table(tbl)
    if (#tbl == 0) then
        local kvs = {};
        for key, value in pairs(tbl) do
            kvs[#kvs+1] = {key, value};
        end
        if (#kvs == 0) then
            return types.EMPTY_TABLE;
        end
        local out = "";
        for _, kv in pairs(kvs) do
            out = out .. serializer.serialize(kv[1], kv[2]);
        end
        out = out .. string.char(types.END);
        return types.TABLE, string.byte(out, 1, #out);
    else
        local out = "";
        for _, v in ipairs(tbl) do
            out = out .. serializer.serialize(v);
        end
        out = out .. string.char(types.END);
        return types.LIST, string.byte(out, 1, #out);
    end
end

function serializationFunc.string(str)
    local out = string.char(util.numToBytes(#str, 2)) .. str;
    return types.STRING, string.byte(out, 1, #out);
end

local function vecSerializationMethod(vec)
    local l = #vec;
    local o = "";
    local allNulls = true;
    for i = 1, l, 1 do
        local n = vec[i];
        if (allNulls and n ~= 0) then
            allNulls = false;
        end
        o = o .. string.char(doubleToBytes(n));
    end
    if (allNulls) then
        return types["ZERO_VEC_"..tostring(l)];
    end
    local t = types["VEC_"..tostring(l)];
    return t, string.byte(o, 1, #o);
end

local function matSerializationMethod(mat)
    local l = #mat;
    local o = "";
    local allNulls = true;
    for c = 1, l, 1 do
        local col = mat[tostring(c)];
        for r = 1, l, 1 do
            local n = vec[i];
            if (allNulls and n ~= 0) then
                allNulls = false;
            end
            o = o .. string.char(doubleToBytes(vec[i]));
        end
    end
    if (allNulls) then
        return types["ZERO_MAT_"..tostring(l)];
    end
    local t = types["MAT_"..tostring(l)];
    return t, string.byte(o, 1, #o);
end

for i = 2, 4, 1 do
    serializationFunc["Vector"..tostring(i)] = vecSerializationMethod;
    serializationFunc["Matrix"..tostring(i)] = matSerializationMethod;
end

function serializer.serialize(...)
    local output = "";
    local sources = {...};
    for _, value in ipairs(sources) do
        local t = type(value);
        local f = serializationFunc[t];
        local a = nil;
        if (f == nil) then
            a = string.char(types.NIL);
        else
            a = string.char(f(value));
        end
        output = output..a;
    end
    return output;
end

local deserializationFuncs = {
    [types.NIL] = function ()
        return nil;
    end,
    [types.BOOL_FALSE] = function ()
        return false;
    end,
    [types.BOOL_TRUE] = function ()
        return true;
    end,
    [types.EMPTY_TABLE] = function ()
        return {}
    end,
    [types.ZERO_VEC_2] = function ()
        return vec(0,0)
    end,
    [types.ZERO_VEC_3] = function ()
        return vec(0,0,0)
    end,
    [types.ZERO_VEC_4] = function ()
        return vec(0,0,0,0)
    end,
    [types.ZERO_MAT_2] = function ()
        return matrices.mat2(vec(0,0),vec(0,0))
    end,
    [types.ZERO_MAT_3] = function ()
        return matrices.mat3(vec(0,0,0),vec(0,0,0),vec(0,0,0))
    end,
    [types.ZERO_MAT_4] = function ()
        return matrices.mat4(vec(0,0,0,0),vec(0,0,0,0),vec(0,0,0,0),vec(0,0,0,0));
    end
}

local function des(typ)
    local f = deserializationFuncs[typ];
    if (f ~= nil) then return f end;
    error("Unexpected data type id: "..typ);
end

local function bytesToNum(stream, fmt)
    local size = fmt;
    local s = "";
    local sign = size < 0 and -1 or 1;
    for i = 1, math.abs(size), 1 do
        s = s .. string.char(stream:read());
    end
    return sign*util.numFromBytes(string.byte(s, 1, #s));
end

for _, rng in ipairs(integerRangesToBytes) do
    deserializationFuncs[rng[3]] = function (stream)
        return bytesToNum(stream, rng[4]);
    end
end

---@param stream ByteStream
---@return number
deserializationFuncs[types.DOUBLE] = function(stream)
    local size = 8;
    local s = "";
    for i = 1, size, 1 do
        s = s .. string.char(stream:read());
    end
    return bytesToDouble(s);
end

---@param stream ByteStream
---@return table
deserializationFuncs[types.LIST] = function (stream)
    local t = {};
    local i = stream:read();
    while (i ~= nil and i ~= types.END) do
        local val = des(i)(stream);
        t[#t+1] = val;
        i = stream:read();
    end
    return t;
end
---@param stream any
---@return string
deserializationFuncs[types.STRING] = function (stream)
    local length = util.numFromBytes(stream:read(), stream:read());
    local out = "";
    for i = 1, length do
        local c = stream:read();
        out = out .. string.char(c);
    end
    return out;
end
---@param stream ByteStream
---@return table
deserializationFuncs[types.TABLE] = function (stream)
    local t = {};
    local i = stream:read();
    local k = nil;
    while (not (i == nil or i == types.END)) do
        local v = des(i)(stream);
        if (k ~= nil) then
            t[k] = v;
            k = nil;
        else
            k = v;
        end
        i = stream:read();
    end
    return t;
end

local function deserializeMat(matLen)
    return function (stream)
        local cols = {};
        local sz = 8;
        for c = 1, matLen, 1 do
            local nums = {};
            for v = 1, matLen, 1 do
                local s = "";
                for i = 1, sz, 1 do
                    s = s .. string.char(stream:read())
                end
                nums[#nums+1] = bytesToDouble(s);
            end
            cols[#cols+1] = vec(table.unpack(nums));
        end
        return matrices["mat"..tostring(matLen)](table.unpack(cols));
    end
end

local function deserializeVec(vecLen)
    return function (stream)
        local sz = 8;
        local nums = {};
        for v = 1, vecLen, 1 do
            local s = "";
            for i = 1, sz, 1 do
                s = s .. string.char(stream:read())
            end
            nums[#nums+1] = bytesToDouble(s);
        end
        return vec(table.unpack(nums));
    end
end

for i = 2, 4, 1 do
    deserializationFuncs[types["VEC_"..tostring(i)]] = deserializeVec(i);
    deserializationFuncs[types["MAT_"..tostring(i)]] = deserializeMat(i);
end

---@param stream ByteStream
---@return any
function serializer.deserialize(stream)
    local returnValues = {};
    local i = stream:read();
    while (i ~= nil) do
        local f = deserializationFuncs[i];
        if (f ~= nil) then
            returnValues[#returnValues+1] = f(stream);
        else
            error("Unexpected data type id: "..i);
        end
        i = stream:read();
    end
    return table.unpack(returnValues);
end

return setmetatable({}, {__index = serializer, __newindex = function ()
    
end});