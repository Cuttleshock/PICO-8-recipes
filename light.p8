pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- globals

frame=0
shadow_col=0

bunny_base={
	spr=17,
	w=6,
	h=8,
}

bat_base={
	spr=18,
	w=8,
	h=8,
}

CHECKERBOARD=0b1010010110100101
ANTI_CHECKERBOARD=(~CHECKERBOARD)&0xffff
TORCH_OFF=0xffff
coprime_16={3,5,7,9,11,13,15} -- don't include 1

actors={}
torches={}

interactable=nil

-->8
-- non-drawing functions

-- deterministic and reversible if we want
function permute_16b(bf,n)
	local ret=0
	for i=0,15 do
		local bit=(bf>>i)&1
		ret=ret|bit<<(n*i%16)
	end
	return ret
end

-- swap two bits selected by index
function swap_16b(bf,a,b)
	local bit_a=(bf>>a)&1
	local bit_b=(bf>>b)&1
	if (bit_a!=bit_b) bf=bf^^(1<<a|1<<b)
	return bf
end

-- i hear there's a more efficient way of doing this
function count_16b(bf)
	local ret=0
	for i=0,15 do
		if ((1<<i)&bf!=0) ret+=1
	end
	return ret
end

function rotl_16b(bf, n)
	n=n%16
	return (bf<<n)|(bf>>>(16-n))&TORCH_OFF
end

-- ignores overlap between torches
function take_torch(dest, src)
	dest.bitfield=dest.bitfield&src.bitfield
	src.bitfield=TORCH_OFF
end

-- ignores overlap between torches
function share_torch(src, dest)
	local destmask=TORCH_OFF
	local bits_shared=0
	local bits_unshared=0
	local bits_total=count_16b(~src.bitfield)
	for i=0,15 do
		if (~src.bitfield)&(1<<i)!=0 then
			if bits_unshared>=bits_total/2 or rnd(1)<0.5 then
				destmask=destmask&~(1<<i)
				bits_shared+=1
			else
				bits_unshared+=1
			end
		end
		if (bits_shared>=bits_total/2) break
	end
	dest.bitfield=dest.bitfield&destmask
	src.bitfield=(src.bitfield^^(~destmask))&TORCH_OFF
end

function find_interactable_torch(player)
	for t in all(torches) do
		if (t!=player and abs(t.x-player.x)<=8 and abs(t.y-player.y)<=8) return t
	end
end

-->8
-- drawing routines

function add_actor(base,x,y)
	add(actors,{ base=base, x=x, y=y })
end

function add_torch(x,y,r,bitfield)
	add(torches, { x=x, y=y, r=r, bitfield=bitfield })
end

function draw_actors()
	for a in all(actors) do
		spr(a.base.spr,a.x,a.y)
	end
end

-- draw entire actor if it has any overlap with a light source
function draw_actors_discrete()
	for a in all(actors) do
		for t in all(torches) do
			if t.bitfield==TORCH_OFF or a.x>t.x+t.r or a.x+a.base.w<=t.x-t.r or a.y>t.y+t.r or a.y+a.base.h<=t.y-t.r then
				-- totally outside range, save calculation
			else
				local check_x,check_y
				if a.x>=t.x then
					check_x=a.x
				elseif a.x+a.base.w<=t.x then
					check_x=a.x+a.base.w
				else
					check_x=t.x
				end
				if a.y>=t.y then
					check_y=a.y
				elseif a.y+a.base.h<=t.y then
					check_y=a.y+a.base.h
				else
					check_y=t.y
				end
				if (t.x-check_x)*(t.x-check_x)+(t.y-check_y)*(t.y-check_y)<=t.r*t.r then
					spr(a.base.spr,a.x,a.y)
					break
				end
			end
		end
	end
end

function draw_torches()
	for t in all(torches) do
		if t.bitfield==TORCH_OFF then
			spr(33,t.x-4,t.y-4)
		else
			spr(34,t.x-4,t.y-4)
		end
	end
end

-- simplest fill for a single circle
function draw_plain_stripes(torch, col)
	rectfill(0,0,127,torch.y-torch.r,col)
	rectfill(0,127,127,torch.y+torch.r,col)
	for y=torch.y-torch.r+1,torch.y+torch.r-1 do
		local x=sqrt(torch.r*torch.r-(torch.y-y)*(torch.y-y))
		line(0,y,torch.x-x,y,col)
		line(127,y,torch.x+x,y,col)
	end
end

-- fill one circle with greyscale map
function draw_map_stripes(torch)
	-- greyscale - taken from PICO docs
	pal({1,1,5,5,5,6,7,13,6,7,7,6,13,6,7,1})
	for y=0,127 do
		if y<=torch.y-torch.r or y>=torch.y+torch.r then
			tline(0,y,127,y,0,y*0.125)
		else
			local x=sqrt(torch.r*torch.r-(torch.y-y)*(torch.y-y))
			tline(0,y,torch.x-x,y,0,y*0.125)
			tline(torch.x+x,y,127,y,(torch.x+x)*0.125,y*0.125)
		end
	end
	pal()
end

-- fill two circles with checkerboards
function draw_shared_checkerboard(col)
	for t in all(torches) do
		fillp(t.bitfield|0b0.1)
		draw_plain_stripes(t, col)
	end
	fillp()
end

function draw_plain_stripes_partial(torch,col,n)
	local in_circle=false
	for y=4*n,4*n+3 do
		if y<=torch.y-torch.r or y>=torch.y+torch.r then
			line(0,y,127,y,col)
		else
			local x=sqrt(torch.r*torch.r-(torch.y-y)*(torch.y-y))
			line(0,y,torch.x-x,y,col)
			line(127,y,torch.x+x,y,col)
		end
	end
end

-- with a fixed seed, change fillp every 4 lines
function draw_shuffled_checkerboard(col)
	for n=0,31 do
		local seed=rnd(coprime_16)
		for t in all(torches) do
			if t.bitfield!=TORCH_OFF then
				fillp(permute_16b(t.bitfield,seed)|0b0.1)
				draw_plain_stripes_partial(t,col,n)
			end
		end
	end
	fillp()
end

function draw_alt_stripes(torch, startline, col)
	for y=startline,127,2 do
		if y<=torch.y-torch.r or y>=torch.y+torch.r then
			line(0,y,127,y,col)
		else
			local x=sqrt(torch.r*torch.r-(torch.y-y)*(torch.y-y))
			line(0,y,torch.x-x,y,col)
			line(127,y,torch.x+x,y,col)
		end
	end
end

-- fill two circles stripily
function draw_2_alt_stripes(torch_a, torch_b, col)
	draw_alt_stripes(torch_a, 0, col)
	draw_alt_stripes(torch_b, 1, col)
end

-->8
-- top-level flow

function _init()
	add_actor(bunny_base,16,43)
	add_actor(bunny_base,80,27)
	add_actor(bunny_base,50,115)
	add_actor(bunny_base,60,115)
	add_actor(bat_base,40,24)
	add_actor(bat_base,104,80)
	add_actor(bat_base,64,88)
	add_actor(bat_base,100,108)

	add_torch(40,90,20,0b1111001111110011)
	add_torch(80,40,20,0b0011111100111111)
	add_torch(30,30,15,0b1110111011101110)
	add_torch(75,85,25,0b1101110111011101)
	add_torch(60,64,128,TORCH_OFF)
	add_torch(5,40,0,TORCH_OFF)
	add_torch(5,55,0,TORCH_OFF)
	add_torch(5,70,0,TORCH_OFF)
end

function _update()
	frame+=1

	if frame%20==0 then
		local seed=rnd(coprime_16)
		local a,b=flr(rnd(15)),flr(rnd(15))
		for t in all(torches) do
			t.bitfield=swap_16b(t.bitfield,a,b)
		end
	end

	if interactable then
		if btnp(❎) then
			if interactable.bitfield!=TORCH_OFF then
				take_torch(torches[1],interactable)
			else
				share_torch(torches[1],interactable)
			end
		end
	end

	if (btn(⬇️)) torches[1].y+=1
	if (btn(⬆️)) torches[1].y-=1
	if (btn(⬅️)) torches[1].x-=1
	if (btn(➡️)) torches[1].x+=1

	interactable=find_interactable_torch(torches[1])
end

function _draw()
	map()
	srand(frame\20)
	draw_shuffled_checkerboard(shadow_col)
	draw_actors_discrete()
	draw_torches()
	if interactable then
		if interactable.bitfield!=TORCH_OFF then
			print('\#0❎ take',interactable.x-14,interactable.y-10,7)
		else
			print('\#0❎ share',interactable.x-14,interactable.y-10,7)
		end
	end

	print('\#0cpu '..flr(stat(1)*100)..'%',0,0,7)
end

__gfx__
0000000033333333333333333333333333333333bbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbb33333333bbbbbbbb0000000000000000000000000000000000000000
0000000033a333333b333b333338833333333333bbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbb33333333bbbbbbbb0000000000000000000000000000000000000000
007007003aaa3333333b33333388883333333333bbbbbbbbbbbbb333bbbbbbbb3bbbbbbb33333333bbbbbbbb0000000000000000000000000000000000000000
0007700033a333333b33333333888833bb333bbbbbbbbbbbbbb33333bbbbbbbb3333bbbb33333333bbbbbbbb0000000000000000000000000000000000000000
00077000333333333333b33333888833bbbbbbbb33bbb333bb333333bbbbbbbb33333333333333bbbbbbbbbb0000000000000000000000000000000000000000
007007003333333333b3333b33388333bbbbbbbb333333333333333333bbbbbb333333333333bbbbbbbbbbbb0000000000000000000000000000000000000000
00000000333333333333333333333333bbbbbbbb33333333333333333333bbbb33333333333bbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000333333333333b33333333333bbbbbbbb3333333333333333333333bb333333333bbbbbbbbbbbbbbb0000000000000000000000000000000000000000
000000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ee0eee01000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000eee0001100001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001e10001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000eee0001119191100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000e00000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000eee0000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ee0ee000010010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000a098000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000011000089aa88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111000089990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000110000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0505050505050505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202030202020209040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202090404040a050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040a05050506020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050601010202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020101010202020203020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020302020202020201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020302020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020203020203020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
