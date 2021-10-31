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
-- main logic

-- actors
pc = nil
npcs = {}

local actor = obj:extend{
	sprage=0,
	x=scrnrt,
	y=0,
	dx=0,
	dy=0,
	w=8,
	h=8,
}

function actor:draw()
	self.sprage += 1
	self.sprage %= maxage
	local frame=
	 self.sprage%#self.sprites
	spr(
	 self.sprites[frame+1],
	 self.x,
	 self.y
	)
end

function actor:update()
	--todo:out-of-sync actors look
	--bad (moving alt. frames)
	self.x += self.dx
	self.y += self.dy
end

local block = actor:extend{
  name='blk',
  w=3,
  clr=12,
}
function block:draw()
	rectfill(
	 self.x,
	 self.y,
	 self.x+self.w-1,
	 self.y+self.h-1,
	 self.clr
	)
end

local lvlline = block:extend{
	name='lvl',
	y=scrntp,
	w=2,
	h=scrnbt-scrntp,
	clr=14,
	lvl=1,
	hit=false,
}

local spike = actor:extend{
	name='spk',
	sprites={4},
	w=7,
	h=7,
}

local flower = actor:extend{
	name='flw',
	sprites={5},
	juice=80,
	depleted=false,
}
function flower:draw()
	self.__super.draw(self)
	rectfill(
	 self.x,
	 self.y+9,
	 self.x+16*self.juice/80,
	 self.y+11,
	 self.depleted and 8 or 11
	)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
