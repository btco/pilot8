pico-8 cartridge // http://www.pico-8.com
version 16










































































__lua__
-- pilot8
-- bruno oliveira
--
-- this source code is pre-processed
-- (comments removed and constants inlined)
-- for the more readable original, check:
--   https://github.com/btco/pilot8


local k_lit_clip_r={x=-25,y=-30,w=95,h=60}
local k_rnd=nil
local k_drop_int={300,200}
local k_cr_full={x=0,y=0,w=8,h=8}
local k_cr_plr={x=2,y=2,w=6,h=6}
local k_cr_ship={x=2,y=2,w=6,h=6}
local k_cr_hbar={x=2,y=3,w=6,h=2}
local k_cr_hbar_s={x=3,y=3,w=2,h=1}
local k_cr_dbl={x=1,y=2,w=6,h=3}
local k_cr_ball={x=3,y=3,w=2,h=2}
local k_cr_ball4={x=2,y=2,w=4,h=4}
local k_cr_pwup={x=0,y=0,w=8,h=7}
local k_mus_for_mode={
 [0]=5,
 [1]=0,
 [3]=7,
 [2]=10,
 [7]=11,
}
local g_mus=-1
local k_drop_sched={
 18,
 39,
 47,
 0,
}
local k_hint_char_color={
 ["\139"]=12,["\145"]=12,["\148"]=12,["\131"]=12,
 ["\142"]=11,["\151"]=8
}
local k_scrt_seq={11,7,5,3,2,1}
local g_scrt=nil
local g_lum=nil
local k_anim_die={div=6,fr={12,13,14,15,16,0}}
local k_anim_beacon={div=10,fr={0,30,31},loop=true}
local k_anim_spiky={div=4,fr={26,27},loop=true}
local k_anim_fireball=
  {div=2,fr={24,24},flip={0,1},loop=true}
local k_anim_torch={div=8,fr={122,123,123},loop=true}
local k_anim_lantern={div=8,fr={84,100,116},loop=true}
local k_anim_muzzle={div=2,fr={87,88,103,104},loop=false}
local k_lvl_templ_flood={
 title="flood city",
 bgc=112,bgr=48,bgh=12,
 thc=116,thr=29,
 cclr=0,
 lit=true,
 em={
  {anim=k_anim_beacon,x=0,y=88,cmap={[3]=2,[11]=8}},
  {anim=k_anim_beacon,x=32,y=88,cmap={[3]=4,[11]=9}},
  {anim=k_anim_beacon,x=88,y=88},
 },
 rip_clrs=0x11,
 max_enemies=3,
}
local k_lvl_templ_oasis={
 title="oasis city",
 lit=false,
 cclr=1,
 bgc=64,bgr=48,bgh=12,
 thc=116,thr=26,
 skfx={{sx=0,sy=72,c=64,r=61,w=16,h=3}},
 sun={x=64,y=134,r=48,clr=15},
 rip_clrs=0xdd,
 max_enemies=4,
}
local k_lvl_templ_marshes={
 title="marshes",
 lit=true,
 cclr=0,
 bgc=32,bgr=48,bgh=12,
 thc=116,thr=23,
 rip_clrs=0x00,
 em={
  {anim=k_anim_lantern,x=8,y=88},
  {anim=k_anim_lantern,x=48,y=88},
  {anim=k_anim_lantern,x=96,y=88},
 },
 rain=1,
 max_enemies=5,
}
local k_lvl_templ_coast={
 title="coast",
 lit=false,
 cclr=0,
 bgc=16,bgr=54,bgh=6,bgy=48,
 thc=104,thr=29,
 rip_clrs=0x11,
 skfx={
  {sx=0,sy=48,c=16,r=48,w=16,h=6},
  {sx=0,sy=0,c=16,r=61,w=16,h=3},
 },
 sun={x=64,y=114,r=32,clr=7},
 owfx={sx=0,sy=96,c=16,r=60,w=16,h=1},
 max_enemies=5,
}
local k_lvl_templ_canals={
 title="canals",
 lit=true,
 cclr=0,
 bgc=0,bgr=48,bgh=12,
 thc=104,thr=26,
 rip_clrs=0x11,
 em={
  {anim=k_anim_torch,x=8,y=88},
  {anim=k_anim_torch,x=4*8,y=88},
  {anim=k_anim_torch,x=7*8,y=88},
  {anim=k_anim_torch,x=9*8,y=88},
  {anim=k_anim_torch,x=12*8,y=88},
  {anim=k_anim_torch,x=13*8,y=88},
 },
 max_enemies=6,
}
local k_lvl_templ_castle={
 title="castle",
 lit=true,
 cclr=0,
 bgc=48,bgr=48,bgh=12,
 thc=104,thr=23,
 rip_clrs=0x00,
 em={
  {anim=k_anim_torch,x=8,y=88},
  {anim=k_anim_torch,x=40,y=88},
  {anim=k_anim_torch,x=56,y=88},
  {anim=k_anim_torch,x=88,y=88},
 },
 max_enemies=7,
}
local g_lvls={
 {
  templ=k_lvl_templ_flood,
  mapc=1,mapr=4,
  text="know how to fly? no? well,   \nwhat better way to learn than\non a real mission with real  \nenemies? good luck!          ",
 },
 {
  templ=k_lvl_templ_flood,
  mapc=3,mapr=4,
  rain=1,
  text="congratulations on not dying.\nyou exceeded our expectations\nplease continue with your    \ncurrent strategy of not dying",
 },
 {
  templ=k_lvl_templ_flood,
  mapc=5,mapr=4,
  text="bob left the gates open last \nnight and enemies returned to\nthe area. bob says sorry.",
 },
 {
  templ=k_lvl_templ_oasis,
  mapc=8,mapr=3,
  text="the oasis area has strategic \nsignificance to us. we don't \nknow why yet. but go reclaim \nit anyway. use sunscreen.    ",
 },
 {
  templ=k_lvl_templ_oasis,
  mapc=10,mapr=3,
  text="stellar performance! great...\noh? you are pilot 8, not 9.  \nsorry, nevermind. how awkward\noff you go. good luck.       ",
 },
 {
  templ=k_lvl_templ_oasis,
  mapc=12,mapr=3,
  text="leadership accepted a statue \nof a horse as a gift from the\nenemy. in an unrelated event,\nsomehow the enemies got in.  ",
 },
 {
  templ=k_lvl_templ_marshes,
  mapc=1,mapr=8,
  rain=1,
  text="it's a great night to stay by\nthe fireplace. so leadership \nwill stay by the fireplace   \nwhile you go do the work.    ",
 },
 {
  templ=k_lvl_templ_marshes,
  mapc=3,mapr=8,
  text="bad news: the cheap defenses \nwe set up were not waterproof\nso the enemies are back. go  \nreclaim the area for us.     ",
 },
 {
  templ=k_lvl_templ_marshes,
  mapc=5,mapr=8,
  text="the last pilot was supposed  \nto reclaim this area but got \nrecruited by a startup and   \nleft. it's up to you now.    ",
 },
 {
  templ=k_lvl_templ_coast,
  mapc=10,mapr=9,
  text="the pilot we hired turned out\nto be a werewolf so he can't \nfly under a full moon. so    \nyou will have to go instead. ",
 },
 {
  templ=k_lvl_templ_coast,
  mapc=12,mapr=9,
  text="bob sent an email to the     \nwrong mailing list and gave  \naway our coordinates, so the \nenemies found us. thanks bob.",
 },
 {
  templ=k_lvl_templ_coast,
  mapc=14,mapr=9,
  text="the ideal vacation spot!     \nthe beach, the waves, ....   \nexcept there are a bunch of  \nenemies, so take care of that",
 },
 {
  templ=k_lvl_templ_canals,
  text="we needed the area due to its\ncanals, but remembered we're \na spacefaring society with no\nuse for canals. get it anyway",
  mapc=2,mapr=13,
 },
 {
  templ=k_lvl_templ_canals,
  mapc=4,mapr=13,
  rain=1,
  text="we mistook ourselves for the \nenemy so we left the area to \nclear it of enemies. then the\nreal enemies took it from us.",
 },
 {
  templ=k_lvl_templ_canals,
  mapc=6,mapr=13,
  text="alex set the alarm to 7pm not\n7am so we overslept and lost \nthe area to enemies. they are\nvery punctual, unlike alex.  ",
 },
 {
  templ=k_lvl_templ_castle,
  mapc=9,mapr=13,
  text="leadership wants a castle in \norder to fortify our defenses\nit worked in the middle ages \nso it seems like a good idea.",
 },
 {
  templ=k_lvl_templ_castle,
  mapc=11,mapr=13,
  text="because they are all spelled \nsimilarly, leadership has    \ninvaded the wrong casle. now \ngo conquer the right one.    ",
 },
 {
  templ=k_lvl_templ_castle,
  mapc=13,mapr=13,
  rain=1,
  text="okay, that wasn't the right  \ncastle either but this time  \nwe are really sure. last one!\ngood luck, pilot 8!          ",
 },
}
local k_weap_info={
 [0]={
  init_ammo={-1,-1,-1},
  shot_eid=1000,
  off_x={-6,6},off_y=0,
  sfx=10,
  fire_cds={12,9,6},
  hud_icon=17,
  clr=12,
 },
 [1]={
  init_ammo={5,7,10},
  shot_eid=38,
  off_x={-6,6},off_y=0,
  sfx=15,
  fire_cds={20,15,10},
  hud_icon=18,
  clr=11,
 },
 [2]={
  init_ammo={50,60,70},
  shot_eid=1002,
  off_x={-6,6},off_y=0,
  sfx=15,
  fire_cds={5,4,3},
  hud_icon=47,
  clr=14,
 },
}
local g_mode=0
local g_clk_sec=0
local g_clk=0
local g_aclk=0
local g_sav=nil
local g_sav_templ={
 lvl=1,
 coins=0,
 upgrades=0,
 coins_collected=0,
 coins_spent=0,
 enemies_killed=0,
 levels_played=0,
 deaths=0,
 powerups_collected=0,
 gameplay_minutes=0,
}
local g=nil
local k_g_template={
 lvl_no=-1,
 lvl=nil,
 cmd_cd=0,
 next_cmd=0,
 play_clk=0,
 lit_clip={x=0,y=0,w=0,h=0},
 drop_cd=k_drop_int[1],
 x=10,y=40,
 vx=0,vy=0,
 facing=1,
 xcr=nil,
 fire_cd=0,
 weap=0,
 weap_info=k_weap_info[0],
 ammo=-1,
 shield=0,
 shield_anim_cd=0,
 hurt_cd=0,
 ents={},
 num_enemies=0,
 num_pwups=0,
 num_en_projs=0,
 end_cd=nil,
 muzzle_cc=nil,
}
local k_dmg_cmap={}
for i=1,7 do add(k_dmg_cmap,7) end
local g_sstate={
 sel=1,
 map={
  sel_lvl=nil,
  prompt=false,
 },
 shop={
  mode=0,
  scr_y=0,
  avail=nil,
 }
}
local k_upgrade_entries={
 {
  upf=0x0002,
  title="rapid fire i",
  desc="faster lasers",
  price=10,
 },
 {
  upf=0x0004,
  title="rapid fire ii",
  desc="even faster lasers",
  price=20,
  dep=0x0002,
 },
 {
  upf=0x0010,
  title="ammo i",
  desc="increased ammo",
  price=10,
 },
 {
  upf=0x0020,
  title="ammo ii",
  desc="even more ammo",
  price=20,
  dep=0x0010,
 },
 {
  upf=0x0080,
  title="shield i",
  desc="start with shield",
  price=15,
 },
 {
  upf=0x0100,
  title="shield ii",
  desc="start with 2x shield",
  price=20,
  dep=0x0080,
 },
 {
  upf=0x0200,
  title="shield iii",
  desc="start with 3x shield",
  price=30,
  dep=0x0100,
 },
 {
  upf=0x0400,
  title="green laser",
  desc="start with green laser",
  price=30,
 },
 {
  upf=0x0800,
  title="more powerups",
  desc="get powerups more often",
  price=15,
 },
}
local k_e_template={
 eid=0,
 sp=nil,
 x=0,y=0,
 vx=0,vy=0,
 age=0,
 facing=-1,
 face_plr=false,
 bounce_x=false,
 vx_div=1,vy_div=1,
 cr=k_cr_full,
 dead=false,
 em_sp=nil,
 ttl=nil,
 blink_ttl=nil,
 fires=false,
 fire_eid=1001,
 fire_projs={
  {off_x_left=-6,off_x_right=6,off_y=0,vx_facing=true}
 },
 fire_int_min=60,fire_int_max=100,
 fire_cd=nil,
 dmg_plr=nil,
 dmg_en=nil,
 dmg_cd=0,
 hp=nil,
 anim=nil,
 em_anim=nil,
 enemy=false,
 en_proj=false,
 cmap=nil,
 zigzags=false,
 zigzag_v=1,
 spawn_y=nil,
}
local g_ent_defs={
 [0]={},
 [1]={em_sp=17},
 [1000]={
  sp=0,
  em_sp=2,
  vx=5,
  cr=k_cr_hbar,
  ttl=25,
  dmg_en=1,
 },
 [1001]={
  sp=0,
  em_anim={fr={9,46},div=4,loop=true},
  vx=-1,
  cr=k_cr_hbar_s,
  dmg_plr=1,
  ttl=100,
  en_proj=true,
 },
 [7]={
  em_sp=8,
  enemy=true,
  cr=k_cr_ship,
  vx=-1,
  vx_div=2,
  vy_div=2,
  fire_int_min=30,
  fire_int_max=45,
  bounce_x=true,
  zigzags=true,
  dmg_plr=1,
  hp=3,
  face_plr=true,
 },
 [12]={
  sp=0,
  ttl=5,
  vx=-1,vx_div=2,
 },
 [22]={
  em_sp=23,
  enemy=true,
  vx=-1,
  vx_div=3,
  bounce_x=true,
  cr=k_cr_half,
  fires=true,
  fire_eid=24,
  fire_projs={
   {off_x_left=-1,off_x_right=2,off_y=-2,vx_facing=true},
  },
  fire_int_min=55,
  fire_int_max=75,
  dmg_plr=1,
  hp=3,
  face_plr=true,
  spawn_y=96-8,
 },
 [24]={
  em_anim=k_anim_fireball,
  vy=-1,
  vx=-1,
  vx_div=2,
  vy_div=2,
  cr=k_cr_ball,
  dmg_plr=1,
  ttl=120,
  en_proj=true,
 },
 [10]={
  em_sp=11,
  enemy=true,
  cr=k_cr_ship,
  fires=true,
  fire_int_min=40,fire_int_max=60,
  laser_clr=10,
  bounce_x=true,
  zigzags=true,
  vx=-1,
  vx_div=3,
  vy_div=2,
  dmg_plr=1,
  hp=3,
  face_plr=true,
 },
 [18]={
  em_sp=37,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 [47]={
  em_sp=112,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 [38]={
  sp=0,
  em_sp=38,
  vx=3,
  cr=k_cr_dbl,
  ttl=25,
  dmg_en=3,
 },
 [39]={
  em_sp=40,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 [20]={
  em_sp=42,
  enemy=true,
  cr=k_cr_ship,
  fires=true,
  fire_int_min=30,fire_int_max=45,
  laser_clr=8,
  bounce_x=true,
  vx=-1,
  vx_div=30,
  dmg_plr=1,
  hp=9,
  zigzags=true,
  face_plr=true,
 },
 [1]={
  em_sp=1,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 [21]={
  em_anim=k_anim_spiky,
  enemy=true,
  cr=k_cr_ball4,
  fires=true,
  fire_eid=24,
  fire_int_min=30,fire_int_max=45,
  fire_projs={
   {off_x=-1,off_y=-1,vx=-1,vy=-1},
   {off_x=-1,off_y=2,vx=-1,vy=1},
   {off_x=2,off_y=-1,vx=1,vy=-1},
   {off_x=2,off_y=2,vx=1,vy=1},
  },
  laser_clr=8,
  bounce_x=true,
  vx=-1,
  dmg_plr=1,
  hp=1,
  zigzags=true,
 },
 [43]={
  em_sp=45,
  anim={fr={43,44},div=2,loop=true},
  enemy=true,
  cr=k_cr_ship,
  fires=true,
  fire_int_min=15,fire_int_max=30,
  laser_clr=11,
  bounce_x=true,
  vx=-1,
  vx_div=2,
  dmg_plr=1,
  hp=15,
  zigzags=true,
  zigzag_v=1,
  face_plr=true,
 },
 [1002]={
  sp=0,
  em_sp=9,
  vx=3,
  cr=k_cr_hbar,
  ttl=25,
  dmg_en=1,
  cmap={[12]=14},
 },
}
local g_loaded_data=false
function _init()
 cartdata("btco_pilot8_v1")
 init_rnd()
 init_lvls()
 load_data()
 init_lum()
 set_mode(0)
end
function init_rnd()
 k_rnd={}
 for i=1,64 do
  add(k_rnd,irnd_incl(0,31))
 end
end
function init_lvls()
 for i=1,#g_lvls do
  local lvl=g_lvls[i]
  g_lvls[i]=overlay(lvl.templ,lvl)
  g_lvls[i].templ=nil
 end
 local last_lvl=nil
 for r=0,31,6 do
  for c=0,128 do
   local t=mget(c,r)
   if t==113 then
    local lvl_no_tens=meta_value(mget(c,r+1))
    local lvl_no_ones=meta_value(mget(c,r+2))
    assert(lvl_no_tens and lvl_no_ones)
    local lvl_no=lvl_no_tens*10+lvl_no_ones
    last_lvl=g_lvls[lvl_no]
    last_lvl.mc0=c
    last_lvl.mr0=r
   elseif t==48+15 and last_lvl then
    last_lvl=nil
   end
  end
  last_lvl=nil
 end
 for lvl in all(g_lvls) do
  assert(lvl.mc0 and lvl.mr0)
 end
end
function _update()
 g_clk_sec+=0x0.08
 g_clk=band(g_clk+1,0x7fff)
 g_aclk=band(g_aclk+1,0x7fff)
 g_btn_left,g_btn_right,g_btn_up,g_btn_down,g_btn_x,g_btn_o=
   btn(0),btn(1),btn(2),
   btn(3),btn(5),btn(4)
 g_btnp_left,g_btnp_right,g_btnp_up,g_btnp_down,g_btnp_x,g_btnp_o=
   btnp(0),btnp(1),btnp(2),
   btnp(3),btnp(5),btnp(4)
 if g_aclk%225==224 then g_sav.gameplay_minutes+=0.125 end
 local fun=g_update_fun[g_mode]
 assert(fun)
 fun()
end
function update_title()
 if g_btnp_o then
   set_mode(3)
 end
end
function update_play()
 g.play_clk=g_clk
 update_plr()
 update_lvl()
 update_ents()
 collide_ents()
end
function update_dying()
 if g_clk_sec>4 then
  set_mode(3)
 end
end
function update_hangar()
 local h=g_sstate
 local dx,dy=get_dpadp()
 h.sel=mid(h.sel+dy,1,4)
 if g_btnp_o then
  if h.sel==1 then
   start_lvl(g_sav.lvl)
  elseif h.sel==2 then
    start_map()
  elseif h.sel==3 then
   start_shop()
  elseif h.sel==4 then
   set_mode(6)
  end
 elseif g_btnp_x then
  set_mode(0)
 end
end
function start_map()
 local state=g_sstate.map
 state.sel_lvl=g_sav.lvl
 state.prompt=false
 set_mode(5)
end
function start_shop()
 local shop=g_sstate.shop
 shop.scr_y=0
 shop.mode=0
 shop.avail={}
 for i=1,#k_upgrade_entries do
  local e=k_upgrade_entries[i]
  if not has_upgrade(e.upf) then
   if not e.dep or has_upgrade(e.dep) then
    add(shop.avail,e)
   end
  end
 end
 set_mode(4)
end
function update_shop()
 local shop=g_sstate.shop
 local sel_entry=#shop.avail>0 and
   shop.avail[g_sstate.sel] or nil
 if shop.mode==1 then
  if g_btnp_x then
   shop.mode=0
   return
  end
  if g_btnp_o then
   grant_upgrade(sel_entry.upf)
   g_sav.coins=max(0,g_sav.coins-sel_entry.price)
   g_sav.coins_spent+=sel_entry.price
   save_data()
   shop.mode=3
  end
  return
 elseif shop.mode==2 then
  if g_btnp_x or g_btnp_o then
   shop.mode=0
  end
  return
 elseif shop.mode==3 then
  if g_btnp_x or g_btnp_o then
   start_shop()
  end
  return
 end
 assert(shop.mode==0)
 local sel_spos=
   (g_sstate.sel-1)*24+shop.scr_y
 if sel_spos<0 then
  shop.scr_y=min(0,shop.scr_y+4)
 elseif sel_spos>24*3 then
  shop.scr_y-=4
 end
 if g_btnp_x then
  set_mode(3)
  return
 end
 if #shop.avail==0 then return end
 local dx,dy=get_dpadp()
 g_sstate.sel=mid(g_sstate.sel+dy,1,#shop.avail)
 if g_btnp_o then
  shop.mode=sel_entry.price>g_sav.coins and
    2 or 1
 end
end
function update_map()
 local state=g_sstate.map
 if state.prompt then
  if g_btnp_o then
   start_lvl(state.sel_lvl)
   return
  end
  if g_btnp_x then
   state.prompt=false
   return
  end
 end
 if g_btnp_o then
  if state.sel_lvl~=g_sav.lvl then
   state.prompt=true
   return
  else
   set_mode(3)
  end
 elseif g_btnp_x then
  set_mode(3)
  return
 end
 local dx,dy=get_dpadp()
 state.sel_lvl=mid(state.sel_lvl+dx,1,g_sav.lvl)
end
function update_ents()
 local ents=g.ents
 local num_enemies,num_pwups,num_en_projs=0,0,0
 for i=#ents,1,-1 do
  local e=ents[i]
  ent_update(e)
  if e.dead then
   fast_del(ents,i)
  elseif e.enemy then
   num_enemies+=1
  elseif e.en_proj then
   num_en_projs+=1
  elseif e.pwup then
   num_pwups+=1
  end
 end
 g.num_enemies=num_enemies
 g.num_pwups=num_pwups
 g.num_en_projs=num_en_projs
end
function collide_ents()
 local ents=g.ents
 for i=1,#ents do
  local e=ents[i]
  if e.dmg_plr then check_coll_dmg_plr(e) end
  if e.dmg_en then check_coll_dmg_en(e) end
  if e.pwup then check_coll_pwup(e) end
 end
end
function ent_get_cr(e)
 return rect_xlate(e.cr,e.x,e.y)
end
function check_coll_dmg_plr(e)
 if g.hurt_cd>0 then return end
 local ecr=ent_get_cr(e)
 local pcr=g.xcr
 if not rect_isct(ecr,pcr) then return end
 if g.shield>0 then
  g.shield-=1
  g.hurt_cd=40
  sfx(18)
 else
  start_dying()
 end
end
function check_coll_pwup(e)
 local ecr=ent_get_cr(e)
 local pcr=g.xcr
 if not rect_isct(ecr,pcr) then return end
 pickup_pwup(e)
 e.dead=true
end
function pickup_pwup(e)
 if e.eid==18 then
  pickup_weap(1)
 elseif e.eid==39 then
  pickup_shield()
 elseif e.eid==1 then
  pickup_coin()
 elseif e.eid==47 then
  pickup_weap(2)
 end
 g_sav.powerups_collected+=1
end
function pickup_weap(weap_id,play_sfx)
 play_sfx=play_sfx or true
 local wi=k_weap_info[weap_id]
 assert(wi)
 g.weap=weap_id
 g.weap_info=wi
 local upg_level=get_ammo_upg_lvl()
 g.ammo=wi.init_ammo[upg_level+1]
 if play_sfx and weap_id~=0 then
  sfx(16)
 end
end
function pickup_shield()
 g.shield=min(g.shield+1,3)
 g.shield_anim_cd=30
 sfx(17)
end
function pickup_coin()
 g_sav.coins+=1
 g_sav.coins_collected+=1
 save_data()
 sfx(19)
end
function start_dying()
 sfx(13)
 set_mode(2)
 g_sav.deaths+=1
end
function check_coll_dmg_en(e)
 local ents=g.ents
 local ecr=ent_get_cr(e)
 for i=1,#ents do
  local victim=ents[i]
  if victim.hp then
   local vcr=ent_get_cr(victim)
   if rect_isct(vcr,ecr) then
    e.dead=true
    hurt_enemy(victim,e.dmg_en)
   end
  end
 end
end
function hurt_enemy(target,dmg)
 target.hp-=dmg
 target.dmg_cd=3
 target.dead=target.dead or target.hp<1
 sfx(target.dead and 12 or 11)
 if target.dead then
  ent_add(12,target.x,target.y)
  maybe_drop_loot(target,target.x,target.y)
  g_sav.enemies_killed+=1
 end
end
function maybe_drop_loot(e,x,y)
 if g.drop_cd>0 then
  maybe_drop_coin(e,x,y)
  return
 end
 if g.num_pwups>2 then return end
 if g.weap~=0 then return end
 local i=irnd_incl(1,#k_drop_sched)
 if k_debug_force_drop then i=k_debug_force_drop end
 local eid=k_drop_sched[i]
 if not eid or eid==0 then
  maybe_drop_coin(e,x,y)
  return
 end
 ent_add(eid,x,y)
 g.drop_cd=k_drop_int[
   has_upgrade(0x0800) and 2 or 1]
end
function maybe_drop_coin(e,x,y)
 if rnd()<0.5 then
  ent_add(1,x,y)
 end
end
function update_lvl()
 g.drop_cd=max(g.drop_cd-1,0)
 g.cmd_cd=max(g.cmd_cd-1,0)
 g.end_cd=g.end_cd and max(g.end_cd-1,0) or nil
 if g.end_cd and g.end_cd<=0 then
  if g.lvl_no==#g_lvls then
   set_mode(7)
   return
  else
   g_sav.lvl=max(g_sav.lvl,g.lvl_no+1)
   save_data()
   set_mode(3)
   return
  end
 end
 if true and g_btn_up and
   g_btn_down and g_btnp_x then
  local ents=g.ents
  for e in all(ents) do
   e.dead=e.enemy or e.dead
  end
 end
 if g.cmd_cd<=0 and g_clk_sec>4 then
  lvl_exec_next_cmd()
 end
end
function update_plr()
 local dx,dy
 g.hurt_cd=max(0,g.hurt_cd-1)
 if g.hurt_cd>flr(40/2) then
  dx,dy=-1,0
 else
  local ax,ay=get_dpad()
  if g_clk%2==0 then
   g.vx=apply_acc(g.vx,ax)
   g.vy=apply_acc(g.vy,ay)
  end
  dx,dy=g.vx,g.vy
 end
 g.x=mid(g.x+dx,0,120)
 g.y=mid(g.y+dy,0,96-8)
 g.xcr=rect_xlate(k_cr_plr,g.x,g.y)
 g.fire_cd=max(0,g.fire_cd-1)
 if g.fire_cd<1 and g_btn_o and g_clk_sec>1 then
  fire()
 end
 g.lit_clip=rect_xlate(k_lit_clip_r,g.x,g.y)
 if g.muzzle_cc then
  g.muzzle_cc+=1
  if g.muzzle_cc>k_anim_muzzle.div*#k_anim_muzzle.fr then
   g.muzzle_cc=nil
  end
 end
end
function fire()
 local wi=g.weap_info
 local shot=ent_add(
   wi.shot_eid,
   g.x+wi.off_x[g.facing>0 and 2 or 1],
   g.y+wi.off_y)
 shot.vx=g.facing*abs(shot.vx)
 sfx(wi.sfx)
 local upg_lvl=get_rapid_fire_upg_lvl()
 g.fire_cd=wi.fire_cds[upg_lvl+1]
 g.muzzle_cc=0
 if g.ammo>0 then
  g.ammo-=1
  if g.ammo<1 then
   pickup_weap(0)
  end
 end
end
function get_rapid_fire_upg_lvl()
 return has_upgrade(0x0004) and 2 or
   has_upgrade(0x0002) and 1 or 0
end
function get_ammo_upg_lvl()
 return has_upgrade(0x0020) and 2 or
   has_upgrade(0x0010) and 1 or 0
end
function get_shield_upg_lvl()
 return has_upgrade(0x0200) and 3 or
   has_upgrade(0x0100) and 2 or
   has_upgrade(0x0080) and 1 or 0
end
function lvl_exec_next_cmd()
 if g.end_cd then return end
 local c0,r0=g.lvl.mc0+g.next_cmd,g.lvl.mr0
 local marker=c0<128 and mget(c0,r0) or 113
 if g.next_cmd>0 and marker==113 or
     marker==48+15 then
  if can_end_lvl() then
   g.end_cd=100
   music(13)
  else
   g.cmd_cd=30
  end
  return
 end
 if lvl_spawn(c0,r0) then
  g.next_cmd+=1
 end
 g.cmd_cd=30
end
function can_end_lvl()
 if g.num_enemies>0 then return false end
 if g.num_pwups>0 then return false end
 for e in all(g.ents) do
  if e.dmg_plr then return false end
 end
 return true
end
function lvl_spawn(c0,r0)
 local count=0
 for r=r0,r0+6-1 do
  local eid=mget(c0,r)
  if eid>0 and not meta_value(eid) then
   count+=1
  end
 end
 if g.num_enemies>0 and count+g.num_enemies>g.lvl.max_enemies then
  return false
 end
 for r=r0,r0+6-1 do
  local eid=mget(c0,r)
  if is_spawnable(eid) then
   local x,y=128,(r-r0)*16
   local ent=ent_add(eid,x,y)
   ent.y=ent.spawn_y and ent.spawn_y or ent.y
  end
 end
 return true
end
function is_spawnable(eid)
 return eid>0 and not meta_value(eid) and
   eid~=113
end
function _draw()
 local fun=g_draw_fun[g_mode]
 assert(fun)
 fun()
 if g_scrt then draw_scrt() end
end
function draw_play()
 local lvl=g.lvl
 local lit=g.lvl.lit
 local skfx=g.lvl.skfx
 local cclr=lvl.cclr
 if lvl.rain then
  local p=band(shr(g_aclk,2),0x7f)
  if p==50 or p==52 then
   lit=false
   cclr=1
  end
 end
 cls(cclr)
 if lit then
  clip(g.lit_clip.x,g.lit_clip.y,
    g.lit_clip.w,g.lit_clip.h)
 end
 if skfx then
  for si=1,#skfx do
   local fx=skfx[si]
   map(fx.c,fx.r,fx.sx,fx.sy,fx.w,fx.h)
  end
 end
 if lvl.sun then
  circfill(lvl.sun.x,lvl.sun.y,lvl.sun.r,lvl.sun.clr)
 end
 local bg_off=get_bg_off()
 local bgy=lvl.bgy or 0
 map(lvl.bgc,lvl.bgr,-bg_off,bgy,16,lvl.bgh)
 map(lvl.bgc,lvl.bgr,128-bg_off,bgy,16,lvl.bgh)
 local ents=g.ents
 for e in all(ents) do
  e.sp=e.sp or e.eid
  draw_ent(e,false)
 end
 if g_mode==1 then
  draw_plr()
 end
 if lvl.rain then draw_rain(lvl.rain) end
 if lit then postproc_light() end
 if lit then clip() end
 for e in all(ents) do draw_ent(e,true) end
 draw_lvl_em_ovelays()
 postproc_water()
 if lvl.owfx then
  local fx=lvl.owfx
  map(fx.c,fx.r,fx.sx-bg_off,fx.sy,fx.w,fx.h)
  map(fx.c,fx.r,fx.sx-bg_off+128,fx.sy,fx.w,fx.h)
 end
 draw_hud()
 if g_mode==1 and
   g_clk_sec<4 then
  draw_lvl_title()
 end
 if g.end_cd then
  print_c("level clear",64,16,11)
 end
end
function draw_rain(clr)
 local i=1
 for r=0,8 do
  for c=0,8 do
   local x,y=c*16+k_rnd[1+i%#k_rnd]%16,r*16+k_rnd[1+(i+1)%#k_rnd]%16
   y=(y+g_aclk*2)%128
   pset(x,y,clr)
   pset(x,y+1,clr)
   i+=2
  end
 end
end
function draw_lvl_title()
 local left=4-g_clk_sec
 local c=(left<0.5 and 5) or (left<1 and 6) or 7
 print_c("sector " .. g.lvl_no,64,8,c)
 print_c(g.lvl.title,64,16,c)
 if g.lvl_no==1 then
  print_with_btn("\142 [z]: shoot",40,100,7)
 end
end
function draw_plr()
 if band(g.hurt_cd,4)~=0 then return end
 if g.shield>0 then
  g.shield_anim_cd=max(0,g.shield_anim_cd-1)
  if band_nz(g.shield_anim_cd,2) then pal(3,13) end
  if band_nz(g.shield_anim_cd,4) then pal(11,12) end
  spr(41,g.x,g.y,1,1,g.facing<0)
  pal()
 else
  spr(3,g.x,g.y,1,1,g.facing<0)
 end
 if g.muzzle_cc then
  draw_anim(k_anim_muzzle,g.x+4,g.y-1,g.muzzle_cc)
 end
end
function draw_ent(e,is_emi)
 if e.ttl and e.blink_ttl and e.ttl<=e.blink_ttl then
  if band(e.ttl,4)==0 then return end
 end
 if is_emi then
  if e.eid==12 then
   draw_kaboom(e.x,e.y,e.age)
  elseif e.dmg_cd>0 then
   draw_spr(e.sp,e.x,e.y,k_dmg_cmap,e.facing>0)
  elseif e.em_anim then
   draw_anim(e.em_anim,e.x,e.y,e.age,e.cmap,e.facing>0) 
  elseif e.em_sp then
   draw_spr(e.em_sp,e.x,e.y,e.cmap,e.facing>0)
  end
 else
  if e.anim then
   draw_anim(e.anim,e.x,e.y,e.age,e.cmap,e.facing>0)
  else
   draw_spr(e.sp,e.x,e.y,e.cmap,e.facing>0)
  end
 end
end
function draw_kaboom(x,y,age)
 if age<10 then
  circfill(x+4,y+4,4+flr(age/2),min(10,7+flr(age/2)))
 end
end
function draw_lvl_em_ovelays()
 local lvl=g.lvl
 if not lvl.em then return end
 local ems=lvl.em
 local bg_off=get_bg_off()
 for em in all(ems) do
  local x=em.x-bg_off
  if em.mc0 then
   map(em.mc0,em.mr0,x,em.y,16,em.mh)
   map(em.mc0,em.mr0,x+128,em.y,16,em.mh)
  else
   x=x<0 and 128+x or x
   if em.anim then
    draw_anim(em.anim,x,em.y,g_clk,em.cmap)
   else
    draw_spr(em.sp,x,em.y,em.cmap)
   end
  end
 end
end
function draw_spr(s,x,y,cmap,flip_x)
 if s==0 then return end
 if cmap then
  for k,v in pairs(cmap) do
   pal(k,v)
  end
 end
 spr(s,x,y,1,1,flip_x)
 pal()
end
function draw_anim(anim,x,y,clk,cmap,flip_x)
 local raw_fr=flr(clk/anim.div)
 local fr_no=anim.loop and (1+raw_fr%#anim.fr) or
   (min(1+raw_fr,#anim.fr))
 local fr=anim.fr[fr_no]
 local flip=anim.flip and anim.flip[fr_no] or
   (flip_x and 1 or 0)
 if fr>0 then draw_spr(fr,x,y,cmap,flip%2==1) end
end
function draw_hud()
 local wi=g.weap_info
 print("weap:",0,122,6)
 spr(wi.hud_icon,20,121)
 if g.ammo>=0 then
  if g.ammo>3 or band_nz(g_clk,4) then
   print(g.ammo,29,122,wi.clr)
  end
 else
  spr(19,28,121)
 end
 for i=1,g.shield do
  spr(39,40+8*i,121)
 end
 draw_coins()
end
function draw_coins()
 local v=g_sav.coins
 local x,y=120,123
 spr(1,x,y)
 local printed=false
 while not printed or v>0 do
  x-=4
  print(v%10,x,y,5)
  v=flr(v/10)
  printed=true
 end
end
function draw_title()
 local dy=max(64-g_clk*2,0)
 cls(0)
 clip(0,0,128,64)
 circfill(80,62,12,7)
 map(112,18,0,24,16,5)
 clip()
 draw_logo(dy)
 postproc_water(64)
 print_c("github.com/btco/pilot8",64,122,5)
 if g_clk>40 and band_nz(g_clk,8) then
  print_with_btn("press \142 [z]",42,110,7)
 end
 print("v1.1",110,1,5)
end
function draw_logo(y)
 local seq={6,6,7,12,6,6,6,6}
 for i=1,7 do
  pal(i,seq[1+band(i+shr(g_aclk,2),7)])
 end
 sspr(
  0,64,
  40,16,
  28,y,
  80,32
 )
 pal()
end
function draw_dying()
 local clr_seq={0,0,0,1,2,4,9,10}
 draw_play()
 draw_kaboom(g.x,g.y,g_clk)
 print_c("you died",64,20,
   clr_seq[min(#clr_seq,1+flr(g_clk/2))])
end
function draw_hangar()
 cls(0)
 map(96,48,0,0,16,16)
 local next_lvl=g_lvls[g_sav.lvl]
 print_c("mission briefing",64,8,7)
 print("sector " .. g_sav.lvl .. ": " .. next_lvl.title,
   6,42,10)
 print(next_lvl.text,6,49,7)
 map(next_lvl.thc,next_lvl.thr,16,16,12,3)
 local menu_y=83
 local menu_x=30
 local ystride=10
 local sel=g_sstate.sel
 draw_list(
   {"start mission","world map","upgrade ship","stats"},
   sel,menu_x,menu_y,ystride,6,10)
 spr(3,menu_x-10,menu_y+ystride*(sel-1)-1)
 draw_hint("\148\131:select  \142:confirm")
 draw_coins()
end
function draw_map()
 local state=g_sstate.map
 cls(0)
 if state.prompt then pal(3,5) end
 map(80,48,0,0,16,16)
 print_c("world map",64,2,7)
 for i=1,#g_lvls do
  local lvl=g_lvls[i]
  local x,y=lvl.mapc*8,lvl.mapr*8
  if i<g_sav.lvl then
   spr(71,x,y)
  end
  if i==state.sel_lvl and (state.prompt or
    band(g_clk,8)==0) then
   spr(3,x,y)
  end
 end
 pal()
 if state.prompt then
  local box_x,box_y,box_w,box_h=16,40,96,30
  rectfill(box_x,box_y,box_x+box_w,box_y+box_h,3)
  rect(box_x,box_y,box_x+box_w,box_y+box_h,7)
  print("sector " .. state.sel_lvl,box_x+4,box_y+4,10)
  print("you already completed\n" ..
        "this level. replay it?",box_x+4,box_y+12,7)
  draw_hint("\142:play \151:cancel")
 else
  draw_hint("\139\145:move \142:choose \151:exit")
 end
end
function draw_hint(msg)
 rectfill(0,121,128,128,0)
 print_with_btn(msg,2,123,5)
end
function print_with_btn(msg,x,y,clr)
 for i=1,#msg do
  local c=sub(msg,i,i)
  local clr=k_hint_char_color[c] or clr 
  print(c,x,y,clr)
  x+=(k_hint_char_color[c] and 8 or 4)
 end
end
function draw_shop()
 local shop=g_sstate.shop
 local normal=(shop.mode==0)
 cls(normal and 1 or 0)
 if #shop.avail==0 then
  print("no more upgrades available\n" ..
    "you already have them all!",8,50,7)
  draw_hint("\142:ok")
  return
 end
 local x,y=8,24+shop.scr_y
 for i=1,#shop.avail do
  local e=shop.avail[i]
  local sel=(i==g_sstate.sel) and normal
  local clr=normal and 6 or 5
  local blink=normal and sel and band_nz(g_clk,8)
  if sel then spr(3,x,y) end
  print(e.title,x+10,y,sel and (blink and 10 or 7) or clr)
  spr(1,100,y)
  print(e.price,112,y,sel and 7 or clr)
  print(e.desc,x+10,y+8,sel and 7 or clr)
  y+=24
 end
 rectfill(0,0,128,12,6)
 print("available upgrades",8,4,0)
 local box_y,box_h=40,30
 local sel_entry=shop.avail[g_sstate.sel]
 if shop.mode==2 then
  rectfill(16,box_y,112,box_y+box_h,2)
  print("not enough chips! (  )\n" ..
    "collect more chips and\n" ..
    "try again",20,box_y+4,7)
  spr(1,95,box_y+3)
  rect(16,box_y,112,box_y+box_h,7)
  draw_hint("\142:dismiss")
 elseif shop.mode==1 then
  rectfill(16,box_y,112,box_y+box_h,4)
  print(sel_entry.title,20,box_y+4,10)
  print("buy for    " .. sel_entry.price .. "?",
    20,box_y+12,7)
  spr(1,53,box_y+11)
  rect(16,box_y,112,box_y+box_h,7)
  draw_hint("\142:confirm  \151:cancel")
 elseif shop.mode==3 then
  rectfill(16,box_y,112,box_y+box_h,3)
  print(sel_entry.title,20,box_y+4,10)
  print("upgrade applied!",20,box_y+12,7)
  rect(16,box_y,112,box_y+box_h,7)
  draw_hint("\142:dismiss")
 else
  draw_hint("\148\131:sel \142:buy \151:exit")
 end
 draw_coins()
end
function draw_list(list,sel_index,x0,y0,ystride,
    clr,clr_sel)
 for i=1,#list do
  local sel=(i==sel_index)
  print(list[i],x0,y0+ystride*(i-1),
    (sel and (band(g_clk,8)==0 and clr_sel or 7)
    or clr))
 end
end
function get_dpad()
 return g_btn_left and -1 or
  g_btn_right and 1 or 0,
  g_btn_up and -1 or
  g_btn_down and 1 or 0
end
function get_dpadp()
 return g_btnp_left and -1 or
  g_btnp_right and 1 or 0,
  g_btnp_up and -1 or
  g_btnp_down and 1 or 0
end
function postproc_light()
 local px,py=g.x,g.y
 local x0,xf=g.lit_clip.x,g.lit_clip.x+g.lit_clip.w-1
 local y0,yf=g.lit_clip.y,g.lit_clip.y+g.lit_clip.h-1
 x0,xf=mid(x0,0,127),mid(xf+1,0,127)
 y0,yf=mid(y0,0,127),mid(yf+1,0,127)
 for y=y0,yf do
  local dy=py-y
  local ptr=0x6000+y*64
  ptr+=flr(x0/2)
  for x=x0,xf,2 do
   local dx=x-px
   if abs(dy)<30 and dx>0 then
    dx*=0.4
   end
   local dist=dx*dx+dy*dy
   local light_lvl=flr(5-dist*0.005)
   local b=peek(ptr)
   b=light_b(light_lvl,b)
   poke(ptr,b)
   ptr+=1
  end
 end
end
function postproc_water(water_y)
 local water_y=water_y or 96
 local addr_w=0x6000+64*water_y
 local addr_r=addr_w
 local rip_c=(g and g.lvl and g.lvl.rip_clrs) or 0x11
 memset(addr_w,rip_c,64)
 for y=96+1,127 do
  addr_w+=64
  addr_r-=(y%2)*64
  local offset=1+(flr(g_clk/4)+y)%#k_rnd
  local prand=k_rnd[offset]
  if band_nz(prand,30) then
   memcpy(addr_w,addr_r+prand%2*64,64)
  else
   memset(addr_w,rip_c,64)
  end
 end
end
function start_lvl(lvl_no)
 assert(g_lvls[lvl_no])
 g=deep_copy(k_g_template)
 g.lvl_no=lvl_no
 g.lvl=g_lvls[lvl_no]
 g.next_cmd=0
 g.shield=get_shield_upg_lvl()
 if has_upgrade(0x0400) then
  pickup_weap(1,false)
 end
 set_mode(1)
 g_sav.levels_played+=1
end
function set_mode(new_mode)
 g_mode=new_mode
 g_clk_sec=0
 g_clk=0
 g_sstate.sel=1
 local mus=k_mus_for_mode[new_mode]
 if mus and mus~=g_mus then
  music(k_mus_for_mode[new_mode])
  g_mus=mus
 end
 if new_mode~=2 then
  g_scrt=1
 end
 save_data()
end
function ent_add(eid,x,y)
 local e=overlay(k_e_template,
   g_ent_defs[eid] or g_ent_defs[0])
 e.eid,e.x,e.y=eid,x,y
 add(g.ents,e)
 return e
end
function ent_update(e)
 e.age+=1
 e.ttl=e.ttl and (e.ttl-1) or nil
 if e.face_plr then e.facing=e.x>g.x and -1 or 1 end
 if e.bounce_x then
  if e.x<8 then e.vx=abs(e.vx) end
  if e.x>100 then e.vx=-abs(e.vx) end
 end
 if e.zigzags then ent_beh_zigzag(e) end
 if e.enemy and e.x>110 then
  e.x=e.x-(e.x>120 and 2 or 1)
 elseif e.dmg_cd and e.dmg_cd>0 then
  e.x+=1
 else
  e.x=e.x+(
    (e.vx_div<=1 or g_clk%e.vx_div==0) and e.vx or 0)
  e.y=e.y+(
    (e.vy_div<=1 or g_clk%e.vy_div==0) and e.vy or 0)
 end
 e.dmg_cd=max(0,e.dmg_cd-1)
 if e.fires then ent_beh_fire(e) end
 e.dead=e.dead or e.x<-8 or e.y<-8 or e.x>140 or
   e.y>140 or (e.ttl and e.ttl<1)
end
function ent_beh_fire(e)
 e.fire_cd=e.fire_cd or irnd_incl(0,e.fire_int_max)
 e.fire_cd=max(0,e.fire_cd-1)
 if e.fire_cd>0 then return end
 local num_en_projs=g.num_en_projs
 if num_en_projs>=8 then return end
 e.fire_cd=irnd_incl(e.fire_int_min,e.fire_int_max)
 for proj in all(e.fire_projs) do
  local off_x=proj.off_x or (e.facing>0 and
    proj.off_x_right or proj.off_x_left)
  assert(off_x)
  local off_y=proj.off_y
  local shot=ent_add(e.fire_eid,e.x+off_x,e.y+off_y)
  shot.vx=proj.vx or shot.vx
  shot.vy=proj.vy or shot.vy
  if proj.vx_facing then
   shot.vx=e.facing*abs(shot.vx)
  end
  if e.laser_clr then
   shot.cmap={[12]=e.laser_clr}
  end
  num_en_projs+=1
  if num_en_projs>=8 then break end
 end
end
function ent_beh_zigzag(e)
 if not e.zigzag_initted then
  e.vy=(rnd()>0.5 and 1 or -1)*e.zigzag_v
  e.zigzag_initted=true
 end
 if e.y<0 then e.vy=abs(e.vy) end
 if e.y>88 then e.vy=-abs(e.vy) end
end
function interp(x1,y1,x2,y2,x)
 if x1>x2 then
  return interp(x2,y2,x1,y1,x)
 end
 if x<=x1 then return y1 end
 if x>=x2 then return y2 end
 local f=(x-x1)/(x2-x1)
 return y1+(y2-y1)*f
end
function init_lum()
 g_lum={}
 for l=1,3 do
  add(g_lum,load_lum(l))
 end
end
function load_lum(l)
 local t={}
 for b=1,255 do
  local l_unlit=lo_nibble(b)
  local r_unlit=hi_nibble(b)
  local r_lit=
    lum_look_up(l,r_unlit)
  local l_lit=
    lum_look_up(l,l_unlit)
  local v=make_byte(r_lit,l_lit)
  add(t,v)
 end
 return t
end
function lum_look_up(l,c)
 local addr=(c%8)*64
 if c>7 then addr+=2 end
 if l==1 then
  return lo_nibble(peek(addr))
 elseif l==2 then
  return hi_nibble(peek(addr))
 else
  return lo_nibble(peek(addr+1))
 end
end
function lo_nibble(b)
 return band(b,0x0f)
end
function hi_nibble(b)
 return lshr(band(b,0xf0),4)
end
function make_byte(hi_nib,lo_nib)
 return bor(lo_nib,shl(hi_nib,4))
end
function light_b(l,b)
 if b==0 or l<=0 then return 0 end
 if l>3 then return b end
 return g_lum[l][b] 
end
function overlay(a,b)
 local result=deep_copy(a)
 for k,v in pairs(b) do
  if result[k] and type(result[k])=="table" and
    type(v)=="table" then
   result[k]=overlay(result[k],v)
  else
   result[k]=deep_copy(v)
  end
 end
 return result
end
function rect_isct(r1,r2)
 return
  r1.x+r1.w>r2.x and r2.x+r2.w>r1.x and
  r1.y+r1.h>r2.y and r2.y+r2.h>r1.y
end
function rect_xlate(r,dx,dy)
 return {x=r.x+dx,y=r.y+dy,w=r.w,h=r.h}
end
function deep_copy(t)
 if type(t)~="table" then return t end
 local r={}
 for k,v in pairs(t) do
  r[k]=type(v)=="table" and deep_copy(v) or v
 end
 return r
end
function fast_del(t,i)
 if i<1 or i>#t then return end
 local last=#t
 t[i]=t[last]
 t[last]=nil
end
function print_c(str,x,y,clr)
 print(str,x-2*#str,y,clr)
end
function meta_value(sp,deflt)
 return (sp>=48 and sp<=48+15) and
  sp-48 or deflt
end
function has_upgrade(up)
 return band_nz(g_sav.upgrades,up)
end
function grant_upgrade(up)
 g_sav.upgrades=bor(g_sav.upgrades,up)
 save_data()
end
function load_data()
 local addr=0x5e00
 g_sav=deep_copy(g_sav_templ)
 local sig=peek16i(addr) addr+=2
 if sig~=0x1234 then return end
 g_sav.lvl=peek16i(addr) addr+=2
 g_sav.coins=peek16i(addr) addr+=2
 g_sav.upgrades=peek16i(addr) addr+=2
 g_sav.coins_collected=peek16i(addr) addr+=2
 g_sav.coins_spent=peek16i(addr) addr+=2
 g_sav.enemies_killed=peek16i(addr) addr+=2
 g_sav.levels_played=peek16i(addr) addr+=2
 g_sav.deaths=peek16i(addr) addr+=2
 g_sav.powerups_collected=peek16i(addr) addr+=2
 g_sav.gameplay_minutes=peek16i(addr) addr+=2
end
function save_data()
 local addr=0x5e00
 local d=g_sav
 poke16i(addr,0x1234) addr+=2
 poke16i(addr,d.lvl) addr+=2
 poke16i(addr,d.coins) addr+=2
 poke16i(addr,d.upgrades) addr+=2
 poke16i(addr,d.coins_collected) addr+=2
 poke16i(addr,d.coins_spent) addr+=2
 poke16i(addr,d.enemies_killed) addr+=2
 poke16i(addr,d.levels_played) addr+=2
 poke16i(addr,d.deaths) addr+=2
 poke16i(addr,d.powerups_collected) addr+=2
 poke16i(addr,d.gameplay_minutes) addr+=2
end
function peek16i(addr)
 local n=0
 n=bor(n,peek(addr))
 n=bor(n,shl(peek(addr+1),8))
 return n
end
function irnd_incl(a,b)
 return a+flr(rnd(b-a+1))
end
function poke16i(addr,v)
 poke(addr,band(v,0x00ff))
 poke(addr+1,lshr(band(v,0xff00),8))
end
function get_bg_off()
 return band(shr(g_aclk,1),0x7f)
end
function draw_scrt()
 if not g_scrt then return end
 local off=k_scrt_seq[g_scrt]
 local ptr=0x6000
 local tmp=ptr+64*127
 for y=0,126 do
  memcpy(tmp,ptr,64)
  if y%2==0 then
   memcpy(ptr+off,tmp,64-off)
   memset(ptr,0,off)
  else
   memcpy(ptr,tmp+off,64-off)
   memset(ptr+64-off,0,off)
  end
  ptr+=64
 end
 g_scrt+=1
 if g_scrt>#k_scrt_seq then g_scrt=nil end
end
function update_stats()
 if g_btn_up and g_btn_left then
  if g_btn_o and g_btnp_x then
   poke(0x5e00,0)
   load_data()
   set_mode(0)
  end
 elseif g_btnp_x or g_btnp_o then
  set_mode(3)
 end
end
function draw_stats()
 cls(0)
 print_stats(30)
end
function print_stats(y)
 local m=band(g_sav.gameplay_minutes,0x7fff)
 local h=flr(m/60) m%=60
 print("your stats",8,y,11)
 print("gameplay time:\nenemies killed:\nlevels played:\ndeaths:\npowerups collected:\nchips collected: \nchips spent:",8,y+8,7)
 print(
   h .. "h " .. m .. "min" ..
   "\n" .. g_sav.enemies_killed .. 
   "\n" .. g_sav.levels_played .. 
   "\n" .. g_sav.deaths ..
   "\n" .. g_sav.powerups_collected ..
   "\n" .. g_sav.coins_collected .. 
   "\n" .. g_sav.coins_spent,
   90,y+8,6)
end 
function band_nz(num,mask)
 return band(num,mask)~=0
end
function update_win()
 if g_clk<128 then return end
 local s=g_sstate.sel
 g_sstate.sel=g_btnp_o and 1-s or s
end
function draw_win()
 cls(0)
 local base_y=max(0,128-g_clk)
 draw_logo(base_y)
 print_c("the end",64,base_y+28,7)
 if g_sstate.sel==1 then
  print("what the...? oh, you beat the\ngame? how? this wasn't supposed\nto happen. how did you get past\nthe... or the... ah, nevermind.\nthis is awkward, i didn't even\nprepare anything... well...\nuhhh, what i mean is:\n",2,base_y+44,6)
  print_c("congratulations!",64,base_y+90,11)
  print_c("press [z] for final stats",64,base_y+110,6)
 else
  print_stats(base_y+40)
  print("that's pretty impressive, you\nshould post a screenshot",2,100,5)
 end
end
function apply_acc(v,a)
 return a~=0 and mid(v+a,-2,2) or sgn(v)*flr(abs(v)/2)
end
g_update_fun={
 [0]=update_title,
 [1]=update_play,
 [2]=update_dying,
 [3]=update_hangar,
 [4]=update_shop,
 [5]=update_map,
 [6]=update_stats,
 [7]=update_win,
}
g_draw_fun={
 [0]=draw_title,
 [1]=draw_play,
 [2]=draw_dying,
 [3]=draw_hangar,
 [4]=draw_shop,
 [5]=draw_map,
 [6]=draw_stats,
 [7]=draw_win,
}
__gfx__
000012880000000000000000ccccc000550155555555555500115500000ee222000e000000000000000aa999000a000000000000000990000044440000555500
0001124933bbb33900000000566700001555005111111111111111110000766500000000000000000000766500000000000aa000009aa9000449944005544550
0112149a38b3663a0000000005667000001155110500055501000011000766500000000000000000000766500000000000a77a0009a77a90449aa94455400455
1133113b43c355390cccccc0007777701115000111155001100000010007777000000000000cc00007777770000000000a7777a09a7777a949aaaa9454000045
112411dc39333b3a000000000566700000115555001155555000000500076650000000000000000000076650000000000a7777a09a7777a949aaaa9454000045
1155111d33bbbb390000000056670000150500011555005110000001000076650000000000000000000076650000000000a77a0009a77a90449aa94455400455
11d6112e0000000000000000ccccc000551155115510551150000001000ee222000e000000000000000aa999000a0000000aa000009aa9000449944005544550
1d67124f000000000000000000000000005105000051150011101500000000000000000000000000000000000000000000000000000990000044440000555500
005555000777777007777770000000000088eeee00000000000000000000000000000000000bb330000000000000000000000000000000000000000000033000
05000050711111157333333500c000c00800e66500000000007000000000000000000000000b33330000000000000000000000000000000000033000003bb300
500000057111111573bbbb350c0c0c0c0007665000000000005700000000000000000000b300420000a00a00000a0000300000003000000000033000003bb300
5000000571cccc15733333350c00c00c07777770000770000005706500000000000a9000340440300000000000000a0010000030100760300000000000033000
500000057111111573bbbb350c0c0c0c000766500007600076005765000000000009a000004203310000000000a0000031300331313763310000000000000000
50000005711111157333333500c000c00800e665000000007a6a6a550a0a0a00000000000144313300a00a000000a00021313133213761330000000000000000
050000500555555005555550000000000088eeee0000000007666550000000000000000024222112000000000000000022322112223761120000000000000000
00555500000000000000000000000000000000000000000000777500000000000000000042223222000000000000000022123222221762220000000000000000
000555105501555555551055550000000000005500000000000000000777777000000000bbbbb30000880000bb066060bb006660bb0000000000000007777770
155511511555005115005551155000000000055100000000000000007111111500000000566733000800000000b6363600b6356000b000000000000072222225
001100110011510000151100001000000000010000bbbb000bbbbbb071bbbb1500bbbb00356673330000000000065b5600065b5600000b0000000000722e2e25
1155511511150000000051111110000000000111000000000333333071b11b1500b00b000377777300000000bbb63b36bbb63b36bbb00b000007700072222225
313113310010000000000100001000000000010000bbbb000bbbbbb071b11b1500b00b00356673330000000000065b5600065b5600000b000000000072e2e225
21313133151000000000015115100000000001510000000000000000711bb115000bb000566733000800000000b6363600b6356000b000000000000072222225
223221125510000000000155551000000000015500000000000000000555555000000000bbbbb30000880000bb066060bb006660bb0000000000000005555550
22123222005000000000050000500000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
18888811118811111888881118888811181118111888881118888811188888111888881118888811118881111888811111888811188881111188881111888811
18111811111811111111181111111811181118111811111118111111111118111811181118111811181118111811181118111111181118111811111118111111
18111811111811111888881118888811188888111888881118888811111118111888881118888811188888111888881118111111181118111888881118888811
18111811111811111811111111111811111118111111181118111811111118111811181111111811181118111811181118111111181118111811111118111111
18111811111811111811111111111811111118111111181118111811111118111811181111111811181118111811181118111111181118111811111118111111
18888811188888111888881118888811111118111888881118888811111118111888881118888811181118111888811111888811188881111188881118111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
000000000000000000000000cccccccc000100000000000000000000000000000000000044225254005525001121112151515151111111110000000000200000
000000ccccccccccccccc000cccccccc000100000000000000099000000660000000000040555254005545001212121251515151550055000000200000200000
00000c666666666666666c00cccccccc0001000000000000009aa900006556000000000045222525002520002121212151515151111111110201200020202020
0000c61111111111111116c0cccccccc1111111100000000777aa777777557770000000044425540004255002222222251515151005500552010202020022002
000c611111111111111116c0cccccccc0001000000000000009aa900006556000000000024220445005254002222222251515151111411112012020021201202
00c6111111111111111116c0cccccccc000100000000000000099000000660000000000022552555005550002222222251515151550455000222110212022212
0c61111111111111111116c0cccccccc000100000000000000000000000000000000000045552255002552002222222251515151111411111212122221121111
0c61111111111111111116c066666666000100000000000000000000000000000000000044550054005244002222222251515151005500551212212212121212
0c61111111111111111116c011110000000000000000000000000000000000000000000005055450004425002292229211111111111111115544455555445455
0c61111111111111111116c011100000000000000000000000000000000cc0000000000055555545005525002929292955005500005055005444444454400545
0c6111111111111111116c001100000000000000000000000000000000c77c00000cc00044200250000555009292929211111111005115004554455445000054
0c611111111111111116c000100000000000000000000055500000000c7777c000c77c0042000052004525009999999900550055005505005444444444000044
0c61111111111111116c000000000000000aaa0000000500050000000c77777c00c777c055000025005554009999999911111111005115004544555545000054
00c666666666666666c00000000000000000000000005000005000000c7777c000c77c0052000045000525009999999955005500005055004444444555000045
000ccccccccccccccc0000000000000000000000000500000005000000c77c00000cc00055555444055455509a9a9a9a11111111005115005444555544455445
00000000000000000000000000000000000000000005000000050000000cc000000000000455555055522555aaa9aaa900550055555555555544454555554445
111111110c611111111116c000000000000000000005000000050000000000000000000000045000555254442222222211111111000000000000050555544445
111111110c611111111116c000000000000000000005000000050000000000000000000000002000052454402222222255005500000155100000505044442455
111111110c611111111116c000000000000000000000500000500000000000000000000000045000005520002222222211000011000151110004400052412445
111111110c611111111116c000000000000000000000055555000000000ccc000000000000044000002544002222222200000055000150010045440025152524
111111110c611111111116c000000001000a9900000000000000000000c777c000c7c00000045000004242002222222211000011000150000454454025125254
111111110c611111111116c000000011000000000000000000000000000ccc000000000000044000004440002222222255000000001111004550044442221152
111111110c611111111116c000000111000000000000000000000000000000000000000000042000004544002222222211111111055555500450054012121222
111111110c611111111116c000001111000000000000000000000000000000000000000000042000005552002222222200550055111111114455444412122122
00000000999999990000000000000000000000000000000000000000000700000000000000000000000020000000000000000000000000005555555500000000
00000000944999990000000000000000000000000000000000000000000700000005000003300330000000000009000000200000000020004444444400000000
000e0e00944999990000000000000000000000000000000000000000000700000000000030033003000900000009000000090000020140005555555504444440
00000000944999990000000000000000000000007777777750505050000700000005000003302330009a0000000a9000000a0000204444405454545440505054
00e0e0009449999900000000000000000009a9000000000000000000000700000000000030033003000000000000000000000000201212005555555550505050
00000000944444490000000000000000000000000000000000000000000700000005000003342330000000000000000000000000022444024444444550505050
00000000944444490000000000000000000000000000000000000000000700000000000030033003000000000000000000000000121242225444555544444444
00000000999999990000000000000000000000000000000000000000000700000005000000042000000000000000000000000000121241225544454555555555
0000000000000000000000000000000000000000000000000000000000000010ffffffffffffffff454545450000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000010001000ffffffff000ffff0454242450000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000500000100010000000000000f00424005450000000000000000000000000000000000000000
00000000000000070000070000000000000000000000000000000000101010100000000000000000454005455554000000000000000000000000000000000000
00000000000000006000006000066000000000000000000000000000010101010000000000000000450000550404000000000000000000000000000000000000
9a99905555005500500000500050050999a900000000000000000000101010100000000000000000450000550404000000000000000000000000000000000000
00000004004000004000004000044000000000000000000000000000110111010000000000000000420000550404000000000000000000000000000000000000
09a990033330330030330033003003099a9000000000000000000000111111110000000000000000450000454444000000000000000000000000000000000000
0000000200000200202020200020020000000000000000000000000011111111ffffffffffffffff000400000000000000000000000000000000000000000000
000a9011000011101011101110011009a000000000000000000000001111111100000000fffffff0000200000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000001111111100000000000ff000000040000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111111110000000000000000303020320000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000050000111111110000000000000000030343220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111111110000000000000000233322220000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111111110000000000000000323432320000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111111110000000000000000323232320000000000000000000000000000000000000000
00000000000000002222222222222222000000022222222220000000000000000330003345454545000000000004000000000000000000000000000000000000
00000000000000005550555550505050000000025252525250000000000000000003330045424245000000000002000000000000000000000000000000000000
00000000000000002202022250505050000000252522252525000000000000003330333342454545000000000000400000000000000000000000000000000000
00000000000000005005005550505050000000252520252525000000000000000003230045455545300000000000200000000000000000000000000000000000
00000000000000002002002222222222000002525200025252500000000000000030403045454555030303000000400000000000000000000000000000000000
00000000000000005005005500000000000002525200025252500000000000000300200345554555233232200000200000000000000000000000000000000000
00000000000000002002002200000000000025252525252525250000000000000004000042524555323232320004000000000000000000000000000000000000
00000000000000005555555500000000000222222222222222222000000000000002000045425545323232320002000000000000000000000000000000000000
00000000222222222222222200022222222220002000000022222222222222224545454200000002254545252000000000000000000000000000000000000000
00000000525555555255555500205050505052002200000055555555525005554044404500000005254525255000000000000000000000000000000000000000
00000000222222222222222202505050505050205220000022505222220000224440444500000045254525255400000000000000000000000000000000000000
00000000555255555552555520505050505050525252000055000555550000554400044500000045452525455400000000000000000000000000000000000000
00000000222422222222222250522222222220502525200050000052220000224440442500000525452525255250000000000000000000000000000000000000
00000000556462555555525550200000000002502525520050000055555555554054402500000525252545255250000000000000000000000000000000000000
00000000222422222222222252000000000000205252522050000052220000224454442500004525252545255254000000000000000000000000000000000000
00000000555555555555555520000000000000025252525250000055555555554242554500005545254545255455000000000000000000000000000000000000
00000000000000000000000000000000787878787878787878787878787878780000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000004444444444444444444444444444444400000000000000000000000000000000
00000000000000000000000000000000797979797979797979797979797979790000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000097959597970000000414143434343434343434343414142400000000000000000000000000000000
00000000000000000000000000000000797979797979797979797979797979790000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005050505050000096a6a696960000001635000000000000000000000000002600000000000000000000000000000000
004a5a5a6a0000000000004a5a5a6a00797979797979797979797979797979790000000000e60000000000000000000000000000000000000000000000000000
000000c1c1c100000000000000000000001222122202556764576457646500001600000000000000000000000000002600505050000000000000000000000000
00007b7b00004a5a5a5a6a002b2b0000797979797979797979797979797979790000000000e50000000000000000e60000000000d6000000d600000000d60000
00000095959500000000c1c1c1c10000006457645764660000000000008700001600000000000000000000000000362600406040000000000000000050505050
00002b2b0000002a2a2a00007b7b0000797979797979797979797979797979790000000000f50000e6e6e6e60000e50000000000c6000000c6000000d5c5d500
000000a6a6a600000000959595950000556767676767676767676767676600001606060606060606060606060606062600406040005050505050000060606060
4a5a5a5a5a6a002a2a2a3b4b2b2b000000000000000000000000000000000000f7f7f7f7f7e50000f5f5f5f50000f5f7d6000000c4000000c4000000d5c6d500
a60000a4a4a4000000009494949400008700e6e60000000000008a9babbb00001606060606060606060606060606062600404040004060606040000040404040
002a2a2a2a00002a2a2a00007b7b000000000000000000000000009bababbb000000000000f5f7f7e7e7e7e70000e500c60000d5c6c6c6c6c6d50000d5c5d500
a40000a5a5a50000000094949494000087d7e7e7f7d700000000a9aaa8aa8a001606060606060606060606060606062600505050c10202020202c19150505050
002a2a2a2a3b4b2a2a2a00002b2b00000000000000000000000000009a9ab8000000e6e600e50000f5f5f5f50000f500c50000d5c5c5c5c5c5d50000d5c6d500
a4000095959500000000959595950097566457645764676765008998889988001606060606060606060606060606062600406040505050505050505040606040
002a2a2a2a00002b2a2b004a5a5a6a00000000009babababbb8a00008b8bb8000000f5f500f5f7f7e7e7e7e7f7f7e500c50000d5c4c4c4c4c4d50000d5c5d500
a4000094949400979700a60000a60096000000000000000056676457645764650515151515151515151515151515152500404040122212221222122240606040
002a2a2a2a00002b2b2b00002a2a0000008a008a008b8b8bb8ba008a9a9ab88a0000e7e7f7e50000f5f5f5f50000f500c4c4c4d5c6c6c6c6c6d5c4c4d5c6d5c4
a4009794959400969600a40097a49796556767676767676767676767676767664444444444444444444444444444444400406040324232423242324250606040
4b1b6b6b1bc1c11b6b1bc1c11b1b3b3aaaa9aaa9aa9aa89aaaa9aaa9a8a8aaa9e4d7f6f6e4f6d7e4f6f6f6f6d7e4f6f4c5d4c5d5c5d4c5d4c5d5c5d4d5c5d5c5
a5c196949494c19696c1a50096a596968700002a2a0000000000d6d6d600000044444444444444444444444444444444d1020291d1020202020291d102020202
00000000000000000000000000000000998898899888889888899998898899880000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000873b4b2b6b3b4b0000d5c6c6c6d500004444444444444444444444444444444400000000000000000000000000000000
00000000000000000000000000000000006900006900000068000000680000000000000000000000000000000000000000000000000000000000000000000000
b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4566764576457646767645764576400004444444444444444444444444444444400000000000000000000000000000000
00000000000000000000000000000000680000696800680000680000690000000000000000000000000000000000000000000000000000000000000000000000
b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6000000000000000000000000000000004444444444444444444444444444444400000000000000000000000000000000
00000000000000000000000000000000680068000069680068686968000068000000000000000000000000000000000000000000000000000000000000000000
b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5000000000000000000000000000000004444444444444444444444444444444400000000000000000000000000000000
__map__
71000000000000070000000000000000000000000000000071000000000000070000000000000000000000000000007100000000000000000000000a00000000000000000000000000710000070000000000000700000a00000000000a0000000000000a71070000000a00000a00000000000000070000000000000000000000
30000000000000000000070000000000070000000000000030000000000000000a000700000000000a000000000000300a000a00000000000000000000000007000000000a00000a00300007000000000a00000000000000000000000000000000000000300700000000000000000000000000070000000a0000000000000000
31000007000a0000000007000a00000700000a00000000003207000a000a0000000007000000000700000a00000000330000000a0000001500000a000000000000150000000a000000340700000000000000000a000a00150014000a0007000014000a00350700140000000a00150000000a07000000000000000a0000070000
00000a00000000000a00000000000700000000000000000000000a000000000a0000000015000a00000000000000000a000000000a0000000000000000000700000000000a00000000070000000014000a000000000000000000000000000000000000000a0700000000000000000000000700000000000a0000001500070014
07000007000a000000000a000a0000070000000a0000000007000007000a000000000a00000000070000000a000000000a000000000a0000070000000007000000000a000007000a00000700000000000000160000000a00000000000a0000000000000a00070000070000000a00000007000000000000000000070000070000
160000000000001600001600000000000700000000000000001600000000001600001600000000000a00000000000000000000000000000000000016000000160000000000000000000000000000000000000000000000000000000000000016160000000007000000000000000000070000000000001600160000000000000a
710000000000000000000a000000000000070000000000007100000000000000000000000000000000000000000000710000000a000000000000000000000000000000000000070000710000000000000000000000000000070000000000000000000000710000000a0000000007000000000000000000000000000000000000
300000000a000000000700001500000a0007000000000000300014000a000000150000000000001400000a00000000300000000000000000000000140000000a000000000a00070000301500000a00140000140000000000000015000a000000000000003114000a000014000007000000001400001400001400000000000000
36000a00000000000700000000000a0000070a00140014003700000000001400000000140000000000000a002b000038000a0000000a00001400000000000a0015002b00000007002b39000000000000000000000000001400000000000000000000000030000a0000000007000700001500000000000a00001400002b000000
1400000000000a00000700000000000a0007000000000000140000000a000a00000015000700000014000a000000000a0000000000000000000a00000014000a000000000a00070000150a000a0000000700000000140000000000000a002b00000000001400000a000000000000000000001500000000000000140000000000
000000000a00000000000a0000000a00000700000a000000000000000a0000000007000000000000000000000000000000000000000000000000000000000000000000000000070000000000000a00140000000000000000000015000000000000000000000000000a0014000000000000000000140000000000000007000000
00000000000000000000000016000000000700000000160000000000000000000000000000160000000016000000000016001600160016000000000016000000000000000000000000000000000000000000001600000000160000000a0000000000000000140000160000000000160000000000000000000000000000000000
71000000000a0000000000000000000007000000000000007100000007000000000000000000000a0000000000000071000000000a000a00000000000000000000000000140000140071000000000000000000000000000000000000000000000000000071140014000000000000000000000000000000150000000000000000
310000000a000000000a0000140000000700001500000000310000070007000000000a000a00000015000014000000310000000a0000000700000000000000000000000a00000000003100140a000000000015140000000a00000014000014001400000031000000000000001400000000000a00150000000014000000070000
3100000a00000000000014000000000a07000a000014002b32000700000007000000000000000000000000000014003300000a00000000000a00000015000a00140000000014000a00340000000007000a000000000a1400002b00000a000000000000003500070000000000000000000a14000a00000a00000a002b00000a00
2b000a0000150014000000000000000007000000000000000007000000000007000a000a00000a000000000000000000000a0000000000000007000000000000000a00000000000000140000002b00000000000a00000000000a000000000000001400000000000000000a000a000a0000000a000000001500000000000a0000
0007000000000000000000000014000007001500000700070000070000000700000000000000001500000000140000000a000000000000000000140000000015000000000000001400000007140000070014000000000a0a0000000a001400000000001400000007000000000000000000000000000000000014000000000000
000000000000000000160000000000000700000000000000000000070007000000000a0000000016001600000016000a0000000000000000000000070000000000000016000000000000000000000000000000000000001600000000000000000000160000071400000000161616001600000000000000000000000000000000
710a000000000000000700070000000000000000000000007100000000000000000000000007000000000000000000710a000a00000000000000000000000000000000000000000000000000070007000000000000000000003f00000000000000000000000000000000000000000000000000000000000a000000001c190000
31000a00000a0000000007000000000000001400002b000031001400000700000a000000001400002b0a001500000031000a0000000000000a000000000a0014000a0000140000000000000000071507002b000000002b000000000000000000000000000000000000000000000000000000000003090909000a000005050000
360a00000000002b00070007002b00000014000000000000370000000000000000000a00000000000000002b000700380a000a1500150014001500002b00000014000000000000000000000007000700000000000000000000000000000000000000000000000000000000000000000000001c1c1c191c1c1400000006060000
00000a002b00001500000700000000000000140000002b000a00000a00000a0015002b0014001400000a000700000000000a0000150000000a0014000014000000140000000000140000000000070007000000001400000014000000000000000000000000000000000000000000000000000505050505050000000004040000
000a0000000a0000000700070000002b000000140000000000000700000000000000000000000000002b0000000000000a000a07001500000a000000000000000000140000000000000000000700070000000000000000000000000000000000000000000000000000000000000000001c192122212221221c191c1c21221c1c
00000a000000000000160716000000000000000000000000000000161416000000000014000016000000000000000000000a0000160000001600000000000000161600000000000000002b0000070007000000000000000000000000000000000000000000000000006d6d6d000309000a001400006e6e000309000a00140000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005d6c6c6c5d0000006d6d0000005f5f0000006e6e00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005d5c5c5c5d00005d6c6c5d007d7e7e7f7d4e5e5e7f7f7d4e
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4a5a5a60309000a140079000003090014000a000079
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2a20000b7b7000000690059595979005959597969
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009ab3b4b2b6b3b4b2b29a9a9a694e494949694e4949496969
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a8b9babb03a809000a0014000000000309000a0007000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009aaa8aaaa89aaaaaaaa8a8aa1c191c1c1c191c1c1c1c1c1c
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000988988998898898899888888212221222122212221222122
__sfx__
01140000180530c0530c0530c053180530c0530c0530c053180530c0530c0530c053180530c0530c0530c053180530c0530c0530c053180530c0530c0530c053180530c0530c0530c053180530c0530c0530c053
0114000011055150501505513055150551105011052110521005511050130551305513055110501105211052100551005010055110551305515050130521505217052100501105213050100520e0500c0520c050
0114000011155151501515513155151551115011152111521015511150131551315513155111501115211152111551515015155131551515515150181521a1521c1501a150181501715017150110501305015050
011400001c0521005210052100521d0521105211052110521f0521305213052130521c0521005210052100521f052130521305213052210521505215052150521a0520e0520e0520e0521c052100521005210052
011400000e1521315213152131521015215152151521515211152171521715217152131521815218152181521d0551c0551a0551805517055150551305511055210551f0551d0551c0551a055180551705515055
001000001705215052130521305213052100521005210052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001b04000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000000
010c00001564001030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000b66109652076420563300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011a0000156521365211642106420e6320c6220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002
000600000e650126500e650116500c650106500d45011450144500040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000a00001c65016650106500865003650016500165001650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000190701f060240602305027040270002700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c000010050160501d05022050250501e000250001e000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001c6501f0501b050100500a050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a0000240502a0502a0502a0302a030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c550000000c550000001355000000115500000010550000000e550105500e550000000c550000000e550000000e55000000155500000013550000001155000000105501155010550000000e55000000
011000001f615000000c6150c6150c615000000c6150c6151f615000000c6150c6150c615000000c6150c6151f615000000c6150c6150c615000000c6150c6151f615000000c6150c6150c615000000c6150c615
011000000052504525075250452500525045250752504525005250452507525045250052504525075250452502525055250952505525025250552509525055250252505525095250552502525055250952505525
011000000c550105501055010550135501855018550185501c5501f5501f5501f5501855013550105500c5500e550115500e5500e550135500e5500e5500e550115501555015550155500e55015550115500e550
001000000c55000000175500000015550000001355000000115500000010550000000e550000000c5500000015550000001355000000115500000010550000000e550000000c550000001355010550115500e550
0110000010152000000e1520000010152000000e1520000211152000000e1520000011152000000e152000000c1550e15510155000000e152000000c152000000e152000000c152000000e155101551115500000
01100000111500000010150000000e150000000c150000001315000000111500000010150000000e150000001315513155111551115510155101550e1550e155111551115510155101550e1550e1550c1550c155
011000001315000000101500e1500c1500000011150000001315000000101500e1500c1500000011150000001515000000151501315011150101500e15010150151500000015150131501115000000101500e150
011000000005500000040550000007055000000405500000000550000004055000000705500000040550000002055000000505500000090550000005055000000205500000050550000009055000000505500000
011e0000187550000018755000001f755000001d755000001c755000001a7521c7521a7520000518752000001f755000001f75500000237550000021755000001f755000001d7521c7521a752000000000000000
011e00002b755000002b7550000030755000002d755000002b755000002975528755267550000026755000002975500000287550000026755000042475500000237550000021755000001f755000001f75500000
011e00000c0551005513055100550c0551005513055100550c0551005513055100550c05510055130551005513055170551a0551705513055170551a0551705513055170551a0551705513055170551a05517055
011800000c055100550c0551005513052180521805218052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800000c0301003013030100300e0301103015030110300c0300e0200c0100c0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00014244
00 00014344
00 00024344
00 00034344
02 00044344
01 1f1e2044
02 1f222044
03 1f632044
00 1f244344
02 1f254344
04 05424344
01 27294344
02 28294344
04 2a2b4344

