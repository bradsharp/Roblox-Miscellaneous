local Spring = {}
Spring.__index = Spring

function Spring.new(ratio, frequency, value)	
	return setmetatable({
		
		-- Public
		Value = value,
		Target = value,
		Velocity = value * 0,
		
		-- Private
		_ratio = ratio,
		_frequency = frequency,
		
	}, Spring)
end

function Spring:AdjustFrequency(frequency)
	self._frequency = frequency
end

function Spring:Impulse(velocity)
	self.Velocity = self.Velocity + velocity
end

function Spring:Update(step)
	-- Short-circuit
	if step == 0 then
		return self.Value
	end
	-- Spring properties
	local p0, p1 = self.Value, self.Target
	local v0 = self.Velocity
	local d = self._ratio
	local f = self._frequency
	-- Derived spring properties
	local t = f * step
	local dd = d * d
	-- Damping values
	local a0, a1, a2
	local b0, b1, b2
	-- Damping
	if dd == 1 then
		-- Critical
		local epsilon = math.exp(-d * t)
		local cos, sin = epsilon, epsilon * t
		a0, a1, a2 = cos + d * sin, 1 - (cos + d * sin), sin / f
		b0, b1, b2 = -f * sin, f * sin, cos - d * sin
	elseif dd < 1 then
		-- Under
		local h = math.sqrt(1 - dd)
		local epsilon = math.exp(-d * t) / h
		local cos, sin = epsilon * math.cos(h * t), epsilon * math.sin(h * t)
		a0, a1, a2 = h * cos + d * sin, 1 - (h * cos + d * sin), sin / f
		b0, b1, b2 = -f * sin, f * sin, h * cos - d * sin
	else
		-- Over
		local h = math.sqrt(dd - 1)
		local u = math.exp((-d + h) * t)/(2 * h)
		local v = math.exp((-d - h) * t)/(2 * h)
		local cos, sin = u + v, u - v
		a0, a1, a2 = h * cos + d * sin, 1 - (h * cos + d * sin), sin / f
		b0, b1, b2 = -f * sin, f * sin, h * cos - d * sin
	end
	-- Updated spring properties
	local p = a0 * p0 + a1 * p1 + a2 * v0
	local v = b0 * p0 + b1 * p1 + b2 * v0
	self.Value = p
	self.Velocity = v
	return p, v
	
end

return Spring
