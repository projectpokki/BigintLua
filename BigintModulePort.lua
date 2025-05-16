--[[
+--------------------------------------------------------------------------------+
|                                                                                |
| Standalone lua implementation of a big integer library                         |
|                                                                                |
+--------------------------------------------------------------------------------+
|                                                                                |
| Copyright (c) 2024 Pok Man Chiang                                              |
|                                                                                |
| Permission is hereby granted, free of charge, to any person obtaining a copy   |
| of this software and associated documentation files (the "Software"), to deal  |
| in the Software without restriction, including without limitation the rights   |
| to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      |
| copies of the Software, and to permit persons to whom the Software is          |
| furnished to do so, subject to the following conditions:                       |
|                                                                                |
| The above copyright notice and this permission notice shall be included in all |
| copies or substantial portions of the Software.                                |
|                                                                                |
| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     |
| IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       |
| FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    |
| AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         |
| LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  |
| OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  |
| SOFTWARE.                                                                      |
|                                                                                |
+--------------------------------------------------------------------------------+
]]

local Bigint = {}
local libVer = "1.0-STANDALONE"
local libDate = "16/2/2025"
local outputMode = 1 --0 = tohex, 1 = tohexf, 2 = tointstr

local function outputError(func, inputs, message)
	for i = 1, #inputs do
		if typeof(inputs[i]) == "string" then
			inputs[i] = "\"" .. inputs[i] .. "\""
		end
	end
	local formattedInputs = table.concat(inputs, ", ")
	error("Error near Bigint function \"" .. func .. "()\" | inputs: {".. formattedInputs .. "} | " .. message)
end

local function forceToStr(tab)
	if outputMode == 0 then
		return Bigint.tohex(tab)
	elseif outputMode == 1 then
		return Bigint.tohexf(tab)
	else
		return Bigint.tointstr(tab)
	end
end

local function intToBigint(value)
	if value > 0x1000000 then
		return {value % 0x1000000, math.floor(value * 5.960464477539063e-8)}
	else
		return {value}
	end
end

local function addmeta(tab)
	setmetatable(tab, {
		__tostring=forceToStr,
		__lt=Bigint.less,
		__le=Bigint.lessequal,
		__eq=Bigint.equal,
		__add=Bigint.add,
		__sub=Bigint.sub,
		__mul=Bigint.mul,
		__idiv=Bigint.idiv,
		__div=Bigint.fdiv,
		__mod=Bigint.mod,
		__pow=Bigint.pow,
		__band=Bigint.bitand,
		__bor=Bigint.bitor,
		__bxor=Bigint.bitxor,
		__shl=Bigint.lshiftbits,
		__shr=Bigint.rshiftbits
	})
	return tab
end

--INIT AND FORMAT

function Bigint.version(): string
	print("BIGINT MODULE VERSION "..libVer.." ("..libDate..")")
	return nil
end

function Bigint.setOutputMode(mode: string): boolean
	local modeNum = -1
	if mode == "hex" then
		modeNum = 0
	elseif mode == "hexf" then
		modeNum = 1
	elseif mode == "intstr" then
		modeNum = 2
	end
	
	if modeNum == -1 then
		outputError("setOutputMode", {mode}, "malformed input; input must be \"hex\", \"hexf\" or \"intstr\"")
	end
	
	if outputMode == modeNum then
		return false
	end
	outputMode = modeNum
	return true
end

function Bigint.new(value: number | string): {number}
	local inputStr = tostring(value)
	local isHex = string.len(inputStr) > 2 and string.sub(inputStr, 1, 2) == "0x"
	
	local output = {}
	if isHex then
		local hexStr = string.sub(inputStr, 3)
		local strLen = string.len(hexStr)
		for i = 1, strLen // 6 do
			local double = tonumber(string.sub(hexStr, strLen - (i-1) * 6 - 5, strLen - (i-1) * 6), 16)
			if double == nil then
				outputError("new", {inputStr}, "malformed input")
			end
			output[i] = double
		end
		if strLen % 6 > 0 then
			local firstPart = tonumber(string.sub(hexStr, 1, string.len(hexStr) % 6), 16)
			if firstPart == nil then
				outputError("new", {inputStr}, "malformed input")
			end
			output[#output + 1] = firstPart
		end
	else
		local decStr = inputStr
		for i = 1, string.len(decStr) do
			local digit = tonumber(string.sub(decStr, i, i), 10)
			if digit == nil then
				outputError("new", {inputStr}, "malformed input")
			end
			output = Bigint.add(Bigint.mul(output, {10}), {digit})
		end
	end
	return Bigint.strip(output)
end

function Bigint.clone(BigintObject: {number}): {number}
	local output = {}
	for i, j in ipairs(BigintObject) do
		output[i] = j
	end
	return addmeta(output)
end

function Bigint.randdoubles(size: number): {number}
	local output = {}
	for i = 1, math.floor(size) do
		output[i] = math.random(0, 0xffffff)
	end
	return addmeta(output)
end

function Bigint.randbits(size: number): {number}
	local output = {}
	local remBits = math.floor(size)
	while remBits > 24 do
		table.insert(output, math.random(0, 0xffffff))
		remBits -= 24
	end
	if remBits > 0 then
		table.insert(output, math.random(0, 2 ^ (remBits) - 1))
	end
	return addmeta(output)
end

function Bigint.strip(BigintObject: {number}): {number}
	local copy = Bigint.clone(BigintObject)
	for i = #copy, 1, -1 do
		if copy[i] ~= 0 then
			break
		end
		copy[i] = nil
	end
	return addmeta(copy)
end

--TYPE

function Bigint.tohex(BigintObject: {number}): string
	if #BigintObject == 0 then
		return "0x0"
	end
	
	local output = "0x"
	for i = #BigintObject, 1, -1 do
		output ..= string.format("%06x", BigintObject[i])
	end
	return output
end

function Bigint.tohexf(BigintObject: {number}): string
	if #BigintObject == 0 then
		return "0x0"
	end
	
	local output = "0x"
	for i = #BigintObject, 2, -1 do
		output ..= string.format("%06x ", BigintObject[i])
	end
	return output .. string.format("%06x", BigintObject[1])
end

function Bigint.tonumber(BigintObject: {number}): number
	if #BigintObject > 2 then
		return BigintObject[3] * 0x1000000000000 + BigintObject[2] * 0x1000000 + BigintObject[1]
	elseif #BigintObject > 1 then
		return BigintObject[2] * 0x1000000 + BigintObject[1]
	elseif #BigintObject > 0 then
		return BigintObject[1]
	end
	return 0
end

function Bigint.tointstr(BigintObject: {number}): string
	if #BigintObject == 0 then
		return "0"
	end
	
	local rem = Bigint.clone(BigintObject)
	local output = ""
	while Bigint.greater(rem, {}) do
		local digit = Bigint.mod(rem, {10})[1]
		if digit == nil then
			output = "0" .. output
		else
			output = tostring(digit) .. output
		end
		rem = Bigint.idiv(rem, {10})
	end
	return output
end

--EQUALITY

function Bigint.equal(a: {number}, b: {number}): boolean
	if #a ~= #b then
		return false
	end
	for i = #a, 1, -1 do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

function Bigint.notequal(a: {number}, b: {number}): boolean
	if #a ~= #b then
		return true
	end
	for i = #a, 1, -1 do
		if a[i] ~= b[i] then
			return true
		end
	end
	return false
end

function Bigint.less(a: {number}, b: {number}): boolean
	if #a ~= #b then
		return #a < #b
	end
	for i = #a, 1, -1 do
		if a[i] ~= b[i] then
			return a[i] < b[i]
		end
	end
	return false
end

function Bigint.lessequal(a: {number}, b: {number}): boolean
	if #a ~= #b then
		return #a < #b
	end
	for i = #a, 1, -1 do
		if a[i] ~= b[i] then
			return a[i] < b[i]
		end
	end
	return true
end

function Bigint.greater(a: {number}, b: {number}): boolean
	if #a ~= #b then
		return #a > #b
	end
	for i = #a, 1, -1 do
		if a[i] ~= b[i] then
			return a[i] > b[i]
		end
	end
	return false
end

function Bigint.greaterequal(a: {number}, b: {number}): boolean
	if #a ~= #b then
		return #a > #b
	end
	for i = #a, 1, -1 do
		if a[i] ~= b[i] then
			return a[i] > b[i]
		end
	end
	return true
end

function Bigint.max(a: {number}, b: {number}): {number}
	if Bigint.greaterequal(a, b) then
		return Bigint.clone(a)
	end
	return Bigint.clone(b)
end

function Bigint.min(a: {number}, b: {number}): {number}
	if Bigint.greaterequal(a, b) then
		return Bigint.clone(b)
	end
	return Bigint.clone(a)
end

--BITWISE

function Bigint.bitand(a: {number}, b: {number}): {number}
	local output = {}
	for i = 1, math.min(#a, #b) do
		output[i] = a[i] & b[i]
	end
	return Bigint.strip(output) --strip already adds meta so no need
end

function Bigint.bitor(a: {number}, b: {number}): {number}
	local output = {}
	for i = 1, math.max(#a, #b) do
		local value1 if a[i] then value1 = a[i] else value1 = 0 end
		local value2 if b[i] then value2 = b[i] else value2 = 0 end
		output[i] = value1 | value2
	end
	return addmeta(output)
end

function Bigint.bitxor(a: {number}, b: {number}): {number}
	local output = {}
	for i = 1, math.max(#a, #b) do
		local value1 if a[i] then value1 = a[i] else value1 = 0 end
		local value2 if b[i] then value2 = b[i] else value2 = 0 end
		output[i] = a[i] ~ b[i]
	end
	return Bigint.strip(output)
end

function Bigint.lshiftdoubles(a: {number}, b: number): {number}
	if b == 0 then
		return Bigint.clone(a)
	end
	
	local output = {}
	for i = 1, math.floor(b) do
		output[i] = 0
	end
	for _, i in ipairs(a) do
		output[#output + 1] = i
	end
	return addmeta(output)
end

function Bigint.rshiftdoubles(a: {number}, b: number): {number}
	if b == 0 then
		return Bigint.clone(a)
	end
	
	local output = {}
	for i = math.floor(b) + 1, #a do
		output[#output + 1] = a[i]
	end
	return addmeta(output)
end

function Bigint.lshiftbits(a: {number}, b: number): {number}
	if b == 0 then
		return Bigint.clone(a)
	end
	
	local output = {}
	local remshifts = math.floor(b)
	for i = 1, remshifts // 24 do
		output[i] = 0
	end
	local carry = 0
	local remshifts = remshifts % 24
	for _, i in ipairs(a) do
		local double = i * 2 ^ remshifts + carry
		output[#output + 1] = double % 0x1000000
		carry = math.floor(double * 5.960464477539063e-8)
	end
	if carry > 0 then
		output[#output + 1] = carry
	end
	return addmeta(output)
end

function Bigint.rshiftbits(a: {number}, b: number): {number}
	if b == 0 then
		return Bigint.clone(a)
	end
	
	local dshifted = {}
	for i = math.floor(b) // 24 + 1, #a do
		dshifted[#dshifted + 1] = a[i]
	end
	local remshifts = math.floor(b) % 24
	local reversed = {}
	local carry = 0
	for i = #dshifted, 1, -1 do
		local double = dshifted[i] + carry * 0x1000000
		local bitAtRemshifts = 2 ^ remshifts
		reversed[#reversed + 1] = double // bitAtRemshifts
		carry = double % bitAtRemshifts
	end
	local output = {}
	for i = #reversed, 1, -1 do
		output[#output + 1] = reversed[i]
	end
	while output[#output] == 0 do
		output[#output] = nil
	end
	return addmeta(output)
end

function Bigint.lendoubles(BigintObject: {number}): {number}
	return addmeta({#BigintObject})
end

function Bigint.lenbits(BigintObject: {number}): {number}
	if #BigintObject == 0 then
		return addmeta({})
	end
	
	local biggestDouble = BigintObject[#BigintObject]
	return intToBigint(math.floor(math.log(biggestDouble, 2)) + 1 + 24 * (#BigintObject - 1))
	
	
	--if #BigintObject == 0 then
	--	return addmeta({})
	--end
	
	--local doubleCount = (#BigintObject - 1) * 24
	--local msd = BigintObject[#BigintObject]
	--for i = 23, 0, -1 do
	--	if msd >= (2 ^ i) then
	--		return addmeta({doubleCount + msd})
	--	end
	--end
	--return addmeta({doubleCount}) --input not stripped
end

--BASIC MATH

function Bigint.add(a: {number}, b: {number}): {number}
	local output = {}
	local carry = 0
	local minLen = math.min(#a, #b)
	for i = 1, minLen do
		local sum = a[i] + b[i] + carry
		output[i] = sum % 0x1000000
		carry = math.floor(sum * 5.960464477539063e-8)
	end
	
	if #a > #b then
		for i = minLen + 1, #a do
			local sum = a[i] + carry
			output[#output + 1] = sum % 0x1000000
			carry = math.floor(sum * 5.960464477539063e-8)
		end
	elseif #a < #b then
		for i = minLen + 1, #b do
			local sum = b[i] + carry
			output[#output + 1] = sum % 0x1000000
			carry = math.floor(sum * 5.960464477539063e-8)
		end
	end
	if carry > 0 then
		output[#output + 1] = carry
	end
	
	return addmeta(output)
end

function Bigint.subabs(a: {number}, b: {number}): {number}
	local output = {}
	local carry = 0
	
	local bigger
	local smaller
	if Bigint.greater(a, b) then
		bigger, smaller = a, b
	else
		bigger, smaller = b, a
	end
	
	for i = 1, #b do
		if bigger[i] < smaller[i] + carry then
			table.insert(output, bigger[i] - smaller[i] - carry + 0x1000000)
			carry = 1
		else
			table.insert(output, bigger[i] - smaller[i] - carry)
			carry = 0
		end
	end
	
	for i = #smaller + 1, #bigger do
		if bigger[i] < carry then
			table.insert(output, bigger[i] - carry + 0x1000000)
			carry = 1
		else
			table.insert(output, bigger[i] - carry)
			carry = 0
		end
	end
	return Bigint.strip(output)
end

function Bigint.sub(a: {number}, b: {number}): {number}
	if Bigint.lessequal(a, b) then
		return addmeta({})
	end
	
	local output = {}
	local carry = 0
	for i = 1, #b do
		if a[i] < b[i] + carry then
			output[i] = a[i] - b[i] - carry + 0x1000000
			carry = 1
		else
			output[i] = a[i] - b[i] - carry
			carry = 0
		end
	end

	for i = #b + 1, #a do
		if a[i] < carry then
			output[#output + 1] = a[i] - carry + 0x1000000
			carry = 1
		else
			output[#output + 1] = a[i] - carry
			carry = 0
		end
	end
	return Bigint.strip(output)
end

function Bigint.mul(a: {number}, b: {number}): {number} --REPLACE WITH KARATSUBA
	local output = {}
	for n = 2, #a + #b do
		local coeff = {}
		for i = math.max(1, n - #b), math.min(n - 1, #a) do
			coeff = Bigint.add(coeff, intToBigint(a[i] * b[n - i]))
		end
		output = Bigint.add(output, Bigint.lshiftdoubles(coeff, n - 2))
	end
	return addmeta(output)
end

function Bigint.idiv(a: {number}, b: {number}): {number}
	if #b == 0 then
		outputError("idiv", {Bigint.tohexf(a), Bigint.tohexf(b)}, "division by 0")
	end	
	
	local rem = Bigint.clone(a)
	local output = {}
	
	for ind = Bigint.tonumber(Bigint.sub(Bigint.lenbits(a), Bigint.lenbits(b))), 0, -1 do
		local shiftedDenom = Bigint.lshiftbits(b, ind)
		if Bigint.greaterequal(rem, shiftedDenom) then
			rem = Bigint.sub(rem, shiftedDenom)
			output = Bigint.add(output, Bigint.lshiftbits({1}, ind))
		end
	end
	return addmeta(output)
end

function Bigint.fdiv(a: {number}, b: {number}): number
	if #b == 0 then
		outputError("fdiv", {Bigint.tohexf(a), Bigint.tohexf(b)}, "division by 0")
	end
	
	local lenA = Bigint.tonumber(Bigint.lenbits(a))
	local lenB = Bigint.tonumber(Bigint.lenbits(b))
	
	if lenA - lenB > 72 then
		return math.huge
	elseif lenB - lenA > 72 then
		return 0
	end
	
	local maxBits = math.max(lenA, lenB)
	local shiftAmount = maxBits - 72
	local shiftedA = Bigint.tonumber(Bigint.rshiftbits(a, shiftAmount))
	local shiftedB = Bigint.tonumber(Bigint.rshiftbits(b, shiftAmount))
	return shiftedA / shiftedB
end

function Bigint.mod(a: {number}, b: {number}): {number}
	if #b == 0 then
		outputError("mod", {Bigint.tohexf(a), Bigint.tohexf(b)}, "modulo by 0")
	end
	
	local rem = Bigint.clone(a)
	for i = Bigint.tonumber(Bigint.sub(Bigint.lenbits(a), Bigint.lenbits(b))), 0, -1 do
		if Bigint.greaterequal(rem, Bigint.lshiftbits(b, i)) then
			rem = Bigint.sub(rem, Bigint.lshiftbits(b, i))
		end
	end
	return rem --no need for add meta because clone already added it at start
end

function Bigint.square(BigintObject: {number}): {number}
	local output = {}
	for i = 1, #BigintObject - 1 do
		for j = i + 1, #BigintObject do
			output = Bigint.add(output, Bigint.lshiftdoubles(intToBigint(BigintObject[i] * BigintObject[j]), i+j-2))
		end
	end
	output = Bigint.lshiftbits(output, 1)
	for i = 1, #BigintObject do
		output = Bigint.add(output, Bigint.lshiftdoubles(intToBigint(BigintObject[i] * BigintObject[i]), 2*i-2))
	end
	return addmeta(output)
end

function Bigint.gcd(a: {number}, b: {number}): {number}
	if #a == 0 or #b == 0 then
		outputError("gcd", {Bigint.tohexf(a), Bigint.tohexf(b)}, "domain error")
	end
	
	local val1 = Bigint.clone(a)
	local val2 = Bigint.clone(b)
	
	while true do
		if Bigint.greater(val1, val2) then
			val1 = Bigint.mod(val1, val2)
			if #val1 == 0 then
				return val2
			end
		else
			val2 = Bigint.mod(val2, val1)
			if #val2 == 0 then
				return val1
			end
		end
	end
end

function Bigint.lcm(a: {number}, b: {number}): {number}
	if #a == 0 or #b == 0 then
		outputError("lcm", {Bigint.tohexf(a), Bigint.tohexf(b)}, "domain error")
	end
	
	return Bigint.idiv(Bigint.mul(a, b), Bigint.gcd(a, b))
end

--BIG MATH

function Bigint.pow(a: {number}, b: {number}): {number}
	if #b == 0 then --0^0=1 because IEEE
		return addmeta({1})
	elseif #a == 0 then
		return addmeta({})
	end

	local remexp = Bigint.clone(b)
	local output = {1}
	local base = Bigint.clone(a)
	while #remexp > 0 do
		if remexp[1] % 2 == 1 then
			output = Bigint.mul(output, base)
		end
		base = Bigint.square(base)
		remexp = Bigint.rshiftbits(remexp, 1)
	end
	return addmeta(output)
end

function Bigint.powmod(base: {number}, exp: {number}, m: {number}): {number}
	if #m == 0 then
		outputError("powmod", {Bigint.tohexf(base), Bigint.tohexf(exp), Bigint.tohexf(m)}, "modulo by 0")
	elseif #m == 1 and m[1] == 1 then
		return addmeta({})
	elseif #exp == 0 then
		return addmeta({1})
	elseif #base == 0 then
		return addmeta({})
	end
	
	local remexp = Bigint.clone(exp)
	local output = {1}
	local bmod = Bigint.mod(base, m)
	while #remexp > 0 do
		if remexp[1] % 2 == 1 then
			output = Bigint.mod(Bigint.mul(output, bmod), m)
		end
		bmod = Bigint.mod(Bigint.square(bmod), m)
		remexp = Bigint.rshiftbits(remexp, 1)
	end
	return addmeta(output)
end

function Bigint.sqrt(BigintObject: {number}): {number}
	if #BigintObject == 0 then
		return addmeta({})
	end
	
	local upper = Bigint.lshiftbits({1}, Bigint.tonumber(Bigint.rshiftbits(Bigint.add(Bigint.lenbits(BigintObject), {1}), 1)))
	local lower = Bigint.lshiftbits({1}, Bigint.tonumber(Bigint.rshiftbits(Bigint.sub(Bigint.lenbits(BigintObject), {1}), 1)))
	while Bigint.greater(Bigint.sub(upper, lower), {1}) do
		local guess = Bigint.rshiftbits(Bigint.add(upper, lower), 1)
		if Bigint.equal(Bigint.square(guess), BigintObject) then
			return guess
		elseif Bigint.less(Bigint.square(guess), BigintObject) then
			lower = guess
		else
			upper = guess
		end
	end
	return lower
end

function Bigint.root(a: {number}, b: {number}): {number}
	if #b == 0 then
		return addmeta({1})
	elseif #a == 0 then
		return addmeta({})
	elseif #b == 1 and b[1] == 1 then
		return Bigint.clone(a)
	end
	
	local upper = Bigint.lshiftbits({1}, Bigint.tonumber(Bigint.idiv(Bigint.sub(Bigint.add(Bigint.lenbits(a), b), {1}), b)))
	local lower = Bigint.lshiftbits({1}, Bigint.tonumber(Bigint.idiv(Bigint.sub(Bigint.lenbits(a), {1}), b)))
	while Bigint.greater(Bigint.sub(upper, lower), {1}) do
		local guess = Bigint.rshiftbits(Bigint.add(upper, lower), 1)
		local guessPow = Bigint.pow(guess, b)
		if Bigint.equal(guessPow, a) then
			return guess
		elseif Bigint.less(guessPow, a) then
			lower = guess
		else
			upper = guess
		end
	end
	return lower
end

function Bigint.log2(BigintObject: {number}): {number}
	if #BigintObject == 0 then
		outputError("log2", {Bigint.tohexf(BigintObject)}, "domain error")
	end
	return Bigint.sub(Bigint.lenbits(BigintObject), {1})
end

function Bigint.log(a: {number}, b: {number}): {number}
	if #a == 0 or #b == 0 or (#b == 1 and b[1] == 1) then
		outputError("log", {Bigint.tohexf(a), Bigint.tohexf(b)}, "domain error")
	elseif Bigint.less(a, b) then
		return addmeta({})
	elseif Bigint.equal(a, b) then
		return addmeta({1})
	end

	local lower = Bigint.idiv(Bigint.sub(Bigint.lenbits(a), {1}), Bigint.lenbits(b))
	local upper = Bigint.add(Bigint.idiv(Bigint.lenbits(a), Bigint.sub(Bigint.lenbits(b), {1})), {1})
	while Bigint.greater(Bigint.sub(upper, lower), {1}) do
		local guess = Bigint.rshiftbits(Bigint.add(upper, lower), 1)
		local bPow = Bigint.pow(b, guess)
		if Bigint.equal(bPow, a) then
			return guess
		elseif Bigint.less(bPow, a) then
			lower = guess
		else
			upper = guess
		end
	end
	return lower
end

function Bigint.fact(a: {number}): {number}
	local output = {1}
	for i = 2, Bigint.tonumber(a) do
		output = Bigint.mul(output, intToBigint(i))
	end
	return addmeta(output)
end

function Bigint.nPr(n: {number}, r: {number}): {number}
	if Bigint.less(n, r) then
		return addmeta({})
	end
	local output = {1}
	for i = Bigint.tonumber(n) - Bigint.tonumber(r) + 1, Bigint.tonumber(n) do
		output = Bigint.mul(output, intToBigint(i))
	end
	return addmeta(output)
end

function Bigint.nCr(n: {number}, r: {number}): {number}
	if Bigint.less(n, r) then
		return addmeta({})
	end
	return Bigint.idiv(Bigint.nPr(n, r), Bigint.fact(r))
end

return Bigint
