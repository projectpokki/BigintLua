--[[
multiply by fft
* too much overhead, practically useless
* algorithm can be made faster by using other bases so less roots of unity are needed, like base 2^16 or 2^18
]]

local function fft(p, inverseFunction)
	local poly = table.clone(p)
	for i = 0, math.log(#p, 2) - 2 do
		local groupLength = #p / (2 ^ i)
		local even = {}
		local odd = {}
		for j = 2, #p, 2 do
			even[(((j-1)%groupLength)+1)/2] = poly[j-1]
			odd[(((j-1)%groupLength)+1)/2] = poly[j]

			if j % groupLength == 0 then
				table.move(even, 1, #even, j - groupLength + 1, poly)
				table.move(odd, 1, #odd, j - groupLength * 0.5 + 1, poly)
			end
		end
	end

	for i = 1, math.log(#p, 2) do
		local newPoly = {}
		for group = 1, #poly, 2 do
			local evenPoly = poly[group]
			local oddPoly = poly[group + 1]

			newPoly[(group + 1) / 2] = {}
			for j = 1, #p / #poly do
				local rootExp = (inverseFunction and math.pi * (1-j) / #p * #poly) or math.pi * (j-1) / #p * #poly
				local oddProductReal = math.cos(rootExp) * oddPoly[j][1] - math.sin(rootExp) * oddPoly[j][2]
				local oddProductImaginary =  math.cos(rootExp) * oddPoly[j][2] + math.sin(rootExp) * oddPoly[j][1]

				newPoly[(group + 1) / 2][j] = {evenPoly[j][1] + oddProductReal, evenPoly[j][2] + oddProductImaginary}
				newPoly[(group + 1) / 2][j + #p / #poly] = {evenPoly[j][1] - oddProductReal, evenPoly[j][2] - oddProductImaginary}
			end
		end
		poly = newPoly
	end
	return poly[1]
end

function Bigint.mulfft(poly1: {number}, poly2: {number}): {number}
	if #poly1 == 0 or #poly2 == 0 then
		return addmeta({})
	end
	
	local buffered1 = {}
	local buffered2 = {}
	local bufferedLength = 2 ^ math.ceil(math.log(#poly1 + #poly2 - 1, 2) + 1)
	for i = 1, bufferedLength do --convert base 2^24 to 2^12, increase fractional precision
		if i % 2 == 1 then
			buffered1[i] = (#poly1 >= (i+1)/2 and {{poly1[(i+1)/2] % 0x1000, 0}}) or {{0, 0}}
			buffered2[i] = (#poly2 >= (i+1)/2 and {{poly2[(i+1)/2] % 0x1000, 0}}) or {{0, 0}}
		else
			buffered1[i] = (#poly1 >= i/2 and {{poly1[i/2] // 0x1000, 0}}) or {{0, 0}}
			buffered2[i] = (#poly2 >= i/2 and {{poly2[i/2] // 0x1000, 0}}) or {{0, 0}}
		end
	end

	local a = fft(buffered1, false)
	local b = fft(buffered2, false)

	local c = {}
	for i = 1, bufferedLength do
		c[i] = {{a[i][1] * b[i][1] - a[i][2] * b[i][2], a[i][1] * b[i][2] + a[i][2] * b[i][1]}}
	end

	local out = fft(c, true)
	local output = {}
	local carry = 0
	for i = 1, #out, 2 do
		local sum = math.round(out[i+1][1] / bufferedLength) * 0x1000 + math.round(out[i][1] / bufferedLength) + carry
		output[#output + 1] = sum % 0x1000000
		carry = math.floor(sum * 5.960464477539063e-8)
		if math.abs(out[i][2]) > 0.1 then print("error", out[i][2]) end --#error catching
	end
	output[#output + 1] = carry

	return Bigint.strip(output)
end
