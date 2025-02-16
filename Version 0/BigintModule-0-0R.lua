--[[
	ROBLOX LUA LIBRARY

	NOTES
	max number in lua to keep accuracy for integers is 2^53
	max power of 2 to square to under 2^53 is 2^24
	2^24 = 16777216 = 0x1000000
	
	value of bigint is stored in table of numbers
	formula of value is sum(table[i] * 2 ^ ((i - 1) * 24)), for i from 1 to table's length
	max value of table's elements is 2^24 - 1, min value is 0
]]

local Bigint = {}
local libVer = "0.0.0-ROBLOX_LUAU"

--INIT AND FORMAT

function Bigint.version()
	print("BIGINT LIBRARY VERSION "..libVer)
	return nil
end

function Bigint.zero()
	local output = {}
	setmetatable(output, {
		__tostring=Bigint.tohex,
		__lt=Bigint.less,
		__le=Bigint.lessequal,
		__eq=Bigint.equal,
		__add=Bigint.add,
		__sub=Bigint.sub,
		__mul=Bigint.mul,
		__div=Bigint.div,
		__mod=Bigint.mod,
		__pow=Bigint.power,
	})
	return output
end

function Bigint.new(value)
	local output = Bigint.zero()
	local rem = value
	while rem >= 0x1000000 do
		table.insert(output, rem % 0x1000000)
		rem = math.floor(rem * 5.960464477539063e-8) --bit32 caps value so cant be used
	end
	if rem > 0 then
		table.insert(output, rem)
	end
	return output
end

function Bigint.clone(BigintObject)
	local output = Bigint.zero()
	for _, i in ipairs(BigintObject) do
		table.insert(output, i)
	end
	return output
end

function Bigint.randdoubles(size)
	local output = Bigint.zero()
	local remDoubles = size
	for _ = 1, remDoubles do
		table.insert(output, math.random(0, 0xffffff))
	end
	return output
end

function Bigint.randbits(size)
	local output = Bigint.zero()
	local remBits = size
	while remBits > 24 do
		table.insert(output, math.random(0, 0xffffff))
		remBits -= 24
	end
	if remBits > 0 then
		table.insert(output, math.random(0, 2 ^ (remBits) - 1))
	end
	return output
end

function Bigint.strip(BigintObject)
	for i = #BigintObject, 1, -1 do
		if BigintObject[i] == 0 then
			table.remove(BigintObject, i)
		else
			break
		end
	end
	return BigintObject
end

--TYPE

function Bigint.tohex(BigintObject)
	local output = "0x"
	for i = #BigintObject, 1, -1 do
		output ..= string.format("%06x", BigintObject[i])
	end
	if string.len(output) == 2 then
		return "0x0"
	end
	return output
end

function Bigint.tohexf(BigintObject)
	if #BigintObject > 0 then
		local output = "0x"
		for i = #BigintObject, 2, -1 do
			output ..= string.format("%06x ", BigintObject[i])
		end
		return output .. string.format("%06x", BigintObject[1])
	else
		return "0x0"
	end
end

function Bigint.toint(BigintObject)
	if #BigintObject > 1 then
		return BigintObject[2] * 0x1000000 + BigintObject[1]
	elseif #BigintObject > 0 then
		return BigintObject[1]
	end
	return 0
end

function Bigint.tointstr(BigintObject)
	if #BigintObject == 0 then
		return "0"
	end
	
	local rem = BigintObject
	local output = ""
	while Bigint.greater(rem, Bigint.zero()) do
		local digit = Bigint.mod(rem, Bigint.new(10))
		output = tostring(Bigint.toint(digit)) .. output
		rem = Bigint.div(rem, Bigint.new(10))
	end
	return output
end

--EQUALITY

function Bigint.equal(a, b)
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

function Bigint.notequal(a, b)
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

function Bigint.less(a, b)
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

function Bigint.lessequal(a, b)
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

function Bigint.greater(a, b)
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

function Bigint.greaterequal(a, b)
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

--BITWISE

function Bigint.bitand(a, b)
	local output = Bigint.zero()
	for i = 1, math.min(#a, #b) do
		output[i] = bit32.band(a[i], b[i])
	end
	return Bigint.strip(output)
end

function Bigint.bitor(a, b)
	local output = Bigint.zero()
	for i = 1, math.max(#a, #b) do
		local value1 if a[i] then value1 = a[i] else value1 = 0 end
		local value2 if b[i] then value2 = b[i] else value2 = 0 end
		output[i] = bit32.bor(value1, value2)
	end
	return output
end

function Bigint.bitxor(a, b)
	local output = Bigint.zero()
	for i = 1, math.max(#a, #b) do
		local value1 if a[i] then value1 = a[i] else value1 = 0 end
		local value2 if b[i] then value2 = b[i] else value2 = 0 end
		output[i] = bit32.bxor(a[i], b[i])
	end
	return Bigint.strip(output)
end

function Bigint.lshiftdoubles(a, b)
	local output = Bigint.zero()
	for _ = 1, Bigint.toint(b) do
		table.insert(output, 0)
	end
	for _, i in ipairs(a) do
		table.insert(output, i)
	end
	return output
end

function Bigint.rshiftdoubles(a, b)
	local output = Bigint.zero()
	for i = Bigint.toint(b) + 1, #a do
		table.insert(output, a[i])
	end
	return output
end

function Bigint.lshiftbits(a, b) --REPLACE LATER
	if #b == 0 then
		return Bigint.clone(a)
	end
	return Bigint.mul(a, Bigint.new(2 ^ Bigint.toint(b)))
end

function Bigint.rshiftbits(a, b) --REPLACE LATER
	if #b == 0 then
		return Bigint.clone(a)
	end
	return Bigint.div(a, Bigint.new(2 ^ Bigint.toint(b)))
end

function Bigint.lendoubles(BigintObject)
	return Bigint.new(#BigintObject)
end

function Bigint.lenbits(BigintObject)
	if #BigintObject > 0 then
		local output = Bigint.new((#BigintObject - 1) * 24)
		
		local msd = BigintObject[#BigintObject]
		for i = 23, 0, -1 do
			if msd >= bit32.lshift(0x1, i) then
				output = Bigint.add(output, Bigint.new(i + 1))
				break
			end
		end
		return output
	else
		return Bigint.zero()
	end
end

--MATH

function Bigint.add(a, b)
	local output = Bigint.zero()
	local carry = 0
	local minLen = math.min(#a, #b)
	for i = 1, minLen do
		local sum = a[i] + b[i] + carry
		table.insert(output, sum % 0x1000000)
		carry = bit32.rshift(sum, 24)
	end
	
	if #a > #b then
		for i = minLen + 1, #a do
			local sum = a[i] + carry
			table.insert(output, sum % 0x1000000)
			carry = bit32.rshift(sum, 24)
		end
	elseif #a < #b then
		for i = minLen + 1, #b do
			local sum = b[i] + carry
			table.insert(output, sum % 0x1000000)
			carry = bit32.rshift(sum, 24)
		end
	end
	if carry > 0 then
		table.insert(output, carry)
	end
	
	return output
end

function Bigint.subabs(a, b)
	local output = Bigint.zero()
	local carry = 0
	if Bigint.less(a, b) then
		a, b = Bigint.clone(b), Bigint.clone(a)
	end
	
	for i = 1, #b do
		if a[i] < b[i] + carry then
			table.insert(output, a[i] - b[i] - carry + 0x1000000)
			carry = 1
		else
			table.insert(output, a[i] - b[i] - carry)
			carry = 0
		end
	end
	
	for i = #b + 1, #a do
		if a[i] < carry then
			table.insert(output, a[i] - carry + 0x1000000)
			carry = 1
		else
			table.insert(output, a[i] - carry)
			carry = 0
		end
	end
	return Bigint.strip(output)
end

function Bigint.sub(a, b)
	local output = Bigint.zero()
	if Bigint.greater(a, b) then
		local carry = 0
		for i = 1, #b do
			if a[i] < b[i] + carry then
				table.insert(output, a[i] - b[i] - carry + 0x1000000)
				carry = 1
			else
				table.insert(output, a[i] - b[i] - carry)
				carry = 0
			end
		end

		for i = #b + 1, #a do
			if a[i] < carry then
				table.insert(output, a[i] - carry + 0x1000000)
				carry = 1
			else
				table.insert(output, a[i] - carry)
				carry = 0
			end
		end
	end
	return Bigint.strip(output)
end

function Bigint.mul(a, b)
	local output = Bigint.zero()
	for n = 2, #a + #b do
		local coeff = Bigint.zero()
		for i = math.max(1, n - #b), math.min(n - 1, #a) do
			coeff = Bigint.add(coeff, Bigint.new(a[i] * b[n - i]))
		end
		output = Bigint.add(output, Bigint.lshiftdoubles(coeff, Bigint.new(n - 2)))
	end
	return output
end

function Bigint.div(a, b)
	local output = Bigint.zero()
	local rem = Bigint.clone(a)
	for i = Bigint.toint(Bigint.sub(Bigint.lenbits(a), Bigint.lenbits(b))), 0, -1 do
		if Bigint.greaterequal(rem, Bigint.lshiftbits(b, Bigint.new(i))) then
			rem = Bigint.sub(rem, Bigint.lshiftbits(b, Bigint.new(i)))
			output = Bigint.add(output, Bigint.lshiftbits(Bigint.new(1), Bigint.new(i)))
		end
	end
	return output
end

function Bigint.mod(a, b)
	local rem = Bigint.clone(a)
	for i = Bigint.toint(Bigint.sub(Bigint.lenbits(a), Bigint.lenbits(b))), 0, -1 do
		if Bigint.greaterequal(rem, Bigint.lshiftbits(b, Bigint.new(i))) then
			rem = Bigint.sub(rem, Bigint.lshiftbits(b, Bigint.new(i)))
		end
	end
	return rem
end

function Bigint.square(BigintObject)
	local output = Bigint.zero()
	for i = 1, #BigintObject - 1 do
		for j = i + 1, #BigintObject do
			output = Bigint.add(output, Bigint.lshiftdoubles(Bigint.new(BigintObject[i] * BigintObject[j]), Bigint.new(i+j-2)))
		end
	end
	output = Bigint.lshiftbits(output, Bigint.new(1))
	for i = 1, #BigintObject do
		output = Bigint.add(output, Bigint.lshiftdoubles(Bigint.new(BigintObject[i] * BigintObject[i]), Bigint.new(2*i-2)))
	end
	return output
end

function Bigint.power(a, b)
	if #b == 0 then
		return Bigint.new(1)
	elseif #b == 1 and b[1] == 1 then
		return Bigint.clone(a)
	elseif b[1] % 2 == 0 then
		return Bigint.square(Bigint.power(a, Bigint.rshiftbits(b, Bigint.new(1))))
	else
		return Bigint.mul(Bigint.square(Bigint.power(a, Bigint.rshiftbits(b, Bigint.new(1)))), a)
	end
end

function Bigint.sqrt(BigintObject)
	local upper = Bigint.lshiftbits(Bigint.new(1), Bigint.rshiftbits(Bigint.add(Bigint.lenbits(BigintObject), Bigint.new(1)), Bigint.new(1)))
	local lower = Bigint.lshiftbits(Bigint.new(1), Bigint.rshiftbits(Bigint.sub(Bigint.lenbits(BigintObject), Bigint.new(1)), Bigint.new(1)))
	while Bigint.greater(Bigint.sub(upper, lower), Bigint.new(1)) do
		local guess = Bigint.rshiftbits(Bigint.add(upper, lower), Bigint.new(1))
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

function Bigint.root(a, b)
	if #b == 0 then
		return Bigint.new(1)
	end
	if Bigint.equal(b, Bigint.new(1)) then
		return Bigint.clone(a)
	end
	
	local upper = Bigint.lshiftbits(Bigint.new(1), Bigint.div(Bigint.sub(Bigint.add(Bigint.lenbits(a), b), Bigint.new(1)), b))
	local lower = Bigint.lshiftbits(Bigint.new(1), Bigint.div(Bigint.sub(Bigint.lenbits(a), Bigint.new(1)), b))
	while Bigint.greater(Bigint.sub(upper, lower), Bigint.new(1)) do
		local guess = Bigint.rshiftbits(Bigint.add(upper, lower), Bigint.new(1))
		local guessPow = Bigint.power(guess, b)
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

function Bigint.log2(BigintObject)
	if #BigintObject == 0 then
		return nil
	else
		return Bigint.sub(Bigint.lenbits(BigintObject), Bigint.new(1))
	end
end

function Bigint.log(a, b)
	if #a == 0 or #b == 0 or Bigint.equal(b, Bigint.new(1)) then
		return nil
	end
	if Bigint.less(a, b) then
		return Bigint.zero()
	end
	
	local lower = Bigint.div(Bigint.sub(Bigint.lenbits(a), Bigint.new(1)), Bigint.lenbits(b))
	local upper = Bigint.add(Bigint.div(Bigint.lenbits(a), Bigint.sub(Bigint.lenbits(b), Bigint.new(1))), Bigint.new(1))
	while Bigint.greater(Bigint.sub(upper, lower), Bigint.new(1)) do
		local guess = Bigint.rshiftbits(Bigint.add(upper, lower), Bigint.new(1))
		local bPow = Bigint.power(b, guess)
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

function Bigint.fact(a)
	local output = Bigint.new(1)
	for i = 2, Bigint.toint(a) do
		output = Bigint.mul(output, Bigint.new(i))
	end
	return output
end

function Bigint.nPr(n, r)
	if Bigint.less(n, r) then
		return Bigint.zero()
	end
	local output = Bigint.new(1)
	for i = Bigint.toint(n) - Bigint.toint(r) + 1, Bigint.toint(n) do
		output = Bigint.mul(output, Bigint.new(i))
	end
	return output
end

function Bigint.nCr(n, r)
	if Bigint.less(n, r) then
		return Bigint.zero()
	end
	
	if Bigint.greater(Bigint.sub(n, r), r) then
		r = Bigint.sub(n, r)
	end
	local top = Bigint.new(1)
	local bottom = Bigint.new(1)
	for i = Bigint.toint(r) + 1, Bigint.toint(n) do
		top = Bigint.mul(top, Bigint.new(i))
		bottom = Bigint.mul(bottom, Bigint.sub(n, Bigint.new(i - 1)))
	end
	return Bigint.div(top, bottom)
end

return Bigint
