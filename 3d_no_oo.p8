pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- maths helpers and globals

eps = 0x0.0001
phiw = 1
phimax = phiw/2
phimin = -phimax
thetah = 1
thetamax = thetah/2
thetamin = -thetamax

movspd = 0.05
turnspd = 0.1

pi = 3.1415
pi2 = pi/2
twopi = 2*pi
inv2pi = 1/(pi*2)

_sin_builtin=sin
function sin(x)
	return -_sin_builtin(x*inv2pi)
end
_cos_builtin=cos
function cos(x)
	return _cos_builtin(x*inv2pi)
end

-- todo: can we replace all this with built-in atan2?
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

function calc_vec(v, m, fresh)
	if not fresh then
		v[m] = {
			(v[1]*cos(m.phi)+v[2]*sin(m.phi))*m.scale+m.disp[1],
			(v[2]*cos(m.phi)-v[1]*sin(m.phi))*m.scale+m.disp[2],
			(v[3]*m.scale)+m.disp[3],
		}
	end
	return v[m]
end

function draw_vec(vec)
	local x,y=get_sx(vec,true),get_sy(vec,true)
	rectfill(x-1,y-1,x+1,y+1,8) -- red
end

function tl_vec(v1,v2)
	v1[1]+=v2[1]
	v1[2]+=v2[2]
	v1[3]+=v2[3]
	v1._sx,v1._sy=nil,nil
end

function get_phi(v)
	local x=(v[1]-pov[1])*cos(pov.phi)-(v[2]-pov[2])*sin(pov.phi)
	local y=(v[2]-pov[2])*cos(pov.phi)+(v[1]-pov[1])*sin(pov.phi)
	if y>0 then
		return atan(x/y)
	else
		return (twopi+atan(x/y))*sgn(x)
	end
end

function get_theta(v)
	local x=(v[1]-pov[1])*cos(pov.phi)-(v[2]-pov[2])*sin(pov.phi)
	local y=(v[2]-pov[2])*cos(pov.phi)+(v[1]-pov[1])*sin(pov.phi)
	local z=v[3]-pov[3]
	return atan(z*invsqrt(x*x+y*y))
end

function get_sx(v, fresh)
	-- todo check self.y==0 etc
	if not fresh then
		v._sx=(get_phi(v)-phimin)*(128/phiw)
	end
	return v._sx
end

function get_sy(v, fresh)
	if not fresh then
		v._sy=(thetamax-get_theta(v))*128/thetah
	end
	return v._sy
end

-->8
-- model definition

function init_model(fs,vs,disp,scale,phi,col)
	add(models,{fs=fs,vs=vs,disp=disp,scale=scale,phi=phi,col=col})
end

function draw_model(m)
	local m_fresh = fresh and m.fresh
	for f in all(m.fs) do
		for i=1,#f do
			local v0=calc_vec(m.vs[f[i]],m,m_fresh)
			local v1=calc_vec(m.vs[f[i+1]] or m.vs[f[1]],m,m_fresh)
			line(get_sx(v0,m_fresh),get_sy(v0,m_fresh),get_sx(v1,m_fresh),get_sy(v1,m_fresh),m.col)
		end
	end
	m.fresh = true
	for v in all(m.vs) do
		draw_vec(calc_vec(v,m,true))
	end
end

cube_vs = {
	{0,0,0},
	{1,0,0},
	{1,1,0},
	{0,1,0},
	{0,0,1},
	{1,0,1},
	{1,1,1},
	{0,1,1},
}
cube_fs = {
	{1,2,3,4},
	{1,2,6,5},
	{1,4,8,5},
	{2,3,7,6},
	{3,4,8,7},
	{5,6,7,8},
}
function make_cube(disp,scale,phi,col)
	init_model(cube_fs,cube_vs,disp,scale,phi,col)
end

octa_vs = {
	{0,0,0},
	{1,0,1},
	{0,1,1},
	{-1,0,1},
	{0,-1,1},
	{0,0,2},
}
octa_fs = {
	{1,2,3},
	{1,3,4},
	{1,4,5},
	{1,5,2},
	{6,2,3},
	{6,3,4},
	{6,4,5},
	{6,5,2},
}
function make_octa(disp,scale,phi,col)
	init_model(octa_fs,octa_vs,disp,scale,phi,col)
end

tetra_vs = {
	{0,0,0},
	{2,0,0},
	{1,sqrt(3),0},
	{1,invsqrt(3),2*sqrt(2)*invsqrt(3)},
}
tetra_fs = {
	{1,2,3},
	{1,2,4},
	{1,3,4},
	{2,3,4},
}
function make_tetra(disp,scale,phi,col)
	init_model(tetra_fs,tetra_vs,disp,scale,phi,col)
end

-->8
-- top-level logic

function _init()
	pov={0,0,0,phi=0}
	models={}
	frame=0
	make_cube({-0.5,3,0.5},1,0.2,7)
	make_cube({0,4,-0.5},0.5,0,11)
	make_octa({-1,4,0},0.5,0,12)
	make_tetra({-1,2,-1},0.3,0,10)
end

function _update()
	frame+=eps

	-- move shapes
	models[1].disp[1]+=0.02*sgn(cos(frame*0x1000))
	models[1].phi+=0.05
	models[1].fresh=false

	models[3].phi-=0.03
	models[3].fresh=false

	models[4].scale=0.3+0.15*sin(frame*0x1000)
	models[4].fresh=false

	-- control pov
	fresh=true
	if btn(⬆️) then
		if btn(❎) then
			pov[3]+=movspd
		else
			pov[2]+=movspd*cos(pov.phi)
			pov[1]+=movspd*sin(pov.phi)
		end
		fresh=false
	end
	if btn(⬇️) then
		if btn(❎) then
			pov[3]-=movspd
		else
			pov[2]-=movspd*cos(pov.phi)
			pov[1]-=movspd*sin(pov.phi)
		end
		fresh=false
	end
	if btn(➡️) then
		if btn(❎) then -- strafe
			pov[1]+=movspd*cos(pov.phi)
			pov[2]-=movspd*sin(pov.phi)
		else -- turn
			pov.phi+=turnspd
		end
		fresh=false
	end
	if btn(⬅️) then
		if btn(❎) then -- strafe
			pov[1]-=movspd*cos(pov.phi)
			pov[2]+=movspd*sin(pov.phi)
		else -- turn
			pov.phi-=turnspd
		end
		fresh=false
	end
end

function _draw()
	cls()
	for m in all(models) do
		draw_model(m)
	end
	print('\#0cpu '..flr(stat(1)*100)..'% mem '..flr(stat(0)*100/2048)..'%',0,0,7)
end
