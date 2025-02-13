local beziers = {
	CubicBezier = function(t, p0, p1, p2, p3)
		return (1 - t) ^ 3 * p0 + 3 * (1 - t) ^ 2 * t * p1 + 3 * (1 - t) * t ^ 2 * p2 + t ^ 3 * p3
	end,

	QuadBezier = function(t, p0, p1, p2)
		return (1 - t) ^ 2 * p0 + 2 * (1 - t) * t * p1 + t ^ 2 * p2
	end,
}

local function createLUT(numSegments, bezierType, ...)
	local distSum = 0
	local sums = {}
	local step = 1 / numSegments
	for i = 0, 1, step do
		local firstPoint = if beziers[bezierType] then beziers[bezierType](i, ...) else beziers.CubicBezier(i, ...)
		local secondPoint = if beziers[bezierType]
			then beziers[bezierType](i + step, ...)
			else beziers.CubicBezier(i + step, ...)
		local dist = (secondPoint - firstPoint).Magnitude
		table.insert(sums, distSum)
		distSum += dist
	end
	return sums
end

local function remap(n, oldMin, oldMax, min, max)
	return (min + ((max - min) * ((n - oldMin) / (oldMax - oldMin))))
end

local Bezier = {}
Bezier.__index = Bezier

function Bezier.new(numSegments, bezierType, p0, p1, p2, p3)
	local self = setmetatable({}, Bezier)
	self._bezierType = bezierType
	self._points = { p0, p1, p2, p3 }
	self._distLUT = createLUT(numSegments, bezierType, p0, p1, p2, p3)

	return self
end

function Bezier:calc(t)
	local LUT = self._distLUT
	local arcLength = LUT[#LUT]
	if not arcLength then
		return
	end

	local targetDist = arcLength * t

	for i, dist in ipairs(LUT) do
		local nextDist = LUT[i + 1]
		if nextDist and targetDist >= dist and targetDist < nextDist then
			local adjustedT = remap(targetDist, dist, nextDist, i / #LUT, (i + 1) / #LUT)
			return if beziers[self._bezierType]
				then beziers[self._bezierType](adjustedT, unpack(self._points))
				else beziers.CubicBezier(adjustedT, unpack(self._points))
		end
	end
end

return Bezier
