pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--amika's quest
--by tyler, cory and te


function init_lists()
	--load lists to populate shops, etc.
	directions,coin,drop_list={'s','n','e','w'},{true,false},{1,1,1,1,1,1,2}
	moblists={{1,2},{3,4},{1,2,3,4}}
	shoplists={{3,5,3},{3,4,3},{6,6,6}}
	gamestate,counter,world="play",0,1
--world=1
end
function _init()
	solid,lock=0,1

	--load data
	--create arrays of room templates
	rooms,keyrooms=split(rooms),split(keyrooms)
	
	init_lists()	
	gamestate="menu"
	camx,camy,t=0,0,0
	dungeon={}
	player_setup()
	camx_target,camy_target=camx,camy
	--change default transparent color to light green
	palt(0,false)
	palt(11,true)
	
	music(3)
end

function _update()
	if gamestate=="menu" then
		update_menu()
	elseif gamestate=="restart" then
		--restart, place player in a new dungeon
		init_lists()
		world=1
		counter+=1
		map_gen(world)
		player_setup()
		place_player(first_room())
		mobs_setup()
		camx_target,camy_target=camx,camy
		gamestate,t="play",0
	elseif gamestate=="dead" then
	--game over screen
		if btn(❎) then
		 gamestate="restart"
			music(3)
		end
	elseif gamestate=="end" then
		--game complete screen
		counter+=1
		world=1
		if (counter>10) p.dx,p.dy=0,0
		if btn(❎) and counter>70 then
		 music(3)
		 gamestate="restart"
		end
	elseif gamestate=="nextlevel" then
		--level transition
		if counter==30 then	
			world+=1
			change_pallete(world)
			map_gen(world)
			--player_setup()
			place_player(first_room())
			camx_target,camy_target=camx,camy
		end
		counter+=1
		if counter==40 then
			if world==2 then
				music(10)
			else
				music(0)
			end
			gamestate,counter="play",0
		end
	elseif gamestate=="play" or gamestate=="debug" then
		--game play
		--pause menu
		if p.items[1]==nil then
			menuitem(1,"🅾️ item: ",item_select)
		else
			menuitem(1,"🅾️ item: "..item_library[p.items[p.item]].name,item_select)
		end
		menuitem(2,"quick restart",quick_restart)
	
		--timer
		t+=1
		
		update_player()
		update_map()
		camera_handler()
		camera(camx,camy)
		
		roomx,roomy=roomxy(value_index(player_room()))
		--check monster collisions
		for m in all(mobs) do
			if (m.room==player_room()) m:update()
			if m.hp<1 then
			 del(mobs,m)	
				add_drop(rnd(drop_list),m.x,m.y)
			end	
		end
		--check boss collisions
		for b in all(boss) do
		 	if (dungeon[b.room]==player_room()) b:update()
				if (b.hp<1) del(boss,b)		
		end
		--check item collisions
		for i in all(items) do
			i:update()
			for m in all(mobs) do
				if check_ebe_collision(i.x,i.y,m.x,m.y) then
					if m.state~="hurt" then
						i:hit(m)
						sfx(44)
					end	
				end
			end
			for b in all(boss) do
				if check_ebe_collision(i.x,i.y,b.x,b.y,8,b.l) then
					if (b.state~="hurt") i:hit(b)
				end
			end
		end
		
		--check pickup collisions
		for c in all(pickups) do
				c:update()
				if check_ebe_collision(c.x,c.y,p.x,p.y) and not c.hidden then
					if (c.timer>15) c:pickup(m)
				end
				for i in all(items) do
					if check_ebe_collision(c.x,c.y,i.x,i.y) and not c.hidden then
					if (c.timer>15) c:pickup(m)
				end
				end
		end
	end
end

function _draw()
	
	if gamestate~="menu" then
		--clear screen, draw map
		cls()
		map(0,0,0,0,128,64)
		
		--draw pickups
		for c in all(pickups) do
				c:draw()
		end
		
		--draw items	
		for i in all(items) do
			i:draw()
			spr(i.sprite,i.x,i.y,1,1,i.flipx,i.flipy)
		end
		
		draw_player()
		--draw monsters
		for m in all(mobs) do
			if m.state=="stun" then
				--change pallete if stunned
				fillp(ˇ\3000|0b.011)
			end
			m:draw()
			fillp()
		end
		
		--draw boss monsters
		for b in all(boss) do
			if b.state=="stun" then
				fillp(ˇ\3000|0b.011)
			end
			b:draw()
			--🐱
			--print(m.room,m.x+8,m.y+8,8)	
			fillp()
		end
		
		--draw hud
		rectfill(camx,camy,camx+(16*8), camy+16,0)
		draw_minimap()
		draw_health()
		
		print("k",camx+36,camy+10,10)
		print(p.keys,camx+40,camy+10,7)
		
		print("◆",camx+44,camy+10,9)	
		print(p.coins,camx+51,camy+10,7)
		
		draw_item()
		draw_timer()
		color(7)
	----text---
	
	if gamestate=="dead" then
		stroke_text("game over",camx+42,camy+40,7,0)
		stroke_text("press ❎ to restart",camx+24,camy+50,7,0)
	elseif gamestate=="end" then
		stroke_text("game complete",camx+37,camy+40,7,0)
		if  counter>60 then
		 stroke_text("press ❎ to restart",camx+26,camy+50,7,0)
		end
	elseif gamestate=="nextlevel" or gamestate=="restart" then
		if counter<40 then	
			cls(0)
		end
	end
end
end
-->8
--map code

function update_map()
	--handle key room, boss room
	if sub(player_room(),1,1)=='k' 
	and p.state=="control" 
	and monsters_in_room(player_room())
	then	
		--if player enters key room, block exit
		for d in all(directions) do
				set_barrier(value_index(player_room()),d)
		end
	end

	if player_room()==final_room() 
	and p.state=="control" 
then	
		--if player enters boss room, block exit
		for d in all(directions) do
			set_barrier(value_index(player_room()),d)
		end
		
		if boss[1]==nil then
		--if boss dies, open door or end game
				if world==1 or world==2 then
					set_door(value_index(player_room()),'n')
						music(-1,300)
						sfx(41)
				elseif world==3 then
				 gamestate,counter="end",0
				 music(3)
				end
		end
	end
	--add current room to explored rooms list
	if (not is_in_list(explored,player_room())) add(explored,player_room())

end


--locks and doors--
function unlock()
	replace_tiles(value_index(player_room()),4,5)	
	sfx(41)
	p.keys-=1
end

function replace_tiles(index,sprite,new_sprite)
	for x=0,16 do
		for y=0,14	do
			local s=get_tile_in_room(roomx,roomy,x,y)
			if (s==sprite) set_tile_in_room(index,x,y,new_sprite)
		end
	end
end



--items--
pickups={}
function place_key(room,x,y)
	--place key, hide it until room is cleared
	local k={}
	k.x,k.y=coord_in_room(room,x,y)
	k.room=dungeon[room]
	k.hidden,k.timer=true,0
	k.draw=function(self)
		if (not k.hidden) spr(16,k.x,k.y,1,1)
	end
	k.update=function(self)
		local monsters=false
		if (monsters_in_room(self.room)) monsters=true
		if (not monsters) k.hidden=false
		if (not k.hidden) k.timer+=1
	end
	k.pickup=function(self)
		if not self.hidden then
			p.keys+=1
			sfx(2)
			del(pickups,self)
			sfx(41)
			for d in all(directions) do
				unset_barrier(value_index(self.room),d)
			end
		end
	end
	add(pickups,k)
end


function add_drop(typ,x,y)
		--for coins and hearts dropped by enemies
		--and shop items
		local d={
		x=x,
		y=y,
		sprite=typ+18,
		timer=0,
		update=pu_library[typ].update,
		draw=pu_library[typ].draw,
		pickup=pu_library[typ].pickup
		}
		add(pickups,d)
end

function set_shop_mobs(world)
--select correct items and monsters for current world
	moblist,shoplist=moblists[world],shoplists[world]
end


pu_library={}

pu_library[1]={
	--coin--
	draw=function(self)
		spr(19,self.x,self.y,1,1)
	end,
	pickup=function(self)
		p.coins+=1
		sfx(2)
		del(pickups,self)
	end,
	update=function(self)
			if (self.timer<20) self.timer+=1
	end,
}

pu_library[2]={
	--heart--
	draw=function(self)
		spr(20,self.x,self.y,1,1)
	end,
	pickup=function(self)
		if (p.hp<p.maxhp) p.hp+=1
		sfx(3)
		del(pickups,self)
	end,
	update=function(self)
		if (self.timer<20) self.timer+=1
	end,
}
function monsters_in_room(room)
	local rtrn=false
	for m in all(mobs) do
		if (m.room==room) rtrn=true
	end
	return rtrn
end

pu_library[3]={
	--heart container--
	draw=function(self)
		spr(21,self.x,self.y,1,1)
		stroke_text(10,self.x,self.y+10,7,0)
	end,
	pickup=function(self)
		if p.coins>=10 then
			p.maxhp+=1
			if (p.hp<p.maxhp) p.hp+=1
			p.coins-=10
			sfx(3)
			del(pickups,self)
		end
	end,
	update=function(self)
	self.timer=20
	end,
}

pu_library[4]={
--boomerang
	draw=function(self)
		spr(50,self.x,self.y,1,1)
		stroke_text(20,self.x,self.y+10,7,0)
	end,
	pickup=function(self)
		if p.coins>=20 then
			add(p.items,2)
			p.coins-=20
			sfx(3)
			del(pickups,self)
		end
	end,
	update=function(self)
		self.timer=20
	end,
}
pu_library[5]={
--slingshot
	draw=function(self)
		spr(27,self.x,self.y,1,1)
		stroke_text(5,self.x,self.y+10,7,0)
	end,
	pickup=function(self)
		if p.coins>=5 then
			add(p.items,5)
			p.coins-=5
			sfx(3)
			del(pickups,self)
		end
	end,
	update=function(self)
		self.timer=20
	end,
}

pu_library[6]={
	--key for purchase--
	draw=function(self)
		spr(16,self.x,self.y,1,1)
		stroke_text(20,self.x,self.y+10,7,0)
	end,
	pickup=function(self)
		if p.coins>=20 then
			p.keys+=1
			p.coins-=20
			sfx(3)
			del(pickups,self)
		end
	end,
	update=function(self)
		self.timer=20
	end,
}


function change_pallete(world)
	--change dungeon tiles for current world
	pal(15,1,1)
	if world==1 then
		--floor
		pal(3,140,1)
		pal(12,12,1)
		--dark
		pal(1,1,1)
		--darker
		pal(14,129,1)
		--darkest
		pal(2,128,1)
	elseif world==2 then
		--floor
		pal(3,131,1)
		pal(12,13,1)
		--dark
		pal(1,2,1)
		--darker
		pal(14,130,1)
		--darkest
		pal(2,128,1)
	elseif world==3 then
		--floor
		pal(3,13,1)
		pal(12,15,1)
		--dark
		pal(1,5,1)
		--darker
		pal(14,133,1)
		--darkest
		pal(2,128,1)
	end
end
-->8
--player/items
function player_setup()
	--init library to store player data
	p={
		dx=0,
		dy=0,
		sprite=34,
		face='n',
		anim_time=0,
		anim_delay=4,
		keys=0,
		state="control",
		coins=0,
		hp=4,
		maxhp=4,
		item=1,
		items={},
		timer=0
	}
	
end


function draw_player()
	local flipped=false

	if p.face=='s' then
		anim(p,32,33)
	elseif p.face=='n' then
		anim(p,34,35)	
	elseif p.face=='w' or p.face=='e' then
		anim(p,36,37)
	end
	if p.face=='w' then
		flipped=true
	end

	if p.state=="dead" then
			spr(38,p.x,p.y,1,1)
	elseif p.state~="hurt" then
		spr(p.sprite,p.x,p.y,1,1,flipped)
	elseif p.state=="hurt" and t%2==0 then
		spr(p.sprite,p.x,p.y,1,1,flipped)
	end		
end

function update_player()
	if p.hp<1 then
		death_screen()
	end
	
	if p.state=="control" or p.state=="hurt" and p.timer>7 then
		
		p.dx,p.dy=0,0
		
		if p.state=="control" then
			hurt_handler(p)
		end
		
		--controller inputs
		if btn(⬆️) then
			p.face='n'
			p.dy+=-1
		elseif btn(⬇️) then
			p.face='s'
			p.dy+=1
		elseif btn(⬅️) then
			p.face='w'
			p.dx+=-1
		elseif btn(➡️) then
			p.face='e'
			p.dx+=1
		end
		
		if btnp(❎) and p.state~="hurt" then
			if (not btn(🅾️)) use_item(1,p.x,p.y-7)
			sfx(42)
			p.state=8
		end
		if btnp(🅾️) and p.state~="hurt" then
				if p.items[1]~=nil then
					if not btn(❎) and #items<1 then
						use_item(p.items[p.item],p.x,p.y-7)
						p.state=8
					end
				end
				end
		end
		
		--pause when items is used
		if tonum(p.state) then	
	 	p.dx,p.dy=0,0
	 	p.timer+=1
	 	if p.timer==p.state then
	 		p.state,p.timer="control",0
	 	end
	 end
	
	--wall collisions 
	if not collided(p.x,p.y,one(p.dx),one(p.dy),solid) then
	 	p.x+=p.dx
	 	p.y+=p.dy 
	end
	
	if collided(p.x,p.y,p.dx,p.dy,lock) then
		if (p.keys>0) unlock()
	end
	
	--damage invulnerability	
	if p.state=="hurt" then
		p.timer+=1
		if p.timer==30 then
		 p.state,p.timer="control",0
		end
	
	elseif p.state=="hurt" and p.timer<=7 then
		p.timer+=1
		if not collided(p.x,p.y,one(p.dx),one(p.dy),solid) then
	 	p.x+=p.dx
	 	p.y+=p.dy 
		end
	
	elseif p.state=="transition" then
		--transition between rooms
		p.x+=p.dx/8
		p.y+=p.dy/8
		if camx==camx_target and camy==camy_target then
		 p.state="control"
			if player_room()==final_room() then
			 music(15)
			 sfx(41)
			elseif player_room()=='k' and monsters_in_room(player_room())  then
				sfx(41)
			end
		end
	end

end

function place_player(index)
	--place player in room
	if (index==nil) index=value_index(1)
	p.x,p.y=roomxy(index)
	p.x,p.y=(p.x*16)*8,((p.y*14)*8)
	camx,camy=p.x,p.y
	p.x+=7*8
	p.y+=14*8
end


function hurt_handler(m1)
	local d='w'
	for m2 in all(mobs) do
		if check_ebe_collision(m1.x,m1.y,m2.x,m2.y,m1.l,m2.l) then
		 d=direction_from(m2,m1)
		 m1.state="hurt"
		 m1.hp-=1
		 p.dx,p.dy=knockback(d)
		 if (m1==p) sfx(45)
		end
	end
	for m2 in all(boss) do
		if check_ebe_collision(m1.x,m1.y,m2.x,m2.y,m1.l,m2.l) then
		 d=direction_from(m2,m1)
		 m1.state="hurt"
		 m1.hp-=1
		 p.dx,p.dy=knockback(d)
		end
	end
end


function knockback(d)
--return direction to knockback creature when hit
	local dx, dy=0,0
	if (d=='n') dy=-2
	if (d=='s')	dy=2
	if (d=='w') dx=-2
	if (d=='e')	dx=2
	return dx,dy
end



----items----
items={}

function use_item(typ,ix,iy)
	local i={
		room=iroom,
		x=p.x,
		y=p.y-7,
		dx=0,
		dy=0,
		sprite=item_library[typ].sprite,
		first_spr=item_library[typ].first_spr,
		state=item_library[typ].state,
		timer=0,
		flipx=item_library[typ].flipx,
		flipy=item_library[typ].flipy,
		direction='n',
		update=item_library[typ].update,
		draw=item_library[typ].draw,
		hit=item_library[typ].hit
	}
	add(items,i)
end


function place_item(i,rotate)
	--place item based on player face
	rotate=rotate or false
	if p.face=='w' or p.face=='e' then
		if (not rotate) i.sprite=i.first_spr+1
	end
	if p.face=='s' then 
		i.flipy=true
		i.y=p.y+7
	elseif p.face=='e' then
	 i.x,i.y=p.x+7,p.y
	elseif p.face=='w' then
		i.flipx=true
		i.x,i.y=p.x-7,p.y
	end
end

item_library={}

item_library[1]={
	--sword--
	name="sword",
	first_spr=48,
	sprite=48,
	flipx=false,
	flipy=false,
	state="hit",
	update=function(self)
		self.timer+=1
		place_item(self)
		if self.timer==7 then
			del(items,self)
		end
	end,
	draw=function(self)
		
	end,
	hit=function(self,m)
		if self.state=="hit" then
			if m.state~="invulnerable" then
				hurt(m)
			else
				sfx(1)
				self.state="clink"
			end
		end
	end,
}

item_library[2]={
	--boomerang--
	name="boomrang",
	first_spr=50,
	sprite=50,
	flipx=false,
	flipy=false,
	state="init",
	update=function(self)
		self.timer+=1
		if self.timer==1 then 
			place_item(self)
			self.x,self.y=p.x,p.y
			tx,ty=set_target(50)
			self.state="throw"
			--set_target(30)
		end
		if self.state=="throw" then
			move_to_target(tx,ty,self,1.5)
			if (self.timer==30) self.state="return"
		elseif self.state=="return" then
			move_to_target(p.x,p.y,self,2)
		end
		if self.timer>10 and  check_ebe_collision(p.x,p.y,self.x,self.y) then
			del(items,self)
			tx,ty=0
		end
	end,
	draw=function(self)
		anim(self,self.first_spr,self.first_spr+1,true)
		if (self.timer%6==0) sfx(42)
	end,
	hit=function(self,m)
		m.state,m.timer,self.state="stun",0,"return"
	end,
}


item_library[5]={
	--slingshot
	name="slngsht",
	first_spr=27,
	sprite=19,
	state="init",
	update=function(self)
				self.state="shot"
				self.timer+=1
				if self.timer==1 then 
					sfx(43)
					if p.coins>0 then
						place_item(self,true)
						p.coins-=1
						self.x,self.y=p.x,p.y
						stx,sty=set_target(128)
					else
						del(items,self)
					end
				elseif self.timer>1 then
					move_to_target(stx,sty,self,1.5)
					if collided(self.x,self.y,0,0,solid,0) then
						sfx(1)
						add_drop(1,self.x,self.y)
						del(items,self)
					end
					if (self.timer==80) del(items,self)
			end
		

	end,
	draw=function(self)
	
	end,
	hit=function(self,m)
			if m.state~="invulnerable" then
				hurt(m)
			else
				sfx(1)
				self.state="clink"
				add_drop(1,self.x,self.y)
			end
			del(items,self)
	end,
}

function set_target(distance)
--for setting boomerang target
--based on player facing
	local targetx,targety=p.x,p.y
	if (p.face=="n") targety=p.y-distance
	if (p.face=="s") targety=p.y+distance
	if (p.face=="w") targetx=p.x-distance
	if (p.face=="e") targetx=p.x+distance
	return targetx,targety
end

function move_to_target(targetx,targety,self,speed)
	if targetx~=self.x then
		if targetx>self.x then self.dx=1 else self.dx=-1		end
	end
	if targety~=self.y then
		if targety>self.y then self.dy=1 else self.dy=-1		end
	end
	if abs(targetx-self.x)>speed then
		self.x+=self.dx*speed
	else
		self.x=targetx
			--self.x+=(targetx-self.x)*self.dx
	end
	
	if abs(targety-self.y)>speed then
		self.y+=self.dy*speed
	else
		self.y=targety
	end
end
-->8
--helper functions

--collision
function is_tile(x,y,typ,typ2)
	typ2=typ2 or nil
	val=mget(x/8,y/8)
	if typ2~=nil then
		return fget(val,typ) or fget(val,typ2)
	else
	 return fget(val,typ)
	end
end

function collided(x,y,dx,dy,typ,l)
	--collision with walls
	l=l or 8
	if dy<0 then
		return is_tile(x+1,y+dy,typ) or is_tile(x+(l-2),y+dy,typ)
	elseif dy>0 then
		return is_tile(x+1,y+(l-1)+dy,typ) or is_tile(x+(l-2),y+(l-1)+dy,typ)
	elseif dx<0 then
		return is_tile(x+dx,y+1,typ) or is_tile(x+dx,y+(l-2),typ)
	elseif dx>0 then
		return is_tile(x+(l-1)+dx,y+1,typ) or is_tile(x+(l-1)+dx,y+(l-2),typ)
	elseif dx==0 then
		return is_tile(x,y,typ)
	else
		return false
	end
end

function direction_from(m1,m2)
--returns the direction m2 is from m1
	local d='e'
	if (m1.x<=m2.x) d='e'
	if (m1.x>=m2.x) d='w'
	if (m1.y+7<=m2.y) d='s'
	if (m1.y>=m2.y+7) d='n'
	return d
end

function one(x)
	if x==0 then
		return 0
	elseif x>0 then
		return 1
	else
		return -1
	end
end

--check collision of two eight by eight objects
function check_ebe_collision(x1,y1,x2,y2,l1,l2)
 l1=l1 or 8
 l2=l2 or 8
 if (x1+l1-1 < x2) or (x2+l2-1 < x1) 
 or (y1+l1-1 < y2) or (y2+l2-1 < y1) then
   return false
 else 
 	return true
 end
end


--animation--
function anim(x,first_spr,last_spr,move)
	move=move or nil
	if x.dx~=0 or x.dy~=0 or move then
		--if moving
		if not is_between(x.sprite,first_spr,last_spr) then
			x.sprite=first_spr
		end
		if t%4==0 then
			x.sprite+=1
			if x.sprite>last_spr then
				x.sprite=first_spr
			end
		end
	else
	--if not moving
		x.sprite=first_spr
	end
	
end

function camera_handler()
	if p.x+8>camx+(16*8) then
		camx_target=camx+(16*8)
		p.state="transition"
	elseif p.y>camy+(14*8)+8 then
		camy_target=camy+(14*8)
		p.state="transition"
	elseif p.y<camy+16 then
		camy_target=camy-(14*8)
		if camy_target<-50 then
		 camy_target=camy
		 counter,gamestate=0,"nextlevel"
		end
		p.state="transition"
	elseif p.x<camx then
		camx_target=camx-(16*8)
		p.state="transition"
	end
	if camx<camx_target then 
		camx+=8
	elseif camy<camy_target then
	 camy+=8
	elseif camx>camx_target then
		camx-=8
	elseif camy>camy_target then
		camy-=8
	end
end


function roomindex(x,y)
--return room index from x,y
	return (y*5)+x+1
end

function roomxy(index)
--return x,y, from room index
	if (index==nil) index=1
	local x,y=(index%5)-1,(index\5)
	if x==-1 then
	 x=4
	 y-=1
	end
	return x,y
end

function final_room()
--returns value of last room
	local final=0
	for v in all(dungeon) do
	if tonum(v) then	
		if (v>final) final=v
	end
	end
	return final
end

function first_room()
	--return index of first room
	return value_index(1)
end

function value_index(value)
--returns the index of a room value
	for c=1,20 do
		if (dungeon[c]==value) return c
	end
end

function is_between(v,mini,maxi)
	if v>=mini and v<=maxi then
		return true
	else
		return false	
	end
end

function player_room()
--returns the index of the player room
	local x,y=camx\(16*8),camy\(14*8)
	return dungeon[roomindex(x,y)]
end


function is_in_list(list,i)
	local ir=false
	for a in all(list) do
		if (a==i) ir=true
	end
	return ir
end

function coord_in_room(roomi,x,y)
--returns coordinates for a spot in a room
	local roomx,roomy=roomxy(roomi)
	local x=(x+(roomx*16))*8
	local y=(y+(roomy*14)+2)*8
	return x,y
end
-->8
--proc gen
--[[
dungeon layout is stored as aan array
of twenty numbers:
	00000
	00000
	00000
	00000
with the top left room of the dungeon
being dungeon[1] and the bottom right
being dungeon[20]	
]]--


function map_gen(world)
		dungeon ="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"
		dungeon=split(dungeon)
		mobs,boss,pickups,items,explored={},{},{},{},{}
		change_pallete(world)
 	set_shop_mobs(world)
 	

	
	for x=0,127 do
		for y=2,64 do
			mset(x,y,1)
		end
		end
		dungeon_path(world)
end


function set_tile_in_room(rindex,x,y,sprite,ifflag)
	--locate a tile in the room, change it
	ifflag=ifflag or nil
	local roomx,roomy=roomxy(rindex) 
	x,y=x+(roomx*16),y+(roomy*14)+2
	if is_tile(x*8,y*8,ifflag) or ifflag==nil then
		mset(x,y,sprite)
	end
end

function get_tile_in_room(roomx,roomy,x,y)
	--return sprite of a tile in a room
	x,y=x+(roomx*16),y+(roomy*14)+2
	return mget(x,y)
	
end

function set_room_to_string(i,roomstr)
	--iterate through a string to set tiles
	local mob=rnd(moblist)
	for x=0,13 do 
		for y=0,11	do
			local tile=(y*14)+x+1
			local tile_char=sub(roomstr, tile,tile)
			if tile_char=='m' then
			--add monster
				add_mob(mob,i,x+1,y+1)		
			elseif tile_char=='s' then
					--set store item
					local ax,ay=coord_in_room(i,x,y)
					local drop=rnd(shoplist)
					if (drop==nil) drop=3
					add_drop(drop,ax,ay)
					del(shoplist,drop)
			elseif tile_char=='k' then
				place_key(i,x,y)		
	end
			if (not tonum(tile_char)) tile_char=2
			set_tile_in_room(i,x+1,y+1,tile_char)
		end
	end
end

function set_door(index,direction)
--opens a door in a room
	local d=convert_directions({direction})
	direction=d[1]
	if direction==-5 then
		set_tile_in_room(index,7,0,5)
		set_tile_in_room(index,8,0,5)
	elseif direction==5 then
		set_tile_in_room(index,7,13,5)
		set_tile_in_room(index,8,13,5)	
	elseif direction==-1 then
		set_tile_in_room(index,0,6,5)
		set_tile_in_room(index,0,7,5)
	elseif direction==1 then
		set_tile_in_room(index,15,6,5)
		set_tile_in_room(index,15,7,5)
	end
end

function set_barrier(index, direction, lock)
--places a temporary barrier in a room
	lock=lock or false
	local check=2
	if (lock) check=nil
	local tile=3
	if (lock) tile=4
	if direction=='n' then
		set_tile_in_room(index,7,0,tile,check)
		set_tile_in_room(index,8,0,tile,check)
	elseif direction=='s' then
		set_tile_in_room(index,7,13,tile,check)
		set_tile_in_room(index,8,13,tile,check)	
	elseif direction=='w' then
		set_tile_in_room(index,0,6,tile,check)
		set_tile_in_room(index,0,7,tile,check)
	elseif direction=='e' then
		set_tile_in_room(index,15,6,tile,check)
		set_tile_in_room(index,15,7,tile,check)
end
	
end

function all_doors(lock_room)
--connect all active rooms in the dungeon
	local x,y =0,0
	local door,adj=false,0
	for r=1,final_room() do
	--main path
		for d in all(directions) do
			door=false
			adj=adjacent_room(r,d)
			if r>lock_room then
				if adj==r-1 or adj==r+1 then
			 	door=true
				end
			elseif tonum(adj) and r<=lock_room then
				if (adj<=lock_room and adj>0) door=true		
			end
			if (tonum(adj) and adj%1~=0) door=false
			if (not tonum(adj)) door=true	
				
				--set x and y
		 	if (door) set_door(value_index(r),d)	
		 	
		 	--set lock
		 	if r==lock_room and adjacent_room(r,d)==lock_room+1 then
		 		x,y=roomxy(value_index(r))
		 		set_barrier(value_index(r),d,true)
		 	end
		 	
		 	--key path
		 	for r in all(path_rooms) do

		 		for d in all (directions) do
		 			door=false
						adj=adjacent_room(r,d)
						if adj==r+0.1 or adj==r-0.1 then
							door=true
						end
		 			if (door) set_door(value_index(r),d)
		 		end
		 	end
		end
	end
end

function dungeon_path(world)
	--create path through the dungeon
	local dir_choice,i,first_rooms=0,1,{16,17,18,19,20}
	local direction,before_lock={},{}
 lock_rooms,path_rooms,bonus_rooms={},{},{}

	
	--for first two dungeons
	if world<3 then
		--pick first room from bottom row
	 current=rnd(first_rooms)
		dungeon[current]=1
		
		--set main path
		while true do
		i+=1
		direction=clean_directions(current,{-5,-1,1})
			
	
		repeat
		 --choose direction until empty room found
				dir_choice=rnd(direction)
		until  dungeon[mid(1,current+dir_choice,20)]==0 or (current<6 and dir_choice==-5)
			--if on top row and going north, end loop
			if (current<6 and dir_choice==-5) break 		
			
			current=current+dir_choice
			dungeon[current]=i
		end
		
		
		--choose lock rooms
		lock_rooms=set_lock_rooms(1)
		
		
		--make key path
		local i=lock_rooms[1]
		repeat
		--list rooms before lock
			i-=1
			add(before_lock, i)
		until i==1
		
		--pick room to start branching path
		path_room=choose_path_room(before_lock)
		if (path_room==nil) path_room=1
		i=path_room
		add(path_rooms,i)
		del(before_lock, i)
		current=value_index(i)
	--path loop
		repeat
			if not has_openings(i) then
				key_room=dungeon[current]
				break	
		 end
			
			i+=0.1
			direction=clean_directions(current,{-5,-1,1,5})
			
			repeat
				dir_choice=rnd(direction)
			until  dungeon[mid(1,current+dir_choice,20)]==0 or (current<6 and dir_choice==-5) 
	
			
			current=current+dir_choice
			if dungeon[current]==0 then
			 dungeon[current]=i
			 add(path_rooms,i)
			end
		until (not has_openings(i)) or
		i%0.4==0
		
		--designate key room, open doors, set shop room
		key_room=dungeon[value_index(path_rooms[#path_rooms])]
		all_doors(lock_rooms[1])
		add(bonus_rooms,set_bonus_room())	
		if (bonus_rooms[1]~=0) dungeon[bonus_rooms[1]]='s'
		
		--mark special rooms in array
		mark_room(key_room,'k')
		for v in all(lock_rooms) do
			mark_room(v,'l')
		end
		
	
	
	elseif world==3 then
		--for world 3

		--set all rooms active
		dungeon={}
		for c=1,20 do
			dungeon[c]=c
		end
		 
		--separate middle rooms 
		dungeon[1],dungeon[18],dungeon[13]=23,1,28
		dungeon[8],dungeon[3]=29,30
		
		local path_rooms={}
		for r in all(dungeon) do
			--set doors
			local i=value_index(r)
			if tonum(r) and r<28 then
				if (i%5!=1 and adjacent_room(r,'w')<28) set_door(i,'w')
				if (i%5!=0 and adjacent_room(r,'e')<28) set_door(i,'e')
				if (i<16 and adjacent_room(r,'s')<28) set_door(i,'s')
				if (i>5 and adjacent_room(r,'n')<28) set_door(i,'n')
				add(path_rooms,i)
			end
	end
	
	del(path_rooms, 1)
	
	for c=1,3 do
	--place 3 lock rooms
		local key_room=rnd(path_rooms)
		dungeon[key_room]='k'..tostr(c)
		del(path_rooms,key_room)
	end
	--choose random room for shop
	dungeon[rnd(path_rooms)]='s'
	
	for i in all({18,13,8,3}) do
	--set locks for middle rooms
		if (i~=3) set_barrier(i,'n',true)
		if (i~=18) set_door(i,'s')
	end
	
	x,y=roomxy(3)
	set_door(i,'s')
	end
	
	--place templates onto active rooms
	for c=1,20 do
			x,y=roomxy(c)
			if sub(dungeon[c],1,1)=='k' then
				set_room_to_string(c,rnd(keyrooms))
			elseif dungeon[c]=='l' then
				set_room_to_string(c,rnd(rooms))
			elseif dungeon[c]=='s' then
				set_room_to_string(c,shops)
			elseif dungeon[c]~=final_room() then
				set_room_to_string(c,rnd(rooms))
			end
	end	
		set_room_to_string(value_index(final_room()),bossrooms)

		
		if world<3 then
			spawn_boss(1,final_room())
		else
			spawn_boss(2,final_room())
		end
end

function choose_path_room(list)
	for v in all(list) do
		if (not has_openings(v)) del(list,v)
	end
	--if (count(sub_list)<1) add(sub_list, rnd(list))
	return rnd(list)
end

function clean_directions(c,dir_list)
--returns direction list keeping the path in the map
	local direction=dir_list
		
	if c%5==1 then
	--if on left column, dont go west			del(direction,-1)
		del(direction,-1)
	end
	if c%5==0 then
	--on right row, dont go east
		del(direction,1)
	end
	if c>15 then
	--on right row, dont go east
		del(direction,5)
	end
	return direction
end

function has_openings(r)
	--return true if room has adjacent empty rooms
	for d in all(directions) do
		if (adjacent_room(r,d)==0) return true
	end
	return false
end

function which_openings(r)
--returns directions of free space around it
	local list={}
	for d in all(directions) do
		if (adjacent_room(r,d)==0) add(list,d)
	end
	if (list[1]==nil) list={}
	return list
end

function set_lock_rooms(number)
--set lock rooms in table equal to the number
	local lock_rooms,room,i={},2,0
	while i<number do
	 room=flr(rnd(final_room()-2))+2
		if lock_rooms[i]~=room then
			add(lock_rooms, room)
			i+=1
		end
	end
	return lock_rooms
		
end

function mark_room(index,marker)
--sets room value to new value
	for c=1,20 do
		if index~=0 then
			if (dungeon[c]==index) dungeon[c]=marker 
		end
	end
end

function adjacent_room(roomvalue, direction)
--returns value of adjacent room
	local v=-2
	for b=1,20 do
	 if dungeon[b]==roomvalue then
			if (direction=='n' and b>5)  v=dungeon[b-5]
			if (direction=='s' and b<16)  v=dungeon[b+5]
			if (direction=='w' and b%5~=1)  v=dungeon[b-1]		
			if (direction=='e' and b%5~=0)  v=dungeon[b+1]
		end
	end
	if v==nil or v=='?' then
		return 0
	else
		return v
	end
end

function unset_barrier(i, direction)
--remove temporary barriers
	local check,tile=3,2
	if direction=='n' then
		set_tile_in_room(i,7,0,tile,check)
		set_tile_in_room(i,8,0,tile,check)
	elseif direction=='s' then
		set_tile_in_room(i,7,13,tile,check)
		set_tile_in_room(i,8,13,tile,check)	
	elseif direction=='w' then
		set_tile_in_room(i,0,6,tile,check)
		set_tile_in_room(i,0,7,tile,check)
	elseif direction=='e' then
		set_tile_in_room(i,15,6,tile,check)
		set_tile_in_room(i,15,7,tile,check)
end
	
end

function set_bonus_room(marker)
	--finds empty room to place shop
	local room_list={}
	connect_room,bonus_room=1,nil
	for r in all(dungeon) do
		if r~=final_room() and r~=1 then			
		if has_openings(r) and tonum(r) then
		 if (r~=0) add(room_list,r)
		end
		end
	end
	connect_room=rnd(room_list)
	local direct=which_openings(connect_room)
	if (connect_room==nil) return 0
	direct=convert_directions(direct)
	direct=clean_directions(connect_room,direct)
	direct=rnd(direct)
	if direct==nil then
		bonus_room=value_index(2)
		return bonus_room
	else
		bonus_room=value_index(connect_room)+direct
		set_door(value_index(connect_room),direct)
		set_door(bonus_room,direct*-1)
		return bonus_room
	end
	
end


function convert_directions(dir)
	--unify direction notation
	local list={}
	for d in all(dir) do
		if (d=="n") add(list,-5)
		if (d=="s") add(list,5)
		if (d=="w") add(list,-1)
		if (d=="e") add(list,1)
		if (tonum(d)) add(list,d)
	end
	return list
end
-->8
--room templates
--created in room editor built for the game

rooms="222222222222222112222222211221122222222112222m222222m22222221122112222222211221122222222112211222222221122112222222m222222m222211222222221122112222222211222222222222222,222222222222222222222222222222222222222222222m222222m2222222112211222222221122112222222211m211222222221122112222222m222222m222222222222222222222222222222222222222222222,222222222222222222222222222222112222221122221122222211222222m2222m222222222222222222222222222222222222m2222m222222112222221122221122222211222222222222222222222222222222,222222222222222222222222222222112222221122221122222211222222m2222m222222222211222222222222112222222222m2222m222222112222221122221122222211222222222222222222222222222222,222222222222222222222222222222112211221122221122112211222222m2222m222222112211221122221122112211222222m2222m222222112211221122221122112211222222222222222222222222222222,222222222222222222222222222222222211222222222222112222222222m2222m222222112211221122221122112211222222m2222m222222222211222222222222112222222222222222222222222222222222222222222222222222222222222222222211222222222222112222222222m2222m222222112211221122221122112211222222m2222m222222222211222222222222112222222222222222222222222222222222,222222222222222222222222222222222211222222222222112222222222m2222m2222221122m2221122221122222211222222m2222m222222222211222222222222112222222222222222222222222222222222,2222222222222222222222222222221111111111222211111111112222222222222222222m222222m22222222222222222222m222222m22222111111111122221111111111222222222222222222222222222222,2222222222222222222222222222221111111111222211111111112222222222222222222m221122m22222222211222222222m222222m22222111111111122221111111111222222222222222222222222222222,112222222222111222222222222122222222222222222122222212222222m2222m2222222222222222222222222m2222222222m2222m222222212222221222222222222222221222222222222111222222222211,122222222222212222222222222222122222222122222122222212222222m2222m222222222211222222222222112222222222m2222m222222212222221222221222222221222222222222222212222222222221,22222222222222222222222222222222m2112m22222222221122222222222211222222222222112222222222m2112m222222222211222222222222112222222222m2112m22222222222222222222222222222222,22222222222222222222222222222222m2112m22222222221122222222222211222222221111111111222211111111112222222211222222222222112222222222m2112m22222222222222222222222222222222,2222222222222222222222222222222222222222222222m2222m2222222222222222222211111111112222111111111122222222222222222222m2222m2222222222222222222222222222222222222222222222,2222222222222222222222222222222222222222222222m2222m222222222222222222221111221111222211112m111122222222222222222222m2222m2222222222222222222222222222222222222222222222,2222222222222222111122111122221111221111222222m2222m222222222222222222221111221111222211112m111122222222222222222222m2222m2222221111221111222211112211112222222222222222,22222222222222222222222222222112221122211221122211222112211222112221122222m2222m2222222222222222222222m2222m222221122211222112211222112221122112221122211222222222222222,22222222222222222222222222222112221122211221122211222112211222112221122222m2112m2222222222112222222222m2112m222221122211222112211222112221122112221122211222222222222222,22222222222222222222222222222112222222211221122222222112211222222221122222m2112m2222222222112222222222m2112m222221122222222112211222222221122112222222211222222222222222,222222222222222222222222222222222222222222222222m2222222222221111222222222m1111m2222222221111222222222m1111m222222222111122222222222m22222222222222222222222222222222222,2222222222222222222222222222222222222222222222222222222222222m11m222222222m1111m2222222221111222222222m1111m222222222m11m22222222222222222222222222222222222222222222222,2222222222222222222222222222222222222222222222222222222222222m11m222222222m1111m2222222222222222222222m1111m222222222m11m22222222222222222222222222222222222222222222222,2222222222222222222222222222221111111111222222222222222222222m22m22222222222112222222222221122222222222m22m2222222222222222222221111111111222222222222222222222222222222,2222222222222222222222222222221222222221222212222222212222122m22m22122221222112221222212221122212222122m22m2212222122222222122221222222221222222222222222222222222222222,222222222222222222222222222222111222211122221m222222m1222212222222212222222222222222222222222222222212m2222m212222122222222122221112222111222222222222222222222222222222,222222222222222222222222222222111222211122221m222222m1222212222222212222222211222222222222112222222212m2222m212222122222222122221112222111222222222222222222222222222222,222222222222222222222222222222221222212222222m222222m2222212222222212222222211222222222222112222222212m2222m212222222222222222222212222122222222222222222222222222222222,222222222222222122222222221222221222212222222m222222m2222212222222212222222211222222222222112222222212m2222m212222222222222222222212222122222122222222221222222222222222,2222222222222222222222222222222222222222222222m2222m2222222222112222222222211112222222222111122222222222112222222222m2222m2222222222222222222222222222222222222222222222,2222222222222221122222222112211222222221122222m2222m2222222222112222222222211112222222222111122222222222112222222222m2222m2222211222222221122112222222211222222222222222"

keyrooms="222222222222222222222222222222211222211222222112m2211222222112222112222222222k2222222222m2222m2222222112222112222221122m211222222112222112222222222222222222222222222222,2222222222222222222222222222221122222211222211m2222m112222112222221122221122k222112222112222221122221122222211222211m2222m1122221122222211222222222222222222222222222222,222222222222222112222222211221122222222112222m222222m2222222112211222222221122112222222211k211222222221122112222222m222222m222211222222221122112222222211222222222222222"
bossrooms="222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222"


shops="111222222221111122222222221112222222222221222222222222222222222222222222222222222222222s222s22s2222222222222222222222222222222122222222222211122222222221111122222222111"
-->8
--hud/graphics
function draw_minimap()
--draw map in hud
	local i,tile_color,x,y=0,0,0,0

	for v=1,20 do
			tile_color=0
			if (is_in_list(explored,dungeon[v])) tile_color=12
			if (dungeon[v]==player_room()) tile_color=7
		x,y=camx+((i%5)*7)+1,camy+((i\5)*4)+1
		rectfill(x,y,x+4,y+1,tile_color)
		i+=1
	end
end

function draw_health()
	local i=0
	if p.maxhp>7 then
		print("♥"..p.hp.."/"..p.maxhp,camx+35+i,camy+3,8)
	else
		for c=1,p.maxhp do
			local col=8
			if (c>p.hp) col=1
			print("♥",camx+35+i,camy+3,col)
			i+=6
		end
	end
end

function draw_item()
	rect(camx+80,camy+3,camx+91, camy+14,5)
	if (p.items[1]~=nil) spr(item_library[p.items[p.item]].first_spr,camx+82,camy+5)
	
	rect(camx+94,camy+3,camx+105, camy+14,5)
	spr(48,camx+96,camy+5)
	

end

function minutes(seconds)
 --convert seconds to time format
 local minutes = seconds\60
	seconds=seconds%60
	if (seconds<10) seconds="0"..seconds
 local string= " "..minutes..":"..seconds 
	return string	
end

function draw_timer()
	local string=minutes(flr(t/30))
	print(string, camx+(16*8)-(#string*4), camy+3,7)
end

--game states--
function death_screen()
	p.dx,p.dy=0,0
	p.state,p.sprite,gamestate="dead",38, "dead"
end

function update_menu()
	cls(0)
	map(0,0,0,0,128,128)
	print('press ❎ to start',(0+64-(17*2))+1,(10*8),0)
	print('press ❎ to start',0+64-(17*2),10*8,10)
	spr(144,40,48,6,3) 	
	if btnp(❎) then
		gamestate="restart"
		--music(0)
	end
end

--text--
function stroke_text(string,x,y,fillc,strokec)
	print(string,x+1,y,str0kec)
	print(string,x-1,y,str0kec)
	print(string,x,y+1,str0kec)
	print(string,x,y-1,str0kec)
	print(string,x,y,fillc)
end


--pause menu
function item_select(b)  
    if b&1>0 then
	    if p.items[1]~=nil then
	    	p.item-=1
						if p.item==0 then 
							p.item=#p.items
						end
	    	menuitem(_,"🅾️ item: "..item_library[p.items[p.item]].name)
	    end
	   elseif b&2>0 then
    	if p.items[1]~=nil then
	    	p.item+=1
						if p.item>#p.items then 
							p.item=1
						end
	    	menuitem(_,"🅾️ item: "..item_library[p.items[p.item]].name)
	    --if(b&32 > 0) menuitem(_,"selected!")
	   	end
	   end
    return true -- stay open
end

function quick_restart(b)
		if counter==0 then
		 if b&32>0 then
				menuitem(_,"are you sure?")
				counter+=1
				return true
			end
  else
	  if b&32>0 then
				gamestate="restart"
				counter=0
				menuitem(_,"quick restart")
	  end
	 end 
end



-->8
--mobs

mobs={}

function mobs_setup()
	for m in all(mobs) do
		if m.room==lock_rooms[1] then
			m.room=dungeon[m.room]
		else m.room=dungeon[m.room]
		end
	end
end
function add_mob(typ,mroom,mx,my)
	local m={
		room=mroom,
		dx=0,
		dy=0,
		tx=0,
		ty=0,
		l=8,
		sprite=mob_library[typ].sprite,
		first_spr=mob_library[typ].first_spr,
		state="stop",
		timer=0,
		face='n',
		hp=mob_library[typ].hp,
		flipx=false,
		flipy=false,
		direction=rnd(directions),
		update=mob_library[typ].update,
		draw=mob_library[typ].draw
		}
		m.x,m.y=coord_in_room(mroom,mx,my)
		if (world>1) m.room=dungeon[mroom]
	add(mobs,m)
end

function mob_move(m,amt,d)
	--move monster if it can
	if d=='n' then
		m.dy=-amt
	elseif d=='s' then
		m.dy=amt
	elseif d=='w' then
		m.dx=-amt
	else
		m.dx=amt
	end
	if collided(m.x,m.y,m.dx,m.dy,enemy_solid) then
		m.dx,m.dy=0,0
		return false	
	else return true end
end


function hurt(m)
		local d=direction_from(p,m)
	 m.state,m.timer="hurt",0
	 m.dx,m.dy=knockback(d)
end


function grid_enemy(m,pause,d,seek)
--behavior for most monsters
			d=d or directions
			if m.state=="stop" then
				 	m.timer+=1
				if m.timer==pause then
				 m.direction=rnd(d)
				 if seek then
						m.direction=direction_from(m,p)
						if (not mob_move(m,0.25,m.direction,m.l)) m.direction=rnd(d)
 					end
					m.timer,m.state=0,"move"
				end
			elseif m.state=="stun" then
				m.timer+=1
				if m.timer>59 then
					m.timer,m.state=0,"move"
				end
			elseif m.state=="hurt" then
				m.timer+=1
				m.dx,m.dy=one(m.dx),one(m.dy)
				if not collided(m.x,m.y,m.dx,m.dy,enemy_solid,m.l) then
					m.x+=m.dx
					m.y+=m.dy
				end
				if m.timer==8 then
					m.timer,m.state=0,"stop"
					m.hp-=1
				end
			elseif m.state=="move" then

				if mob_move(m,0.25,m.direction,m.l) then
					m.x+=m.dx
					m.y+=m.dy
					m.timer+=1
					if m.timer==16 then
						m.timer,m.dx,m.dy,m.state=0,0,0,"stop"
					end
				else
					m.direction=rnd(d)	
				end
			end
		if not collided(m.x,m.y,m.dx,m.dy,enemy_solid) and not m.state=="stun" then
	 	m.x+=m.dx
	 	m.y+=m.dy 
		end
		end
		
		
--boss--

boss={}

function spawn_boss(typ,room)
	local b={}
	b.room=(value_index(room))
	b.x,b.y=coord_in_room(b.room,6,2)
	--if (world==2) b.x,b.y=coord_in_room(b.room,6,8)	
	b.state,b.timer,b.direction='stop',0,'e'
	b.hp=6
	b.dx=0
	b.dy=0
	b.l=24
	b.sprite=boss_library[typ].sprite
	b.first_spr=boss_library[typ].first_spr
	b.flipy=boss_library[typ].flipy
	b.update=boss_library[typ].update
	b.draw=boss_library[typ].draw
	add(boss,b)
	boss_library[typ].spawn()
end

function minion(x,y)
	local b={}
	b.sprite,b.first_spr=66,66
	b.room=boss[1].room
	b.x,b.y=boss[1].x+x,boss[1].y+y
	b.dx,b.dy=0,0
	b.l=8.1
	b.hp,b.speed=1,2
	b.state="invulnerable"
	b.timer,b.direction=0,'e'

	b.update=function(self)
		if (self.y>camy+128) del(boss,self)
		local targetx,targety=0
		if self.state=="invulnerable" then	
			self.dx,self.dy=boss[1].x+x,boss[1].y+y
			self.speed=2
		elseif b.state=="hunt" then
			self.speed=0.75
			self.dx,self.dy=p.x+4,p.y+4
		if	check_ebe_collision(p.x,p.y,self.x,self.y,p.l,8) then self.state="hurt" end
	
		elseif b.state=="stun" then
			self.speed=0
			self.timer+=1
			if (self.timer==75)	self.state="invulnerable"
		elseif self.state=="hurt" then
					self.timer+=1
					self.speed=0
					if self.timer>7 then
						self.timer=0
						self.state="stop"
						self.hp-=1
					end
		end
	
		move_to_target(self.dx,self.dy,self,self.speed)
	
	end
	b.draw=function(self)
		--this aint working
		if self.state~="hurt" then
			spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
		elseif self.state=="hurt" and t%2==0 then
			spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
		end
	end
	
	return b
end
	
	
	boss_library={}
	boss_library[1]={
	--slime
	sprite=64,
	first_spr=64,
	flipy=false,
	hp=6,
	update=function(self)
		if #boss>1 then
			self.hp=6
		end
			grid_enemy(self,1,{'e','w','n','s',})		
	end,
	draw=function(self)
		anim(self,self.first_spr,self.first_spr+1)
		local sx,sy=(self.sprite%16)*8, (self.sprite\16)*8
		if self.state=="hurt" and #boss==1 and t%2==0 then
			sspr(sx,sy,8,8,self.x,self.y,24,24,self.flipx,self.flipy)
		elseif self.state~="hurt" or (self.state=="hurt" and #boss>1) then
				sspr(sx,sy,8,8,self.x,self.y,24,24,self.flipx,self.flipy)
		end
	end,
	spawn=function(self)
		
	end
	}
	
	boss_library[2]= {
	--eyeball
	sprite=66,
	first_spr=66,
	flipy=true,
	hp=6,
	update=function(self)
		if #boss>1 then
			self.hp=6
		end
		grid_enemy(self,15,{'e','w'})
		if t%150==0 and #boss>1 then
			repeat 
				m=rnd(boss)
			until m~=boss[1]
			m.state="hunt"
			if #boss<8 then
				repeat 
					m=rnd(boss)
				until m~=boss[1]
				m.state="hunt"
			end
		end
	end,
	draw=function(self)
		if (self.direction=='s') self.flipy=true
		if (self.direction=='n') self.flipy=false
		if (self.direction=='w') self.flipx=true
		if (self.direction=='e') self.flipx=false
		anim(self,self.first_spr,self.first_spr+1)
		local sx,sy=(self.sprite%16)*8, (self.sprite\16)*8
		if self.state=="hurt" and #boss==1 and t%2==0 then
			sspr(sx,sy,8,8,self.x,self.y,24,24,self.flipx,self.flipy)
		elseif self.state~="hurt" or (self.state=="hurt" and #boss>1) then
				sspr(sx,sy,8,8,self.x,self.y,24,24,self.flipx,self.flipy)
		end
	end,
	spawn=function(self)
		add(boss,minion(-2,-2))
		add(boss,minion(4,-6))
		add(boss,minion(11,-6))
		add(boss,minion(18,-2))
		add(boss,minion(22,4))
		add(boss,minion(22,11))
		add(boss,minion(18,18))
		add(boss,minion(-6,4))
		add(boss,minion(-6,11))
		add(boss,minion(-2,18))
		add(boss,minion(4,22))
		add(boss,minion(11,22))
	end
	}
-->8
--mob library
mob_library={}

mob_library[1]= {
	--slime
	hp=1,
	sprite=64,
	first_spr=64,
	update=function(self)
		grid_enemy(self,16)
	end,
	draw=function(self)
		anim(self,self.first_spr,self.first_spr+1)
	if self.state~="hurt" then
		spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
	elseif self.state=="hurt" and t%2==0 then
		spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
	end
	end
	}
	
mob_library[2]= {
	--bug
	hp=1,
	l=8,
	sprite=70,
	first_spr=70,
	update=function(self)
		grid_enemy(self,1)
	end,
	draw=function(self)
		if (self.direction=='w') self.flipx=true
		if (self.direction=='e') self.flipx=false
		anim(self,self.first_spr,self.first_spr+1)
	if self.state~="hurt" then
		spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
	elseif self.state=="hurt" and t%2==0 then
		spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
	end
	end
	}
	
	mob_library[3]= {
	--bat
	hp=1,
	l=8,
	sprite=68,
	first_spr=68,
	update=function(self)
		if self.state=="stop" then
			self.timer+=1
			if self.timer>rnd(600) then
			 self.state="move"
			 self.timer=0
			end
		elseif self.state=="stun" then
				self.timer+=1
				if self.timer>59 then
					self.timer=0
					self.state="move"
				end
		elseif self.state=="hurt" then
				self.timer+=1
				if self.timer==8 then
					self.timer=0
					self.state="stop"
					self.hp-=1
				end
		elseif self.state=="move" then
		
			if self.timer==0 then
				self.tx,self.ty=set_target(rnd(10))
				if self.tx>self.x then self.dx=1 elseif self.tx<self.x then self.dx=-1 end
				if self.ty>self.y then self.dy=1 elseif self.ty<self.y then self.dy=-1 end
		
			end
			self.x+=self.dx/2
			self.y+=self.dy/2
			self.timer+=1
			if self.timer>rnd(600) then
				self.state="stop"
				self.dx=0
				self.dy=0
				self.timer=0
			end
			
		
		end
	end,
	draw=function(self)
		anim(self,self.first_spr,self.first_spr+1)
		if self.state~="hurt" then
			spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
		elseif self.state=="hurt" and t%2==0 then
			spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
	end
	end
	}
	
	mob_library[4]= {
	--eyeball
	hp=1,
	l=8,
	sprite=66,
	first_spr=66,
	update=function(self)
		grid_enemy(self,1,directions,true)
	end,
	draw=function(self)
		if (self.direction=='s') self.flipy=true
		if (self.direction=='n') self.flipy=false
		if (self.direction=='w') self.flipx=true
		if (self.direction=='e') self.flipx=false
		anim(self,self.first_spr,self.first_spr+1)
	if self.state~="hurt" then
		spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
	elseif self.state=="hurt" and t%2==0 then
		spr(self.sprite,self.x,self.y,1,1,self.flipx,self.flipy)
	end
	end
	}
__gfx__
0000000011111112ccccccc301111110a111111accccccc300bbbb00000000011111111100000000000000000000000000000000000000000000000607777770
0000000011111122c333333e101111021a1111a2c333333e0bbbbbb0000000111000000200000000000000000000000000000000000000000666666670000007
0070070011eeee22c333333e1100002211aaaa22c333333ebbbbbbbb005555111000000200000000000000000000000000000000000000000600006670077007
0007700011eeee22c333333e1100002211a00a22c333333ebbbbbbbb005555111000000200000000000000000000000000000000000000000600006670700707
0007700011eeee22c333333e1100002211a00a22c333333ebbbbbbbb005555111000000200000000000000000000000000000000000000000600006670700707
0070070011eeee22c333333e1100002211aaaa22c333333ebbbbbbbb005555111000000200000000000000000000000000000000000000000600006670077777
0000000012222222c333333e102222021a2222a2c333333e0bbbbbb0011111111000000200000000000000000000000000000000000000000666666670000007
0000000022222222eeeeeee102222220a222222aeeeeeee100bbbb00111111112222222100000000000000000000000000000000000000006666666607777770
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeeebeebb666666bb666666bb666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbaaabbbbbbbbbbbbb6666bbbbba9bbbb88eb8ebe88ee88eb6bbbb6bb6bbbb6bb6bbbb6bbbbbbbbbbbbbbbbbb47bbb47bbbbbbbbbbbbbbbb0000000000000000
bba9abbbbbbbbbbbb622226bbbaaa9bbb888888be888888eb666666bb666666bb666666bbbbbbbbbbbbbbbbbb4b7bb47bbbbbbbbbbbbbbbb0000000000000000
bbaaabbbbbbbbbbbb766667bbaaaaa9bb888888be888888e6bbbb6b66bbbb6b66bbbb6b6bbbbbbbbb66bbbbbb44b744bbbbbbbbbbbbbbbbb0000000000000000
bbb9abbbbbbbbbbb77777777baaaaa9bb888888be888888e688868866bbb6bb665556556bb66bbbb6bb6bbbbbb44447bbbbbbbbbbbbbbbbb0000000000000000
bbaaabbbbbbbbbbb71717171bbaaa9bbbb8888bbbe8888eb688688666bb6bb6665565566b6bb6bbb6bb6bbbbbbb44bbbbbbbbbbbbbbbbbbb0000000000000000
bbb9abbbbbbbbbbb17171717bbba9bbbbbb88bbbbbe88ebb686886866b6bb6b665655656b6bb6bbbb66bbbbbbbbaabbbbbbbbbbbbbbbbbbb0000000000000000
bbaaabbbbbbbbbbbb777777bbbbbbbbbbbbbbbbbbbbeebbbb666666bb666666bb666666bbb66bbbbbbbbbbbbbbb44bbbbbbbbbbbbbbbbbbb0000000000000000
b000000bb000000bb000000bb000000bb000000bb000000bb555555b000000000000000000000000000000000000000000000000000000000000000000000000
004444000044440000000000000000000000044b0000044b55666655000000000000000000000000000000000000000000000000000000000000000000000000
007e7e00007e7e000000000000000000000047eb000047eb55727255000000000000000000000000000000000000000000000000000000000000000000000000
dddd440bdddd440bb000000db000000db004444db004444d7777665b000000000000000000000000000000000000000000000000000000000000000000000000
dffd887bdffd887bb788887db788887db788887db788887d7557557b000000000000000000000000000000000000000000000000000000000000000000000000
dffd994bdffd994bb499994db499994db499994db499994d7557006b000000000000000000000000000000000000000000000000000000000000000000000000
bdd880bbbdd888bbbb8880dbbb0888dbbb8888bdbb8888bdb77555bb000000000000000000000000000000000000000000000000000000000000000000000000
bb0bbbbbbbbbb0bbbb0bbbbbbbbbb0bbbb0bb0bbbbb00bbbbb0bb0bb000000000000000000000000000000000000000000000000000000000000000000000000
bbb77bbbbbbbbbbbbbbbbbbbbbbbffbbbb1111bbbb1111bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb77bbbbbbbbbbbbbbbbbbbbbbb8fbbb1111e1bb1111e1b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb77bbbbbdbbbbbbbf888ffbbbb88bb111111e1111111e100000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb77bbbffd77777bb8f888fbbbb88bb111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb77bbbffd77777bb88bbbbf888f8bb111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
bbddddbbbbdbbbbbbb88bbbbff888fbb111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbffbbbbbbbbbbbbbf8bbbbbbbbbbbbb111111bb111111b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbffbbbbbbbbbbbbbffbbbbbbbbbbbbbb1111bbbb1111bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbb8888bbbb8888bb8888bbbbbbbb88888b98b9bbb98bb8bb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbb8888bbb877778bb877778b8778bbbbbbbb8778b98bb89bb89b898b0000000000000000000000000000000000000000000000000000000000000000
bb8888bbbb8878bb87771178877711788718bbbbbbbb8178b999999bb888888b0000000000000000000000000000000000000000000000000000000000000000
b888788bb888878b877711788777117888888bbbbbb8888889899989989888980000000000000000000000000000000000000000000000000000000000000000
b888878bb888888b8777777887777778bbb8888888888bbb89989899988989880000000000000000000000000000000000000000000000000000000000000000
88888888b888888b8777777887777778bbbb87788778bbbb89999999988888880000000000000000000000000000000000000000000000000000000000000000
98888889b988889bb877778bb877778bbbbb87188178bbbbb8998899b98899880000000000000000000000000000000000000000000000000000000000000000
b988889bbb9889bbbb8888bbbb8888bbbbbb88888888bbbbbb89999bbb98888b0000777700000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000777700077777007770707000770000077000000000000000000000000000
bbbbbbbbbb8888bb0000000000000000000000000000000000000000000000000007700770070707000700707007007070700000000000000000000000000000
bb8888bbbb8878bb0000000000000000000000000000000000000000000000000007700770070707000700707007007070700000000000000000000000000000
b888788bb888878b0000000000000000000000000000000000000000000000000077000077070707000700770007777000070000000000000000000000000000
b888878bb888888b0000000000000000000000000000000000000000000000000077000077070707000700707007007000007000000000000000000000000000
88888888b888888b0000000000000000000000000000000000000000000000000077000077070707000700707007007000007000000000000000000000000000
98888889b988889b0000000000000000000000000000000000000000000000000077000077070707007770707007007000770000000000000000000000000000
b988889bbb9889bb0000000000000000000000000000000000000000000000000077000077000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000077000077000600700707077700770777000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000077000077111657575757577557555575500000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000077000077111657755757575555575575550000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000077000077000600770077077707700070000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000077000077000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000055555555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0000677700000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00006777000000000000000000000000000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
00677777770000000000000000000000000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
00677777770000000000000000000000000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
00677777770000000000000000000000000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
06777006777000000000000000000000000000067000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
06777006777000000000000000000000000000007000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
06777006777000077777700067700670670077700067770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700677777770067700670670677770067770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700670670670067700670670670670067000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700670670670067700670670670670067000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700670670670067700670670670670067770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700670670670067700677700677770067770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700670670670067700677770670670000770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67777777777700670670670067700670670670670000770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67777777777700670670670067700670670670670000770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67777777777700670670670067700670670670670067770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700670670670067700670670670670067770000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700000000000000000000000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700000000000700707077700770777000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700000060007070707070007000070000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700111165557575757577557775575555500000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700111165557755757575555575575555550000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
67770000677700000060000770077077707700070000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001
00000011000000110000001100000011000000110000001100000011000000110000001100000011000000110000001100000011000000110000001100000011
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
01111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000677700000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000067777777000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000067777777000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000067777777000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000677700677700000000000000000000000000006700000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000677700677700000000000000000000000000000700000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000677700677700007777770006770067067007770006777000000000000000000000000000000000001111111
11111111000000000000000000000000000000006777000067770067777777006770067067067777006777000000000000000000000000000000000011111111
00000001000000000000000000000000000000006777000067770067067067006770067067067067006700000000000000000000000000000000000000000001
00000011000000000000000000000000000000006777000067770067067067006770067067067067006700000000000000000000000000000000000000000011
00555511000000000000000000000000000000006777000067770067067067006770067067067067006777000000000000000000000000000000000000555511
00555511000000000000000000000000000000006777000067770067067067006770067770067777006777000000000000000000000000000000000000555511
00555511000000000000000000000000000000006777000067770067067067006770067777067067000077000000000000000000000000000000000000555511
00555511000000000000000000000000000000006777777777770067067067006770067067067067000077000000000000000000000000000000000000555511
01111111000000000000000000000000000000006777777777770067067067006770067067067067000077000000000000000000000000000000000001111111
11111111000000000000000000000000000000006777777777770067067067006770067067067067006777000000000000000000000000000000000011111111
00000001000000000000000000000000000000006777000067770067067067006770067067067067006777000000000000000000000000000000000000000001
00000011000000000000000000000000000000006777000067770000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000006777000067770000000000070070707770077077700000000000000000000000000000000000000000555511
00555511000000000000000000000000000000006777000067770000006000707070707000700007000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000006777000067770011116555757575757755777557555550000000000000000000000000000000000000555511
00555511000000000000000000000000000000006777000067770011116555775575757555557557555555000000000000000000000000000000000000555511
01111111000000000000000000000000000000006777000067770000006000077007707770770007000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
00555511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555511
01111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001
00000011000000110000001100000011000000110000001100000011000000110000001100000011000000110000001100000011000000110000001100000011
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
00555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511005555110055551100555511
01111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0011001903140011000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041414040000040400000000000000000414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0707070707070707070707070707070701000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0767676767676767676767676767670700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070701000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001
0100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
003200000413005130041300513004130051300413005130041300513004130051300413005130041300513004130051300413005130041300513004130051300413005130041300513004130051300413005130
0002000033550385503a5500050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000
000900002f33034340003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000600000256006560005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00320000000000000000000000000000000000000000000021730217302173021730217302173021730217301f7301f7301f7301f7301f7301f7301f7301f7302173021730217302173221732217322172221715
003200000000000000000000000000000000000000000000170201702017020170201702017020170201702015020150201502015020150201502015020150201702017020170201702017020170201701017015
00320000000000000000000000000000000000000000000021730217302173021730217302173021730217301f7301f7301f73021730217302273022730227302273022730227302273222732227322272222725
013200000000000000000000000000000000000000000000170201702017020170201702017020170201702015020150201502017020170201802018020180201802018020180201802018020180201801018015
0132000004130051300a1300913004130051300a1300913004130051300a1300913004130051300a1300913004130051300a1300913004130051300a1300913004130051300a1300913004130051300a13009130
013200000000000000000000000000000000000000000000267302673024730247302673028730287300000029730297302b7302b7302d7302d7302d7302d7302e7302e7302e7302d7302d7302d7302d7202d715
0132000000000000000000000000000000000000000000001b0201b02019020190201b0201d0201d020000001e0201e0202002020020220202202022020220202302023020230202702027020270202701027015
001000002615028150291502a1502b1500010000100001002615026150261502615000100001000010023150181052315023150181001f150231501810018100181001f1501f1501f1521f1421f1321f1221f112
0010000000000000000000000000230500000000000000001f0501f0501f0501f05000000000000000021050000001f0501f050000001a0501f05000000000000000017050170501705217042170321702217012
001000000000000000000000000007430000000000000000072300723007230072300040000000000000223000000022300223000000022300223000000000000000007230072400725007260072700000000000
0018000000000000000000000000000000000000000000001a25000000172501725000000152501525013250172500000015250152500000015250152501325017250000000e2500e25000000152501525013250
001800000715502155071550215507155021550715502155071550215507155021550715502155071550215507155021550715502155071550215507155021550715502155071550215507155021550715502155
0018000017250000000e2500e250152511525213252132521a25000000172521725200000152521525213250172500000015252152520000015252152521325017250000000e2520e25215251152521325213252
001800001325213252132421324213232132321322300000175500050013550135500050013550135500e550135500070013550135500050012550125500e550135500050006550065500050012550125500e550
001800001355000500125501255012551125520e5520e552175500050013552135520050013552135520e550135500050013552135520050012552125520e550135500050012552125520f5510f5521055210552
0018000017250000001325013250000001225012250102501325000000122501225000000122501225010250132500000012250122500f2500f25010250102501725000000132501325000000122501225010250
001800000415507155041550715504155071550415507155041550715504155071550415507155041550715504155071550415507155041550715504155071550415507155041550715504155071550415507155
0018000013250000001225012250000001225012250102501325000000122501225000000122501225010250132500000012250122500f2500f25010250102501325013250122501225012250122500000000000
001800000d00010000140001b0001900015000120000f00000000000000000000000000000000000000000000000000000000000000021550215501f5501f550175501755015550155500e2560e2561325613256
001d00000d75010750147501b7501975015750127500f7500d75010750147501b7501975015750127500f7500b7500f750127501b7501975015750127500f750097500d750107501b7501975015750127500f750
001d00001b5501b5501b5501b5501b5501b5501b5501b5501b5501b5501b5501b5501b5501b5501b5501b55019550195501955015550155501555014550155501455014550145501455014550145501455014550
001d00001455014550145501455014550145501455014550145501454014530145201451200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001d0000002000020000200002000020000200002000020000200002000020000200002000020000200002001b2251b225002001b220002001b220002001b2251922519225002001922000200192200020019225
001d0000002000020000200002000020000200002000020000200002000020000200002000020000200002001e2251e225002001e220002001e220002001e2251c2251c225002001c220002001c220002001c225
001d000019225192250020019220002001922000200192251c2251c225002001c220002001c220002001c22000200002000020000200002000020000200002000020000200002000020000200002000020000200
001d00001c2251c225002001c220002001c220002001c225202252022500200202200020020220002002022000200002000020000200002000020000200002000020000200002000020000200002000020000200
001600000000000000000000000000000000000000000000000000000000000000000000000000000001f000220512205022050220502205022050220552205522050210501f0502205021050210501a0501a050
001600000e2550e1550e1550e2550e1550e1550e2550e1550e2550e1550e1550e2550e1550e1550e2550e1550e2550e1550e1550e2550e1550e1550e2550e1550e2550e1550e1550e2550e1550e1550e2550e155
001600000725507155071550725507155071550725507155072550715507155072550715507155072550715507255071550715507255071550715507255071550725507155071550725507155071550725507155
001600001a0501a0501a0501a0501a0501a0501a0501a0501a0521a0521a0521a0521a0521a0521a0521a0520000000000000000000000000000000000000000000000000000000000000000000000000001f000
001600000525505155051550525505155051550525505155052550515505155052550515505155052550515505255051550515505255051550515505255051550525505155051550525505155051550525505155
00160000220512205022050220502205022050220552205522050210501f0502205021050210501a0501a05011150111501315013150151501515018150181502205022050220502205022050220502205522055
0016000026050260502605026050260502605026055260552605024050220502605024050240501d0501d0501a1501a1501c1501c1501d1501d15021150211502605126050260502605026050260502605526055
0016000022050210501f0502205021050210501a0501a05011150111501315013150151501515018150181501d0501d0501c0501c0501a0501a05018050180501a1321a132181321813216132161321513215150
001600002605024050220502605024050240501d0501d0501a1501a1501c1501c1501d1501d150211502115026050260502405024050220502205021050210502413224132221322213221132211321f1321f150
0016000022050210551f05522055210501f0551d055210551f0501d0551c0551f0551d0501c0551a0551d0550a1500c1550e15510155111501315515155171501811018120181321814218152181621817218172
00160000261502415522155261552415022155211552415522150211551f15522155211501f1551d15521155131501515516155181551a1501c1551d155201502111021120211322114221152211622117221172
00070000006000e670006001b67000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000700001c67400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604
000300000315006150001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000700001967500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
000200001a57111571005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
__music__
01 00040544
00 00060744
02 08090a44
00 0b0c0d44
01 0e42430f
00 1042430f
00 0e11430f
00 1012430f
00 13614314
02 15164314
01 68424317
00 18424317
00 191a1b17
00 1c1d1b17
02 181a1c17
01 1e421f20
00 21421f22
00 23241f20
00 25261f22
02 27281f22

