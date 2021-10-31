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
-- maths helpers and globals

phimin = -1
phimax = 1
phiw = phimax-phimin
pxw = 128
thetamin = -1
thetamax = 1
thetah = thetamax-thetamin
pxh = 128

pi = 3.1415
pi2 = pi/2
pi4 = pi/4

-- atan lookup table
_atlen = 64
_atres = 1/_atlen

-- 1/64 resolution
_at = {
  [0x0]=0x0.0000,
  [0x0.04]=0x0.0400,
  [0x0.08]=0x0.0800,
  [0x0.0c]=0x0.0bfe,
  [0x0.1]=0x0.0ffa,
  [0x0.14]=0x0.13f6,
  [0x0.18]=0x0.17ee,
  [0x0.1c]=0x0.1be4,
  [0x0.2]=0x0.1fd6,
  [0x0.24]=0x0.23c4,
  [0x0.28]=0x0.27ae,
  [0x0.2c]=0x0.2b94,
  [0x0.3]=0x0.2f72,
  [0x0.34]=0x0.334e,
  [0x0.38]=0x0.3722,
  [0x0.3c]=0x0.3af0,
  [0x0.4]=0x0.3eb6,
  [0x0.44]=0x0.4278,
  [0x0.48]=0x0.4630,
  [0x0.4c]=0x0.49e0,
  [0x0.5]=0x0.4d8a,
  [0x0.54]=0x0.512a,
  [0x0.58]=0x0.54c2,
  [0x0.5c]=0x0.5852,
  [0x0.6]=0x0.5bd8,
  [0x0.64]=0x0.5f56,
  [0x0.68]=0x0.62ca,
  [0x0.6c]=0x0.6634,
  [0x0.7]=0x0.6994,
  [0x0.74]=0x0.6cea,
  [0x0.78]=0x0.7036,
  [0x0.7c]=0x0.737a,
  [0x0.8]=0x0.76b2,
  [0x0.84]=0x0.79e0,
  [0x0.88]=0x0.7d04,
  [0x0.8c]=0x0.801c,
  [0x0.9]=0x0.832c,
  [0x0.94]=0x0.8630,
  [0x0.98]=0x0.892a,
  [0x0.9c]=0x0.8c1a,
  [0x0.a]=0x0.8f00,
  [0x0.a4]=0x0.91dc,
  [0x0.a8]=0x0.94ac,
  [0x0.ac]=0x0.9774,
  [0x0.b]=0x0.9a30,
  [0x0.b4]=0x0.9ce2,
  [0x0.b8]=0x0.9f8a,
  [0x0.bc]=0x0.a228,
  [0x0.c]=0x0.a4bc,
  [0x0.c4]=0x0.a746,
  [0x0.c8]=0x0.a9c8,
  [0x0.cc]=0x0.ac3e,
  [0x0.d]=0x0.aeac,
  [0x0.d4]=0x0.b110,
  [0x0.d8]=0x0.b36c,
  [0x0.dc]=0x0.b5bc,
  [0x0.e]=0x0.b806,
  [0x0.e4]=0x0.ba44,
  [0x0.e8]=0x0.bc7c,
  [0x0.ec]=0x0.beaa,
  [0x0.f]=0x0.c0ce,
  [0x0.f4]=0x0.c2ec,
  [0x0.f8]=0x0.c500,
  [0x0.fc]=0x0.c70c,
  [0x1]=0x0.c910,
  -- hack to get atan(1) w/o
  -- adding a branch:
  [0x1.04]=0x0.c910,
}

function atan(x)
  if x < 0 then
  	return -atan(-x)
  elseif x > 1 then
  	return pi2 - atan(1/x)
  else
  	local i = flr(x*_atlen)*_atres
  	local j = i+_atres
		return _at[i]+(x-i)*(_at[j]-_at[i])*_atres
	end
end

function invsqrt(x)
	-- todo: efficient. also x=0?
	return 1/sqrt(x)
end

-->8
-- vector definition

vec = obj:extend{
	x=0,
	y=0,
	z=0,
	_sx=nil,
	_sy=nil,
}

-- allow positional initialisn
-- in addition to named params
function vec:init(o)
	self.x = o[1]
	self.y = o[2]
	self.z = o[3]
	self.__super.init(self,o)
end

function vec:draw()
	local x = self:sx()
	local y = self:sy()
	rectfill(x-1,y-1,x+1,y+1,8)
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

-- translate: add in place
function vec:tl(v)
	self.x += v[1]
	self.y += v[2]
	self.z += v[3]
	-- clear cached screen pos
	self._sx,self._sy=nil,nil
end

function vec:phi()
  local x=self.x-pov.x
  local y=self.y-pov.y
	return atan(x/y)
end

function vec:theta()
	local x=self.x-pov.x
	local y=self.y-pov.y
	local x2=x*x
	local y2=y*y
	local z=self.z-pov.z
	return atan(z*invsqrt(x2+y2))
end

function vec:sx()
	-- todo check self.y==0 etc
	-- todo check if behind cam
	if not self._sx or not fresh then
		self._sx=(
		 self:phi()-phimin
		)*(pxw/phiw)
	end
	return self._sx
end

function vec:sy()
	if not self._sy or not fresh then
		self._sy = (
		 thetamax-self:theta()
		)*(pxh/thetah)
	end
	return self._sy
end

-->8
-- model definition

model = obj:extend{
--	vs={}, -- vertices
--	fs={}, -- faces
}

function model:init(o)
	for v in all(self.vs) do
		v.x=(v.x+o.d[1])*o.s
		v.y=(v.y+o.d[2])*o.s
		v.z=(v.z+o.d[3])*o.s
	end
end

function model:draw()
	for f in all(self.fs) do
		for i=1,#f do
			v0 = self.vs[f[i]]
			v1 = self.vs[f[i+1]] or self.vs[f[1]]
			line(
			 v0:sx(),
			 v0:sy(),
			 v1:sx(),
			 v1:sy(),
			 7
			)
		end
	end
	for v in all(self.vs) do
		v:draw()
	end
end

function model:tl(u)
	for v in all(self.vs) do
		v:tl(u)
	end
end

cube = model:extend{
	vs={
		vec{0,0,0},
		vec{1,0,0},
		vec{1,1,0},
		vec{0,1,0},
		vec{0,0,1},
		vec{1,0,1},
		vec{1,1,1},
		vec{0,1,1},
	},
	fs={
		{1,2,3,4},
		{1,2,6,5},
		{1,4,8,5},
		{2,3,7,6},
		{3,4,8,7},
		{5,6,7,8},
	},
}

-->8
-- top-level logic

models = {}
pov = nil
movspd = 0.02

function _init()
	pov = vec{0,0,0}
	add(models, cube{
		d={-0.5,1,0.5},
		s=1,
	})
end

function _update()
	if btn(⬆️) then
		pov:tl{0,movspd,0}
	end
	if btn(⬇️) then
		pov:tl{0,-movspd,0}
	end
	if btn(➡️) then
		pov:tl{movspd,0,0}
	end
	if btn(⬅️) then
		pov:tl{-movspd,0,0}
	end
	if btn(🅾️) then
		pov:tl{0,0,movspd}
	end
	if btn(❎) then
		pov:tl{0,0,-movspd}
	end
end

function _draw()
	cls()
	for m in all(models) do
		m:draw()
	end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
