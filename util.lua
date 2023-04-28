--[[
    PingsEncrypt.
    Made by Lexize#0765
    Source: https://github.com/lexize/PingsEncrypt
]]
local util = {};

---@param ... integer
---@return ...integer
function util.hashFromSource(...)
    local bytes = table.pack(...);
    local w = {};
    local buffSize = math.ceil(#bytes / (4 * 32));
    for i = 1, buffSize * 16, 1 do
        local j = ((i-1) * 4)+1;
        local b1,b2,b3,b4 = bytes[j] or 0, bytes[j + 1] or 0, bytes[j + 2] or 0, bytes[j+3] or 0;
        local append = buffSize * 16 == i and 1 or 0;
        w[i] = b1 + bit32.lshift(b2, 8) + bit32.lshift(b3, 16) + bit32.lshift(b4, 24) + append;
    end
    for i = 1, (buffSize * 32), 1 do
        local i1 = (i)%(buffSize*32) + 1;
        local i2 = (i+13)%(buffSize*32) + 1;
        local i3 = (i+8)%(buffSize*32) + 1;
        local i4 = (i+15)%(buffSize*32) + 1;
        local w1 = w[i1];
        local a0 = bit32.bxor(bit32.rrotate(w1, 7), bit32.rrotate(w1, 18), bit32.rshift(w1, 3));
        local w14 = w[i2];
        local a1 = bit32.bxor(bit32.rrotate(w14, 17), bit32.rrotate(w14, 19), bit32.rshift(w14, 10));
        w[i4] = w[i] + a0 + w[i3] + a1;
    end
    local hT = {};
    hT[1] = bit32.bnot(w[1]);
    for i = 2, 8, 1 do
        hT[i] = bit32.bxor(w[i],hT[i-1]);
    end
    local k = {};
    k[1] = w[1];
    for i = 2, buffSize*32, 1 do
        k[i] = bit32.bnot(bit32.bxor(w[i],k[i-1]));
    end
    local a,b,c,d,e,f,g,h = hT[1],hT[2],hT[3],hT[4],hT[5],hT[6],hT[7],hT[8];
    for i = 1, buffSize * 32, 1 do
        local e0 = bit32.bxor(bit32.rrotate(a, 2),bit32.rrotate(a, 13), bit32.rrotate(a, 22));
        local e1 = bit32.bxor(bit32.rrotate(e, 6),bit32.rrotate(a, 11), bit32.rrotate(a, 25));
        local ch = bit32.bxor(bit32.band(e,f), bit32.band(bit32.bnot(e),g));
        local m = bit32.bxor(bit32.band(a,b),bit32.band(a,c), bit32.band(b,c));
        local t1 = h + e1 + ch + k[i] + w[i];
        local t2 = e0 + m;
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    end
    return a,b,c,d,e,f,g,h;
end

function util.numToBytes(num, bytesCount)
    local bits = {};
    for i = 1, (bytesCount*8), 1 do
        bits[#bits+1] = bit32.band(bit32.rshift(num, i-1), 1);
    end
    local bytes = {};
    for i = 0, math.ceil(#bits / 8)-1, 1 do
        local minIndex = (i * 8) + 1;
        local byte = 0;
        for j = 0, 7, 1 do
            byte = byte + bit32.lshift(bits[minIndex+j] or 0, j);
        end
        bytes[#bytes+1] = byte;
    end
    return table.unpack(bytes);
end

function util.numFromBytes(...)
    local bytes = {...};
    local bits = {};
    for _, byte in ipairs(bytes) do
        for i = 0, 7, 1 do
            bits[#bits+1] = bit32.band(bit32.rshift(byte, i),1)
        end
    end
    local num = 0;
    for i = 1, #bits, 1 do
        num = num + bit32.lshift(bits[i], i-1);
    end
    return num;
end

function util.byteRotate(byte, rot)
    local bits = {};
    for i = 0, 7, 1 do
        bits[i+1] = bit32.band(1, bit32.rshift(byte, i));
    end
    local finalByte = 0;
    for i = 0, 7, 1 do
        local bit = bits[((i+rot)%#bits)+1];
        finalByte = finalByte + (bit32.lshift(bit, i));
    end
    return finalByte;
end

function util.createFunctionKey(func)
    local metatable = {};
    function metatable:__index(k)
        if (k == "secret") then
            return func();
        end
    end
    function metatable:__newindex(k, v)
        if (k ~= "secret") then
            rawset(self, k, v);
        end
    end
    return setmetatable({}, metatable);
end

return setmetatable({}, {__index = util, __newindex = function ()
    
end});