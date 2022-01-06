pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- globals

frame=0

t1={x=40,y=90,r=20}
t2={x=80,y=40,r=20}

-->8
-- drawing routines

function draw_stripes(torch)
	rectfill(0,0,127,torch.y-torch.r,0)
	rectfill(0,127,127,torch.y+torch.r,0)
	for y=torch.y-torch.r+1,torch.y+torch.r-1 do
		local x=sqrt(torch.r*torch.r-(torch.y-y)*(torch.y-y))
		line(0,y,torch.x-x,y,0)
		line(127,y,torch.x+x,y,0)
	end
end

function draw_2_checkerboard(torch_a, torch_b)
	fillp()
	draw_stripes(torch_a)
	fillp()
	draw_stripes(torch_b)
	fillp()
end

function draw_alt_stripes(torch, startline)
	for y=startline,127,2 do
		if y<=torch.y-torch.r or y>=torch.y+torch.r then
			line(0,y,127,y,0)
		else
			local x=sqrt(torch.r*torch.r-(torch.y-y)*(torch.y-y))
			line(0,y,torch.x-x,y,0)
			line(127,y,torch.x+x,y,0)
		end
	end
end

function draw_2_alt_stripes(torch_a, torch_b)
	draw_alt_stripes(torch_a, 0)
	draw_alt_stripes(torch_b, 1)
end

-->8
-- top-level flow

function _init()
end

function _update()
	frame+=1
	if (btn(⬇️)) t1.y+=1
	if (btn(⬆️)) t1.y-=1
	if (btn(⬅️)) t1.x-=1
	if (btn(➡️)) t1.x+=1
	if btn(❎) then
		t1.r=max(t1.r-1,0)
	end
	if (btn(🅾️)) t1.r+=1
end

function _draw()
	cls(13)

	-- simplest fill for a single circle:
	-- draw_stripes(t1)

	-- fill two circles stripily:
	-- draw_2_alt_stripes(t1, t2)

	-- fill two circles with alternating stripes:
	-- if frame%20<10 then
	-- 	draw_2_alt_stripes(t1, t2)
	-- else
	-- 	draw_2_alt_stripes(t2, t1)
	-- end

	-- fill two circles with checkerboards
	draw_2_checkerboard(t1, t2)

	print('cpu '..flr(stat(1)*100)..'%',0,0,7)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
