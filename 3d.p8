pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- oo structuring

function ctor(self,o)
	for k,v in pairs(o) do
		self[k] = v or self[k]
	end
end

local obj = {init = ctor}
obj.__index = obj

function obj:__call(...)
	local o=setmetatable({},self)
	return o, o:init(...)
end

function obj:extend(proto)
	proto = proto or {}

	for k,v in pairs(self) do
		if sub(k,1,2) == '__' then
			proto[k] = v
		end
	end

	proto.__index = proto
	proto.__super = self

	return setmetatable(proto,self)
end

-->8
-- vector definition

vec = obj:extend{
	x=0,
	y=0,
	z=0,
}

-- allow positional initialisn
-- in addition to named params
function vec:init(o)
	self.x = o[1]
	self.y = o[2]
	self.z = o[3]
	self.__super.init(self,o)
end

function vec:__add(v)
	return vec{
	 x=self.x+v.x,
	 y=self.y+v.y,
	 z=self.z+v.z,
	}
end

function vec:__sub(v)
	return vec{
	 x=self.x-v.x,
	 y=self.y-v.y,
	 z=self.z-v.z,
	}
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
