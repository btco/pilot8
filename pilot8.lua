---------------------------------------------------
-- pilot 8
--   a simple spaceship game for pico8.
--
-- copyright (c) 2018 bruno oliveira
-- all rights reserved
---------------------------------------------------

#define k_start_lvl 1
#define k_start_coins 0
#define k_debug_allow_kill_all true

-- clip rect shape (width and height) when drawing
-- lit portion of level (this rect is centered on
-- the player).
local k_lit_clip_r={x=-25,y=-30,w=95,h=60}
-- by how much to translate the rect if player is
-- facing left instead of right
#define k_lit_clip_xleft -40

-- lighting falloff. the bigger this number, the
-- smaller the lit area will be around the player
#define k_light_falloff 0.005
-- eccentricity of the lit area (to give it a more
-- oval shape). this hack is too ugly to describe
-- in words, see postproc_light() for how these numbers
-- are haphazardly used
#define k_light_ecc 0.4 -- 1=circle, smaller is more oval
#define k_light_ecc_cutoff 30

-- how long entities remain in the "damaged" state
-- after taking damage
#define k_dmg_dur 3

-- x coordinate where we spawn entities
#define k_spawn_x 128  -- just off the screen

-- y coordinate of water surface
#define k_water_y 96

-- player bounds
#define k_plr_min_x 0
#define k_plr_max_x 120
#define k_plr_min_y 0
#define k_plr_max_y k_water_y-8

-- pre-generated pseudo random numbers for some
-- effects that need stability
local k_rnd=nil

-- interval between executing successive level seq
-- commands
#define k_cmd_int 30

-- how long the player remains in "hurt" mode
#define k_plr_hurt_dur 40

-- maximum shield player can have
#define k_shield_max 3

-- minimum interval between enemy loot drops
-- (without and with the "more powerups" upgrade)
local k_drop_int={300,200}

-- duration of the level title display in seconds
#define k_title_dur_sec 4

-- duration of the "end of level" state, in ticks.
#define k_end_lvl_dur 100

-- zigzag min/max y for enemy zigzagging behavior
#define k_zigzag_min_y 0
#define k_zigzag_max_y 88

-- maximum # of enemy projectiles on the screen
#define k_max_en_projs 8

-- maximum # of enemies on the screen
#define k_max_enemies 8

-- game modes
#define k_mode_title 0
#define k_mode_play 1
#define k_mode_dying 2
#define k_mode_hangar 3
#define k_mode_shop 4
#define k_mode_map 5
#define k_mode_stats 6
#define k_mode_win 7

-- sprites
#define k_sp_plr 3
#define k_sp_hlaser_l 2  -- long laser
#define k_sp_hlaser_s 9  -- short laser
#define k_sp_en_alpha 7
#define k_sp_kaboom 12
#define k_sp_en_boat 22
#define k_sp_fireball 24
#define k_sp_en_beta 10
#define k_sp_weap_laser 17
#define k_sp_weap_dbl 18
#define k_sp_dbl 38  -- double laser
#define k_sp_infty 19
#define k_sp_shield 39
#define k_sp_plr_w_shield 41
#define k_sp_en_gamma 20
#define k_sp_coin 1
#define k_sp_lvl_done 71
#define k_sp_en_spiky 21
#define k_sp_en_delta 43
#define k_sp_weap_mach 47
#define k_sp_lvl_start_mark 113  -- level start mark
#define k_sp_lvl_wave_mark 114  -- wave start mark

-- entity ids that don't correspond to sprites
-- these must be >1000 to avoid conflict with sprites
#define k_eid_plr_laser 1000  -- player laser
#define k_eid_en_laser 1001  -- enemy laser
#define k_eid_mach_laser 1002  -- mach weapon laser

-- meta sprite with value 0. meta sprites indicate
-- numeric data in map rom (like level commands).
-- these are not sprites for display.
#define k_sp_meta0 48

-- collision rectangles
local k_cr_full={x=0,y=0,w=8,h=8}
local k_cr_plr={x=2,y=2,w=6,h=6}
local k_cr_ship={x=2,y=2,w=6,h=6}
local k_cr_hbar={x=2,y=3,w=6,h=2}
local k_cr_hbar_s={x=3,y=3,w=2,h=1}
local k_cr_dbl={x=1,y=2,w=6,h=3}
local k_cr_ball={x=3,y=3,w=2,h=2}
local k_cr_ball4={x=2,y=2,w=4,h=4}
local k_cr_pwup={x=0,y=0,w=8,h=7}

-- sfx
#define k_sfx_fire 10
#define k_sfx_hurt 11
#define k_sfx_kill 12
#define k_sfx_die 13
#define k_sfx_dbl 15
#define k_sfx_pwup 16
#define k_sfx_shield 17
#define k_sfx_lose_shield 18
#define k_sfx_coin 19

-- music
#define k_mus_play_1 0
#define k_mus_title 5
#define k_mus_hangar 7
#define k_mus_die 10
#define k_mus_win 11
#define k_mus_end_level 13

-- buttons
#define k_btn_left 0
#define k_btn_right 1
#define k_btn_up 2
#define k_btn_down 3
#define k_btn_o 4
#define k_btn_x 5

-- music for each mode
-- if not specified, previous music will continue
local k_mus_for_mode={
 [k_mode_title]=k_mus_title,
 [k_mode_play]=k_mus_play_1,
 [k_mode_hangar]=k_mus_hangar,
 [k_mode_dying]=k_mus_die,
 [k_mode_win]=k_mus_win,
}

-- music that's currently playing
local g_mus=-1

-- probability schedule for enemy powerup drops
-- each entry has equal probability
local k_drop_sched={
 k_sp_weap_dbl,
 k_sp_shield,
 k_sp_weap_mach,
 0,
}

-- character colors for hint bar at bottom of screen
local k_hint_char_color={
 ["\139"]=12,["\145"]=12,["\148"]=12,["\131"]=12,
 ["\142"]=11,["\151"]=8
}

-- screen transition offsets
local k_scrt_seq={11,7,5,3,2,1}
-- screen transition counter, nil means not doing
-- transition
local g_scrt=nil

-- luminosity mapping table.
-- for each light lvl (1,2,3), g_lum[l][b] maps input
-- byte b (pair of pixels) to an output byte b (pair of
-- pixels) of lit pixels. light level 0 is not stored,
-- as it just maps to 0. light level 4 (max) is not
-- stored, as it maps to itself.
local g_lum=nil

-- animations
--    div: divisor for frame rate
--    fr: sequence of sprites
--    flip: sequence of flips (0=no flip, 1=flip x)
--    loop: true if loops, false or nil if not
--     (default false)
local k_anim_kaboom={div=2,fr={12,13,14,15,16,0}}
local k_anim_die={div=6,fr={12,13,14,15,16,0}}
local k_anim_beacon={div=10,fr={0,30,31},loop=true}
local k_anim_spiky={div=4,fr={26,27},loop=true}
local k_anim_fireball=
  {div=2,fr={24,24},flip={0,1},loop=true}
local k_anim_torch={div=8,fr={122,123,123},loop=true}
local k_anim_lantern={div=8,fr={84,100,116},loop=true}

-- height of level data in map rom, in cells
#define k_lvl_rom_h 6

-- interval before we start each wave of enemies
#define k_pre_wave_int 30

-- level templates (see below for the meaning of
-- each field)
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
 -- beach effect
 owfx={sx=0,sy=96,c=16,r=60,w=16,h=1},
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
}

-- game level definitions.
-- each level has:
--  lit: if true, uses lit mode, if false level
--    if fully lit
--  mc0,mr0: the col/row in map rom where level data
--    begins (this is filled in at runtime)
--  bgc,bgr: col/row of background in map rom
--    bgh: height of background in map tiles
--  thc,thr: col/row of the briefing screen thumbnail
--    for this level.
--  skfx: if not nil, specifies the sky to draw
--    {c,r,w,h,sx,sy} - where to copy from map rom
--    and where to draw on screen (sx,sy)
--  cclr: clear color
--  sun{x,y,rad,clr}: a circle to draw
--  em: (emissive overlays): emissive sprites/anims
--    each is {sp=...,x=..,y=..} or {anim=...,x=..,y=..}
--  title: level title
--  subt: level subtitle 
--  mapc,mapr: location on world map (in tiles)
--  rip_clrs: water ripple colors (as a byte
--    with two colors)
--  num_waves: (computed at runtime) # of waves.
-- 
-- how level data is represented:
--  the level starts at a level start mark
--  (k_sp_lvl_start_mark) in map rom. the start mark
--  has the level # it represents right below it
--  using meta sprites. that's the base-cell of the
--  level (mc0,mr0). Each column of k_lvl_rom_h tiles
--  starting at mc0,mr0 represents a 'level command',
--  which are executed in sequence. the top of each
--  column can have a command number, which by default
--  (if missing) is 0x00, meaning 'spawn these enemies'.
--  the level ends at the 'end level' command (0xff).
--
-- for ease of representation, each level can have a
-- template (the templ field) which has common fields
-- that are the same for many levels.
local g_lvls={
 -- level 1.
 {
  templ=k_lvl_templ_flood,
  mapc=1,mapr=4,
  text="know how to fly? no? well,   \nwhat better way to learn than\non a real mission with real  \nenemies? good luck!          ",
 },
 -- level 2.
 {
  templ=k_lvl_templ_flood,
  mapc=3,mapr=4,
  rain=1,
  text="congratulations on not dying.\nyou exceeded our expectations\nplease continue with your    \ncurrent strategy of not dying",
 },
 -- level 3
 {
  templ=k_lvl_templ_flood,
  mapc=5,mapr=4,
  text="bob left the gates open last \nnight and enemies returned to\nthe area. bob says sorry.",
 },
 -- level 4
 {
  templ=k_lvl_templ_oasis,
  mapc=8,mapr=3,
  text="the oasis area has strategic \nsignificance to us. we don't \nknow why yet. but go reclaim \nit anyway. use sunscreen.    ",
 },
 -- level 5
 {
  templ=k_lvl_templ_oasis,
  mapc=10,mapr=3,
  text="stellar performance! great...\noh? you are pilot 8, not 9.  \nsorry, nevermind. how awkward\noff you go. good luck.       ",
 },
 -- level 6
 {
  templ=k_lvl_templ_oasis,
  mapc=12,mapr=3,
  text="leadership accepted a statue \nof a horse as a gift from the\nenemy. in an unrelated event,\nsomehow the enemies got in.  ",
 },
 -- level 7
 {
  templ=k_lvl_templ_marshes,
  mapc=1,mapr=8,
  rain=1,
  text="it's a great night to stay by\nthe fireplace. so leadership \nwill stay by the fireplace   \nwhile you go do the work.    ",
 },
 -- level 8
 {
  templ=k_lvl_templ_marshes,
  mapc=3,mapr=8,
  text="bad news: the cheap defenses \nwe set up were not waterproof\nso the enemies are back. go  \nreclaim the area for us.     ",
 },
 -- level 9
 {
  templ=k_lvl_templ_marshes,
  mapc=5,mapr=8,
  text="the last pilot was supposed  \nto reclaim this area but got \nrecruited by a startup and   \nleft. it's up to you now.    ",
 },
 -- level 10
 {
  templ=k_lvl_templ_coast,
  mapc=10,mapr=9,
  text="the pilot we hired turned out\nto be a werewolf so he can't \nfly under a full moon. so    \nyou will have to go instead. ",
 },
 -- level 11
 {
  templ=k_lvl_templ_coast,
  mapc=12,mapr=9,
  text="bob sent an email to the     \nwrong mailing list and gave  \naway our coordinates, so the \nenemies found us. thanks bob.",
 },
 -- level 12
 {
  templ=k_lvl_templ_coast,
  mapc=14,mapr=9,
  text="the ideal vacation spot!     \nthe beach, the waves, ....   \nexcept there are a bunch of  \nenemies, so take care of that",
 },
 -- level 13
 {
  templ=k_lvl_templ_canals,
  text="we needed the area due to its\ncanals, but remembered we're \na spacefaring society with no\nuse for canals. get it anyway",
  mapc=2,mapr=13,
 },
 -- level 14
 {
  templ=k_lvl_templ_canals,
  mapc=4,mapr=13,
  rain=1,
  text="we mistook ourselves for the \nenemy so we left the area to \nclear it of enemies. then the\nreal enemies took it from us.",
 },
 -- level 15
 {
  templ=k_lvl_templ_canals,
  mapc=6,mapr=13,
  text="alex set the alarm to 7pm not\n7am so we overslept and lost \nthe area to enemies. they are\nvery punctual, unlike alex.  ",
 },
 -- level 16
 {
  templ=k_lvl_templ_castle,
  mapc=9,mapr=13,
  text="leadership wants a castle in \norder to fortify our defenses\nit worked in the middle ages \nso it seems like a good idea.",
 },
 -- level 17
 {
  templ=k_lvl_templ_castle,
  mapc=11,mapr=13,
  text="because they are all spelled \nsimilarly, leadership has    \ninvaded the wrong casle. now \ngo conquer the right one.    ",
 },
 -- level 18
 {
  templ=k_lvl_templ_castle,
  mapc=13,mapr=13,
  rain=1,
  text="okay, that wasn't the right  \ncastle either but this time  \nwe are really sure. last one!\ngood luck, pilot 8!          ",
 },
}

-- player weapons
#define k_weap_laser 0  -- default boring weapon
#define k_weap_dbl 1  -- double laser
#define k_weap_mach 2  -- mach weapon (fast shots)

-- info for each weapon
--   init_ammo: initial ammo, -1 means infinite
--     for each possible upgrade level: 0,1,2,3.
--   shot_eid: eid of the shot entity
--   off_x: {l,r} where l is the x offset of
--     the shot entity when shooting left,
--     and r is the offset of the shot entity when
--     shooting right.
--   off_y: y offset of shot entity.
--   sfx: sound to play when shooting
--   hud_icon: icon to use for the hud
--   clr: dominant color (for text effects)
--   fire_cds: interval between shots (ticks),
--     for each possible upgrade level: 0,1,2,3.
local k_weap_info={
 [k_weap_laser]={
  init_ammo={-1,-1,-1,-1},
  shot_eid=k_eid_plr_laser,
  off_x={-6,6},off_y=0,
  sfx=k_sfx_fire,
  fire_cds={15,10,7,5},
  hud_icon=k_sp_weap_laser,
  clr=12,
 },
 [k_weap_dbl]={
  init_ammo={5,7,10,15},
  shot_eid=k_sp_dbl,
  off_x={-6,6},off_y=0,
  sfx=k_sfx_dbl,
  fire_cds={20,15,10,10},
  hud_icon=k_sp_weap_dbl,
  clr=11,
 },
 [k_weap_mach]={
  init_ammo={50,60,70,80},
  shot_eid=k_eid_mach_laser,
  off_x={-6,6},off_y=0,
  sfx=k_sfx_dbl,
  fire_cds={5,4,3,3},
  hud_icon=k_sp_weap_mach,
  clr=14,
 },
}

-- current game mode.
local g_mode=k_mode_title

-- mode clock (this counts in "seconds",
-- approximately). resets when the mode changes
local g_clk_sec=0 -- clock in "seconds"
local g_clk=0 -- clock in ticks since mode change
local g_aclk=0 -- clock in ticks since start

-- persistent save data. this is saved and loaded
-- to persistent memory (player progression)
--
-- attention: all data in g_sav must be saved/loaded
-- by load_data() and save_data(). update those
-- functions when adding/removing fields from
-- g_sav.
local g_sav=nil
local g_sav_templ={  -- copied to g_sav
 lvl=k_start_lvl,  -- next level to play
 coins=k_start_coins,  -- coins
 -- purchased upgrades (bit flags)
 -- combination of bit flags k_upf_*
 upgrades=0,
 -- stats:
 coins_collected=0,
 coins_spent=0,
 enemies_killed=0,
 levels_played=0,
 deaths=0,
 powerups_collected=0,
 -- this accumulates fractions during gameplay,
 -- but only the integer part is serialized.
 gameplay_minutes=0,
}

-- transient game state. this gets wiped every time
-- we play a level.
local g=nil -- copied from k_g_template
local k_g_template={
 -- level number
 lvl_no=-1,  -- initialized later
 -- convenience pointer, equiv to g_lvls[g.lvl_no]
 lvl=nil,  -- initialized later
 -- countdown to execute next level command
 cmd_cd=0,
 -- if true, we are in an interval between successive
 -- enemy waves. when cmd_cd reaches 0, we will start
 -- the next wave.
 pre_wave=false,
 -- current wave#
 cur_wave_no=0,
 -- index of the next command to execute
 -- starts at 0 (0th column of level)
 next_cmd=0,
 -- copy of last g_clk value for play mode (needed
 -- because when we switch to "paused" states like
 -- k_mode_dying we lose g_clk and need it for
 -- drawing.
 play_clk=0,
 -- clip rectangle of the lit area. updated every
 -- frame.
 lit_clip={x=0,y=0,w=0,h=0},
 -- countdown for next enemy loot drop
 drop_cd=k_drop_int[1],
 -- player state:
 x=10,y=40,  -- position
 facing=1,  -- facing direction 1=right, -1=left
 -- to animate the light effect, this counter
 -- keeps track of "fractionary" facing direction
 -- where 1 means the player is fully facing right,
 -- -1 means fully facing left, and anything in
 -- between is an intermediate state
 facing_frac=1,
 -- translated collision rectangle, computed
 -- after moving the player each frame
 xcr=nil,
 -- countdown to being ready to fire next shot
 fire_cd=0,
 -- current weapon
 weap=k_weap_laser,
 weap_info=k_weap_info[k_weap_laser],
 ammo=-1,  -- -1 = infinite
 -- amount of shield
 shield=0,
 -- count down to end shield animation
 shield_anim_cd=0,
 -- if >0 player has just taken damage (lost
 -- shield), and this is the count down to end
 -- the effect
 hurt_cd=0,
 -- entities. see k_e_template below.
 ents={},
 -- number of active enemies, updated every frame
 num_enemies=0,
 -- number of active powerups, updated every frame
 num_pwups=0,
 -- number of active enemy projectiles, updated every
 -- frame
 num_en_projs=0,
 -- if this is not nil, we are in "level ended"
 -- mode and this is the countdown
 end_cd=nil,
}

-- color map for the damage state (map all to white)
local k_dmg_cmap={}
for i=1,7 do add(k_dmg_cmap,7) end

-- upgrade shop sub-modes
#define k_shop_mode_normal 0  -- displaying list
#define k_shop_mode_buy 1  -- offering to buy
#define k_shop_mode_sorry 2  -- saying "no funds, sorry"
#define k_shop_mode_bought 3  -- just bought it

-- state for the several screens
local g_sstate={
 -- currently selected menu item, for the modes that
 -- have this
 sel=1,
 -- map screen
 map={
  -- currently selected level
  sel_lvl=nil,
  -- showing confirmation prompt?
  prompt=false,
 },
 -- shop screen
 shop={
  mode=k_shop_mode_normal,
  scr_y=0,  -- scroll Y pos
  -- list of available upgrades -- computed when
  -- entering the shop, each is a reference to
  -- an entry of k_upgrade_entries
  avail=nil,
 }
}

-- height of each upgrade shop item on the screen
#define k_shop_item_h 24

-- coin drop probability
#define k_coin_prob 0.5

-- possible upgrade (bit flags)
#define k_upf_speed        0x0001
#define k_upf_rapid_fire_1 0x0002
#define k_upf_rapid_fire_2 0x0004
#define k_upf_rapid_fire_3 0x0008
#define k_upf_ammo_1       0x0010
#define k_upf_ammo_2       0x0020
#define k_upf_ammo_3       0x0040
#define k_upf_shield_1     0x0080
#define k_upf_shield_2     0x0100
#define k_upf_shield_3     0x0200
#define k_upf_start_dbl    0x0400
#define k_upf_pwup_int     0x0800

-- list of upgrades as they appear in the upgrade
-- shop screen
--   upf: the upgrade flag
--   title: the title of the upgrade
--   desc: description
--   price: price in coins
--   dep: if not nil, this upgrade will only be
--     offered when this other upgrade has already
--     been purchased.
local k_upgrade_entries={
 {
  upf=k_upf_speed,
  title="speed boost",
  desc="fly faster",
  price=20,
 },
 {
  upf=k_upf_rapid_fire_1,
  title="rapid fire i",
  desc="faster lasers",
  price=20,
 },
 {
  upf=k_upf_rapid_fire_2,
  title="rapid fire ii",
  desc="even faster lasers",
  price=40,
  dep=k_upf_rapid_fire_1,
 },
 {
  upf=k_upf_rapid_fire_3,
  title="rapid fire iii",
  desc="the fastest lasers",
  price=80,
  dep=k_upf_rapid_fire_2,
 },
 {
  upf=k_upf_ammo_1,
  title="ammo i",
  desc="increased ammo",
  price=30,
 },
 {
  upf=k_upf_ammo_2,
  title="ammo ii",
  desc="even more ammo",
  price=50,
  dep=k_upf_ammo_1,
 },
 {
  upf=k_upf_ammo_3,
  title="ammo iii",
  desc="lots of ammo",
  price=70,
  dep=k_upf_ammo_2,
 },
 {
  upf=k_upf_shield_1,
  title="shield i",
  desc="start with shield",
  price=50,
 },
 {
  upf=k_upf_shield_2,
  title="shield ii",
  desc="start with 2x shield",
  price=80,
  dep=k_upf_shield_1,
 },
 {
  upf=k_upf_shield_3,
  title="shield iii",
  desc="start with 3x shield",
  price=100,
  dep=k_upf_shield_2,
 },
 {
  upf=k_upf_start_dbl,
  title="green laser",
  desc="start with green laser",
  price=90,
 },
 {
  upf=k_upf_pwup_int,
  title="more powerups",
  desc="get powerups more often",
  price=90,
 },
}

-- template for entities. deep-copied to create
-- a new entity.
local k_e_template={
 -- entity id (normally k_sp_... for the main sprite)
 eid=0,
 sp=nil, -- sprite to draw. if nil, use eid
 x=0,y=0, -- position
 vx=0,vy=0, -- velocity
 age=0, -- age (in ticks)
 facing=-1, -- facing dir, -1 is left, 1 is right
 face_plr=false,  -- automatically turn to face player?
 bounce_x=false,  -- automatically flip velocity when
     -- edge of screen is reached?
 vx_div=1,vy_div=1, -- velocity divisor (only moves
     -- every this this many frames)
 cr=k_cr_full, -- collision rect (non translated)
 dead=false, -- if true, ent is pending deletion
 -- if not nil, this is an emissive sprite to draw
 -- after the lighting pass
 em_sp=nil,
 -- if not nil, this is how long this entity lives
 -- for, after that it's deleted
 ttl=nil,
 -- if not nil, this is the ttl value below which
 -- this entity will start to blink
 blink_ttl=nil,
 -- if true, this entity shoots projectiles.
 fires=false,
 -- what kind of projectile does it shoot?
 fire_eid=k_eid_en_laser,
 -- projectiles to shoot
 --   each has:
 --     off_x OR off_x_left/off_x_right:
 --        x offset of projectile (when facing left
 --        and right, respectively)
 --     off_y: y offset of projectile
 --     vx, vy: x velocity, y velocity
 --     vx_facing: if true, adjust sign of x velocity
 --        according to facing direction
 fire_projs={
  {off_x_left=-6,off_x_right=6,off_y=0,vx_facing=true}
 },
 -- minimum and maximum shooting interval
 fire_int_min=60,fire_int_max=100,
 -- countdown to next shot, if fires==true
 fire_cd=nil,
 -- if not nil, this is how much damage this entity
 -- causes to the player
 dmg_plr=nil,
 -- if not nil, this is how much damage this entity
 -- causes to enemies.
 dmg_en=nil,
 -- if >0 this entity was recently damaged
 dmg_cd=0,
 -- if not nil, this is the # of hitpoints that this
 -- entity has
 hp=nil,
 -- animation for regular drawing pass
 anim=nil,
 -- animation for emissive drawing pass
 em_anim=nil,
 -- is it an enemy?
 enemy=false,
 -- is it an enemy projectile?
 en_proj=false,
 -- color substitution map
 --   maps from_color -> to_color
 -- applies to normal and emmissive sprites
 cmap=nil,
 -- if true, this entity zigzags vertically
 zigzags=false,
 zigzag_v=1,
 -- spawn y. if defined, entity will be spawned
 -- at this y coordinate regardless of map data
 spawn_y=nil,
}

-- entity definitions. if an entity has a definition
-- in this table, the info there is overlaid on top
-- of the template when creating it. this can
-- override any defaults set in e_template
local g_ent_defs={
 -- [0] is used for all entities missing an entry
 [0]={},
 [1]={em_sp=17},
 -- player laser
 [k_eid_plr_laser]={
  sp=0,
  em_sp=k_sp_hlaser_l,
  vx=5,
  cr=k_cr_hbar,
  ttl=25,
  dmg_en=1,
 },
 -- enemy laser (horizontal)
 [k_eid_en_laser]={
  sp=0,
  em_anim={fr={k_sp_hlaser_s,46},div=4,loop=true},
  vx=-1,
  cr=k_cr_hbar_s,
  dmg_plr=1,
  ttl=100,
  en_proj=true,
 },
 -- enemy "alpha"
 [k_sp_en_alpha]={
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
 -- explosion sprite
 [k_sp_kaboom]={
  sp=0,
  em_anim=k_anim_kaboom,
  ttl=40,
  vx=-1,vx_div=2,
 },
 -- enemy boat
 [k_sp_en_boat]={
  em_sp=23,
  enemy=true,
  vx=-1,
  vx_div=3,
  bounce_x=true,
  cr=k_cr_half,
  fires=true,
  fire_eid=k_sp_fireball,
  fire_projs={
   {off_x_left=-1,off_x_right=2,off_y=-2,vx_facing=true},
  },
  fire_int_min=55,
  fire_int_max=75,
  dmg_plr=1,
  hp=3,
  face_plr=true,
  spawn_y=k_water_y-8,  -- on water surface
 },
 -- enemy fireball (flies diagonally)
 [k_sp_fireball]={
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
 -- enemy "beta"
 [k_sp_en_beta]={
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
 -- "double laser" powerup
 [k_sp_weap_dbl]={
  em_sp=37,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 -- "mach laser" powerup
 [k_sp_weap_mach]={
  em_sp=112,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 -- double laser (projectile)
 [k_sp_dbl]={
  sp=0,
  em_sp=k_sp_dbl,
  vx=3,
  cr=k_cr_dbl,
  ttl=25,
  dmg_en=3,
 },
 -- shield powerup
 [k_sp_shield]={
  em_sp=40,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 -- enemy "gamma"
 [k_sp_en_gamma]={
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
 -- coin
 [k_sp_coin]={
  em_sp=k_sp_coin,
  ttl=120,
  blink_ttl=60,
  pwup=true,
  cr=k_cr_pwup,
  vx=-1,vx_div=2,
 },
 -- enemy "spiky"
 [k_sp_en_spiky]={
  em_anim=k_anim_spiky,
  enemy=true,
  cr=k_cr_ball4,
  fires=true,
  fire_eid=k_sp_fireball,
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
 -- enemy "delta"
 [k_sp_en_delta]={
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
 -- mach weapon laser
 [k_eid_mach_laser]={
  sp=0,
  em_sp=k_sp_hlaser_s,
  vx=3,
  cr=k_cr_hbar,
  ttl=25,
  dmg_en=1,
  cmap={[12]=14},
 },
}

local g_loaded_data=false

-- key states (updated every frame). use this instead
-- of calling btn() and btnp() in order to save
-- tokens (nil or false mean not pressed, true
-- means pressed):
-- g_btn_x, g_btn_o, g_btn_up, g_btn_down, g_btn_left, g_btn_right
-- g_btnp_x, g_btn_o, g_btn_up, g_btn_down, g_btn_left, g_btn_right

function _init()
 cartdata("btco_pilot8_v1")
 init_rnd()
 init_lvls()
 load_data()
 init_lum()
 set_mode(k_mode_title)
end

function init_rnd()
 k_rnd={}
 for i=1,64 do
  add(k_rnd,irnd_incl(0,31))
 end
end

function init_lvls()
 -- expand level templates
 for i=1,#g_lvls do
  local lvl=g_lvls[i]
  g_lvls[i]=overlay(lvl.templ,lvl)
  g_lvls[i].templ=nil
 end

 -- look for level start marks in rows that are
 -- multiples of k_lvl_rom_h in the range [0,31]
 local last_lvl=nil
 for r=0,31,k_lvl_rom_h do
  for c=0,128 do
   local t=mget(c,r)
   if t==k_sp_lvl_start_mark then
    local lvl_no_tens=meta_value(mget(c,r+1))
    local lvl_no_ones=meta_value(mget(c,r+2))
    assert(lvl_no_tens and lvl_no_ones)
    local lvl_no=lvl_no_tens*10+lvl_no_ones
    last_lvl=g_lvls[lvl_no]
    last_lvl.mc0=c
    last_lvl.mr0=r
    last_lvl.num_waves=1
   elseif t==k_sp_meta0+15 and last_lvl then
    -- end level
    last_lvl=nil
   elseif t==k_sp_lvl_wave_mark and last_lvl then
    last_lvl.num_waves+=1
   end
  end
  last_lvl=nil
 end
 for lvl in all(g_lvls) do
  assert(lvl.mc0 and lvl.mr0)
 end
end

function _update()
 g_clk_sec+=0x0.08  -- 1/32th, approx 1/30th second
 g_clk=band(g_clk+1,0x7fff)
 g_aclk=band(g_aclk+1,0x7fff)
 g_btn_left,g_btn_right,g_btn_up,g_btn_down,g_btn_x,g_btn_o=
   btn(k_btn_left),btn(k_btn_right),btn(k_btn_up),
   btn(k_btn_down),btn(k_btn_x),btn(k_btn_o)
 g_btnp_left,g_btnp_right,g_btnp_up,g_btnp_down,g_btnp_x,g_btnp_o=
   btnp(k_btn_left),btnp(k_btn_right),btnp(k_btn_up),
   btnp(k_btn_down),btnp(k_btn_x),btnp(k_btn_o)
 -- every 225 ticks (~1/8 minute), increase the
 -- gameplay minutes counter by 1/8.
 if g_aclk%225==224 then g_sav.gameplay_minutes+=0.125 end

 local fun=g_update_fun[g_mode]
 assert(fun)
 fun()
end

function update_title()
 if g_btnp_o then
  -- if player already cleared the first level,
  -- go to the hangar. otherwise play the first
  -- level.
  --if g_sav.lvl==1 then
  -- start_lvl(1)
  --else
   set_mode(k_mode_hangar)
  --end
 end
end

function update_play()
 g.play_clk=g_clk
 -- update_plr must run first because it initializes
 -- the player's xcr (translated collision rect),
 -- which is used elsewhere.
 update_plr()

 update_lvl()
 update_ents()
 collide_ents()
end

function update_dying()
 if g_clk_sec>4 then
  set_mode(k_mode_hangar)
 end
end

function update_hangar()
 local h=g_sstate
 local dx,dy=get_dpadp()
 h.sel=mid(h.sel+dy,1,4)

 if g_btnp_o then
  if h.sel==1 then
   -- play next mission
   start_lvl(g_sav.lvl)
  elseif h.sel==2 then
   -- show world map
    start_map()
  elseif h.sel==3 then
   -- go to upgrade shop screen
   start_shop()
  elseif h.sel==4 then
   set_mode(k_mode_stats)
  end
 elseif g_btnp_x then
  set_mode(k_mode_title)
 end
end

function start_map()
 local state=g_sstate.map
 state.sel_lvl=g_sav.lvl
 state.prompt=false
 set_mode(k_mode_map)
end

function start_shop()
 local shop=g_sstate.shop
 shop.scr_y=0
 shop.mode=k_shop_mode_normal
 shop.avail={}
 -- add all available upgrades to the list
 -- except the ones the player already has
 for i=1,#k_upgrade_entries do
  local e=k_upgrade_entries[i]
  if not has_upgrade(e.upf) then
   -- hide upgrades that depend on upgrades that the
   -- player doesn't have
   if not e.dep or has_upgrade(e.dep) then
    add(shop.avail,e)
   end
  end
 end
 set_mode(k_mode_shop)
end

function update_shop()
 local shop=g_sstate.shop
 local sel_entry=#shop.avail>0 and
   shop.avail[g_sstate.sel] or nil
 if shop.mode==k_shop_mode_buy then
  if g_btnp_x then
   -- cancel purchase
   shop.mode=k_shop_mode_normal
   return
  end
  if g_btnp_o then
   -- confirm purchase
   grant_upgrade(sel_entry.upf)
   g_sav.coins=max(0,g_sav.coins-sel_entry.price)
   g_sav.coins_spent+=sel_entry.price
   save_data()
   shop.mode=k_shop_mode_bought
  end
  return
 elseif shop.mode==k_shop_mode_sorry then
  if g_btnp_x or g_btnp_o then
   shop.mode=k_shop_mode_normal
  end
  return
 elseif shop.mode==k_shop_mode_bought then
  if g_btnp_x or g_btnp_o then
   -- we must regenerate the list
   start_shop()
  end
  return
 end
 assert(shop.mode==k_shop_mode_normal)

 -- adjust y scroll pos
 local sel_spos=
   (g_sstate.sel-1)*k_shop_item_h+shop.scr_y
 if sel_spos<0 then
  shop.scr_y=min(0,shop.scr_y+4)
 elseif sel_spos>k_shop_item_h*3 then
  shop.scr_y-=4
 end

 if g_btnp_x then
  -- return to hangar
  set_mode(k_mode_hangar)
  return
 end
 -- if there are no entries to display, stop here
 if #shop.avail==0 then return end

 local dx,dy=get_dpadp()
 g_sstate.sel=mid(g_sstate.sel+dy,1,#shop.avail)
 if g_btnp_o then
  -- offer to buy or say sorry, depending on funds
  shop.mode=sel_entry.price>g_sav.coins and
    k_shop_mode_sorry or k_shop_mode_buy
 end
end

function update_map()
 local state=g_sstate.map

 -- if we are prompting the user about selecting
 -- a level, handle the O and X buttons to confirm
 -- or cancel:
 if state.prompt then
  if g_btnp_o then
   -- start this level
   start_lvl(state.sel_lvl)
   return
  end
  if g_btnp_x then
   -- cancel
   state.prompt=false
   return
  end
 end

 if g_btnp_o then
  -- if this is not the current level, show
  -- confirmation
  if state.sel_lvl~=g_sav.lvl then
   state.prompt=true
   return
  else
   -- just return to the hangar
   set_mode(k_mode_hangar)
  end
 elseif g_btnp_x then
  set_mode(k_mode_hangar)
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

-- gets the entity's translated collision rect
function ent_get_cr(e)
 return rect_xlate(e.cr,e.x,e.y)
end

-- checks if the given ent has damaged the player
function check_coll_dmg_plr(e)
 if g.hurt_cd>0 then return end -- invulnerable
 local ecr=ent_get_cr(e)
 local pcr=g.xcr
 if not rect_isct(ecr,pcr) then return end
 if g.shield>0 then
  g.shield-=1
  g.hurt_cd=k_plr_hurt_dur
  sfx(k_sfx_lose_shield)
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
 if e.eid==k_sp_weap_dbl then
  pickup_weap(k_weap_dbl)
 elseif e.eid==k_sp_shield then
  pickup_shield()
 elseif e.eid==k_sp_coin then
  pickup_coin()
 elseif e.eid==k_sp_weap_mach then
  pickup_weap(k_weap_mach)
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
 if play_sfx and weap_id~=k_weap_laser then
  sfx(k_sfx_pwup)
 end
end

function pickup_shield()
 g.shield=min(g.shield+1,k_shield_max)
 g.shield_anim_cd=30
 sfx(k_sfx_shield)
end

function pickup_coin()
 g_sav.coins+=1
 g_sav.coins_collected+=1
 save_data()
 sfx(k_sfx_coin)
end

function start_dying()
 sfx(k_sfx_die)
 set_mode(k_mode_dying)
 g_sav.deaths+=1
end

-- checks if the given ent has damaged an enemy
function check_coll_dmg_en(e)
 local ents=g.ents
 local ecr=ent_get_cr(e)
 for i=1,#ents do
  local victim=ents[i]
  -- only affect victims with hp
  if victim.hp then
   local vcr=ent_get_cr(victim)
   if rect_isct(vcr,ecr) then
    e.dead=true  -- projectile disappears
    hurt_enemy(victim,e.dmg_en)
   end
  end
 end
end

function hurt_enemy(target,dmg)
 target.hp-=dmg
 target.dmg_cd=k_dmg_dur
 target.dead=target.dead or target.hp<1
 sfx(target.dead and k_sfx_kill or k_sfx_hurt)
 if target.dead then
  -- explosion
  ent_add(k_sp_kaboom,target.x,target.y)
  -- maybe drop item
  maybe_drop_loot(target,target.x,target.y)
  g_sav.enemies_killed+=1
 end
end

function maybe_drop_loot(e,x,y)
 if g.drop_cd>0 then
  -- too early to drop powerups, but maybe drop coin
  maybe_drop_coin(e,x,y)
  return
 end
 -- if there are 2 powerups onscreen, don't drop
 if g.num_pwups>2 then return end
 -- if the player already has a non-default weapon,
 -- they're already doing well, so don't drop
 if g.weap~=k_weap_laser then return end
 -- drop a random item according to the schedule
 local i=irnd_incl(1,#k_drop_sched)
 if k_debug_force_drop then i=k_debug_force_drop end
 local eid=k_drop_sched[i]
 if not eid or eid==0 then
  -- out of luck. but maybe drop a coin instead.
  maybe_drop_coin(e,x,y)
  return
 end
 ent_add(eid,x,y)
 g.drop_cd=k_drop_int[
   has_upgrade(k_upf_pwup_int) and 2 or 1]
end

function maybe_drop_coin(e,x,y)
 if rnd()<k_coin_prob then
  ent_add(k_sp_coin,x,y)
 end
end

function update_lvl()
 g.drop_cd=max(g.drop_cd-1,0)
 g.cmd_cd=max(g.cmd_cd-1,0)
 g.end_cd=g.end_cd and max(g.end_cd-1,0) or nil

 if g.end_cd and g.end_cd<=0 then
  -- level cleared
  if g.lvl_no==#g_lvls then
   set_mode(k_mode_win)
   return
  else
   -- save progress and return to hangar
   g_sav.lvl=max(g_sav.lvl,g.lvl_no+1)
   save_data()
   set_mode(k_mode_hangar)
   return
  end
 end

 -- debug key combo: kill all enemies
 if k_debug_allow_kill_all and g_btn_up and
   g_btn_down and g_btnp_x then
  local ents=g.ents
  for e in all(ents) do
   e.dead=e.enemy or e.dead
  end
 end

 if g.cmd_cd<=0 and g_clk_sec>k_title_dur_sec then
  lvl_exec_next_cmd()
 end
end

function update_plr()
 local dx,dy

 -- if player just got hurt, they are pushed back
 g.hurt_cd=max(0,g.hurt_cd-1)
 if g.hurt_cd>flr(k_plr_hurt_dur/2) then
  dx,dy=-1,0
 else
  dx,dy=get_dpad()
  local spd=has_upgrade(k_upf_speed) and 2 or 1
  dx*=spd
  dy*=spd
 end

 g.x=mid(g.x+dx,k_plr_min_x,k_plr_max_x)
 g.y=mid(g.y+dy,k_plr_min_y,k_plr_max_y)

 -- hack: disable player facing direction (test)
 --g.facing=dx>0 and 1 or dx<0 and -1 or g.facing

 -- update translated collision rect
 g.xcr=rect_xlate(k_cr_plr,g.x,g.y)

 g.fire_cd=max(0,g.fire_cd-1)
 if g.fire_cd<1 and g_btn_o and g_clk_sec>1 then
  fire()
 end

 -- update clip rect
 g.lit_clip=rect_xlate(k_lit_clip_r,g.x,g.y)
 -- if player is facing left, correct the rect
 g.lit_clip.x+=interp(1,0,-1,k_lit_clip_xleft,g.facing_frac)
 -- update the "fractionary" facing (used for
 -- lighting animation).
 --g.facing_frac=
   --mid(-1,1,g.facing_frac+(g.facing*0.2))
end

function fire()
 local wi=g.weap_info
 -- fire the correct projectile type for the current
 -- weapon, placing it at the right offset
 local shot=ent_add(
   wi.shot_eid,
   g.x+wi.off_x[g.facing>0 and 2 or 1],
   g.y+wi.off_y)
 shot.vx=g.facing*abs(shot.vx)
 sfx(wi.sfx)
 local upg_lvl=get_rapid_fire_upg_lvl()
 -- get the fire countdown, depending on the level
 -- of the "rapid fire" upgrade
 g.fire_cd=wi.fire_cds[upg_lvl+1]
 -- deduct ammo, except if ammo is infinite
 if g.ammo>0 then
  -- ammo is finite, so deduct one
  g.ammo-=1
  if g.ammo<1 then
   -- ran out of ammo, so switch to basic weapon
   pickup_weap(k_weap_laser)
  end
 end
end

function get_rapid_fire_upg_lvl()
 return has_upgrade(k_upf_rapid_fire_3) and 3 or
   has_upgrade(k_upf_rapid_fire_2) and 2 or
   has_upgrade(k_upf_rapid_fire_1) and 1 or 0
end

function get_ammo_upg_lvl()
 return has_upgrade(k_upf_ammo_3) and 3 or
   has_upgrade(k_upf_ammo_2) and 2 or
   has_upgrade(k_upf_ammo_1) and 1 or 0
end

function get_shield_upg_lvl()
 return has_upgrade(k_upf_shield_3) and 3 or
   has_upgrade(k_upf_shield_2) and 2 or
   has_upgrade(k_upf_shield_1) and 1 or 0
end

-- executes the next level command in the level data
-- the next command is in the g.next_cmd-th column
-- of the map rom data for this level
function lvl_exec_next_cmd()
 -- if we're ending the level, there's nothing more
 -- to execute
 if g.end_cd then return end
 -- calculate coordinates for the column in the
 -- map rom data that represents the command
 local c0,r0=g.lvl.mc0+g.next_cmd,g.lvl.mr0

 -- get special marker from top row
 local marker=c0<128 and mget(c0,r0) or k_sp_lvl_start_mark
 -- the level start marker at the start of a level
 -- is equivalent to the "start wave" marker (it
 -- marks the first wave).
 if g.next_cmd==0 then marker=k_sp_lvl_wave_mark end

 if marker==k_sp_lvl_wave_mark then
  -- it's a "wave start" mark.
  if not g.pre_wave then
   -- we were not already in "pre-wave" state,
   -- so check if we should enter it.
   if g.num_enemies>0 then
    -- wait until there are no enemies left.
    g.cmd_cd=15  -- snooze
    return
   end
   -- enter the pre-wave state where we count down
   -- to start the next wave
   g.cur_wave_no+=1
   g.pre_wave=true
   g.cmd_cd=k_pre_wave_int
   return
  else
   -- we were already in the pre-wave state, so
   -- now it's time to start the wave for real.
   g.pre_wave=false
   -- (fall through)
  end
 elseif marker==k_sp_lvl_start_mark or
     marker==k_sp_meta0+15 then
  -- this is the end of the level
  if can_end_lvl() then
   -- start the end level countdown
   g.end_cd=k_end_lvl_dur
   music(k_mus_end_level)
  else
   -- snooze
   g.cmd_cd=30
  end
  return
 end
 -- if we get here, it's because we are ready to
 -- spawn the enemies on this column of the level
 if lvl_spawn(c0,r0) then
  -- successfully spawned, so advance to next command
  g.next_cmd+=1
 end
 g.cmd_cd=k_cmd_int
end

-- can we end the level now?
function can_end_lvl()
 -- don't trigger end of level until all enemies
 -- are defeated and all projectiles go away
 if g.num_enemies>0 then return false end
 if g.num_pwups>0 then return false end
 for e in all(g.ents) do
  if e.dmg_plr then return false end
 end
 -- no more enemies or enemy projectiles and such,
 -- so start the "end level" sequence
 return true
end

-- spawns the entities on the given column of the level
-- returns false if we couldn't (due to budget,
-- for example)
function lvl_spawn(c0,r0)
 -- figure out how many enemies we will spawn
 local count=0
 for r=r0,r0+k_lvl_rom_h-1 do
  local eid=mget(c0,r)
  -- ignore empty and meta tiles
  if eid>0 and not meta_value(eid) then
   count+=1
  end
 end
 -- if this would go over budget, wait
 if count+g.num_enemies>k_max_enemies then
  return false
 end
 -- instantiate each tile as an entity
 for r=r0,r0+k_lvl_rom_h-1 do
  local eid=mget(c0,r)
  if is_spawnable(eid) then
   -- it's an entity that we should spawn
   local x,y=k_spawn_x,(r-r0)*16
   local ent=ent_add(eid,x,y)
   -- if the entity prescribes a y position for it
   -- to spawn at, override the map-defined y
   ent.y=ent.spawn_y and ent.spawn_y or ent.y
  end
 end
 return true
end

function is_spawnable(eid)
 return eid>0 and not meta_value(eid) and
   eid~=k_sp_lvl_start_mark and
   eid~=k_sp_lvl_wave_mark
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
  -- restrict drawing to lit area
  clip(g.lit_clip.x,g.lit_clip.y,
    g.lit_clip.w,g.lit_clip.h)
 end
 -- render sky effect
 if skfx then
  for si=1,#skfx do
   local fx=skfx[si]
   map(fx.c,fx.r,fx.sx,fx.sy,fx.w,fx.h)
  end
 end
 -- render sun
 if lvl.sun then
  circfill(lvl.sun.x,lvl.sun.y,lvl.sun.r,lvl.sun.clr)
 end
 -- render background
 local bg_off=get_bg_off()
 local bgy=lvl.bgy or 0
 map(lvl.bgc,lvl.bgr,-bg_off,bgy,16,lvl.bgh)
 map(lvl.bgc,lvl.bgr,128-bg_off,bgy,16,lvl.bgh)

 -- ents
 local ents=g.ents
 for e in all(ents) do
  e.sp=e.sp or e.eid
  draw_ent(e,false)
 end
 
 if g_mode==k_mode_play then
  draw_plr()
 end

 -- draw rain, if needed
 if lvl.rain then draw_rain(lvl.rain) end

 -- apply lighting
 if lit then postproc_light() end

 -- now that we're done with lighting, remove the
 -- clip rect so we can paint the full screen.
 if lit then clip() end

 for e in all(ents) do draw_ent(e,true) end

 -- draw level-defined emissive animations
 draw_lvl_em_ovelays()
-- render water
 postproc_water()

 -- render post-water effects, if any
 if lvl.owfx then
  local fx=lvl.owfx
  map(fx.c,fx.r,fx.sx-bg_off,fx.sy,fx.w,fx.h)
  map(fx.c,fx.r,fx.sx-bg_off+128,fx.sy,fx.w,fx.h)
 end

 --print(stat(1)*100,0,0)

 draw_hud()

 if g_mode==k_mode_play and
   g_clk_sec<k_title_dur_sec then
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
 local left=k_title_dur_sec-g_clk_sec
 local c=(left<0.5 and 5) or (left<1 and 6) or 7
 print_c("sector " .. g.lvl_no,64,8,c)
 print_c(g.lvl.title,64,16,c)

 if g.lvl_no==1 then
  print_with_btn("\142 [z]: shoot",40,100,7)
 end
end

function draw_plr()
 if band(g.hurt_cd,4)~=0 then return end -- blink
 if g.shield>0 then
  g.shield_anim_cd=max(0,g.shield_anim_cd-1)
  if band_nz(g.shield_anim_cd,2) then pal(3,13) end
  if band_nz(g.shield_anim_cd,4) then pal(11,12) end
  spr(k_sp_plr_w_shield,g.x,g.y,1,1,g.facing<0)
  pal()
 else
  spr(k_sp_plr,g.x,g.y,1,1,g.facing<0)
 end
end

-- draws the given entity
-- is_emi: if false, it's the lit pass, if true
--  we're in the emissive pass
function draw_ent(e,is_emi)
 -- blink, if requested
 if e.ttl and e.blink_ttl and e.ttl<=e.blink_ttl then
  -- blink
  if band(e.ttl,4)==0 then return end
 end

 if is_emi then
  if e.dmg_cd>0 then
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

function draw_lvl_em_ovelays()
 local lvl=g.lvl
 if not lvl.em then return end
 local ems=lvl.em
 
 local bg_off=get_bg_off()
 for em in all(ems) do
  local x=em.x-bg_off
  if em.mc0 then
   -- draw a map slice
   -- width is hard-coded to 16 because it must
   -- wrap around according to level scroll, and it's
   -- hard to do with any other width
   map(em.mc0,em.mr0,x,em.y,16,em.mh)
   map(em.mc0,em.mr0,x+128,em.y,16,em.mh)
  else
   -- draw sprite or anim
   x=x<0 and 128+x or x
   if em.anim then
    draw_anim(em.anim,x,em.y,g_clk,em.cmap)
   else
    draw_spr(em.sp,x,em.y,em.cmap)
   end
  end
 end
end

-- draws an entity, possibilly with color substitution
-- cmap: (optional) color substitution map
-- flip_x: if true, flip x
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

-- draws an animation
function draw_anim(anim,x,y,clk,cmap,flip_x)
 local raw_fr=flr(clk/anim.div)
 local fr_no=anim.loop and (1+raw_fr%#anim.fr) or
   (min(1+raw_fr,#anim.fr))
 local fr=anim.fr[fr_no]
 local flip=anim.flip and anim.flip[fr_no] or
   (flip_x and 1 or 0)
 if fr>0 then draw_spr(fr,x,y,cmap,flip%2==1) end
end

-- draws the hud
function draw_hud()
 local wi=g.weap_info
 print("weap:",0,122,6)
 spr(wi.hud_icon,20,121)
 if g.ammo>=0 then
  -- finite (blink when < 3)
  if g.ammo>3 or band_nz(g_clk,4) then
   print(g.ammo,29,122,wi.clr)
  end
 else
  -- infinite
  spr(k_sp_infty,28,121)
 end

 -- draw shield
 for i=1,g.shield do
  spr(k_sp_shield,40+8*i,121)
 end

 -- draw coins
 draw_coins()

 if g.pre_wave then
  print_c("wave " .. g.cur_wave_no .. "/" .. g.lvl.num_waves,
    64,10,7)
 end
end

function draw_coins()
 local v=g_sav.coins
 local x,y=120,123
 spr(k_sp_coin,x,y)
 local printed=false
 while not printed or v>0 do
  x-=4
  print(v%10,x,y,5)
  v=flr(v/10)
  printed=true
 end
end

-- draws the title screen
function draw_title()
 --local seq={6,7,12,7,12,7,6,5}
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
end

function draw_logo(y)
 local seq={6,6,7,12,6,6,6,6}
 for i=1,7 do
  pal(i,seq[1+band(i+shr(g_aclk,2),7)])
 end
 sspr(
  0,64,   -- sx,sy on sprite sheet
  40,16,  -- sw,sh
  28,y,  -- dx,dy on screen
  80,32   -- dw,dh on screen
 )
 pal()
end

function draw_dying()
 local clr_seq={0,0,0,1,2,4,9,10}
 draw_play()
 draw_anim(k_anim_die,g.x,g.y,g_clk)
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
 -- draw the thumbnail
 map(next_lvl.thc,next_lvl.thr,16,16,12,3)
 
 local menu_y=83
 local menu_x=30
 local ystride=10
 local sel=g_sstate.sel
 draw_list(
   {"start mission","world map","upgrade ship","stats"},
   sel,menu_x,menu_y,ystride,6,10)
 spr(k_sp_plr,menu_x-10,menu_y+ystride*(sel-1)-1)
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
   spr(k_sp_lvl_done,x,y)
  end
  if i==state.sel_lvl and (state.prompt or
    band(g_clk,8)==0) then
   spr(k_sp_plr,x,y)
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

-- draws a hint bar showing what button does what
function draw_hint(msg)
 rectfill(0,121,128,128,0)
 print_with_btn(msg,2,123,5)
end

-- prints text highlighting the button symbols
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
 local normal=(shop.mode==k_shop_mode_normal)
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
  if sel then spr(k_sp_plr,x,y) end
  print(e.title,x+10,y,sel and (blink and 10 or 7) or clr)
  spr(k_sp_coin,100,y)
  print(e.price,112,y,sel and 7 or clr)
  print(e.desc,x+10,y+8,sel and 7 or clr)
  y+=k_shop_item_h
 end

 rectfill(0,0,128,12,6)
 print("available upgrades",8,4,0)

 local box_y,box_h=40,30
 local sel_entry=shop.avail[g_sstate.sel]
 if shop.mode==k_shop_mode_sorry then
  rectfill(16,box_y,112,box_y+box_h,2)
  print("not enough chips! (  )\n" ..
    "collect more chips and\n" ..
    "try again",20,box_y+4,7)
  spr(k_sp_coin,95,box_y+3)
  rect(16,box_y,112,box_y+box_h,7)
  draw_hint("\142:dismiss")
 elseif shop.mode==k_shop_mode_buy then
  rectfill(16,box_y,112,box_y+box_h,4)
  print(sel_entry.title,20,box_y+4,10)
  print("buy for    " .. sel_entry.price .. "?",
    20,box_y+12,7)
  spr(k_sp_coin,53,box_y+11)
  rect(16,box_y,112,box_y+box_h,7)
  draw_hint("\142:confirm  \151:cancel")
 elseif shop.mode==k_shop_mode_bought then
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
 -- clamp
 x0,xf=mid(x0,0,127),mid(xf+1,0,127)
 y0,yf=mid(y0,0,127),mid(yf+1,0,127)

 -- eccentricity animation
 --local ecc=interp(
 --  0,1.0,1,k_light_ecc,abs(g.facing_frac))
 local ecc=k_light_ecc

 for y=y0,yf do
  local dy=py-y
  local ptr=0x6000+y*64 -- 64 bytes per display row
  ptr+=flr(x0/2) -- start at the right column
  for x=x0,xf,2 do
   local dx=x-px
   local ahead
   if g.facing_frac>0 then ahead=dx>0 else ahead=dx<0 end
   -- ugly hack to make the light beam more oval
   -- shaped and focusing forward
   if abs(dy)<k_light_ecc_cutoff and ahead then
    dx*=ecc
   end
   local dist=dx*dx+dy*dy
   local light_lvl=flr(5-dist*k_light_falloff)
   local b=peek(ptr)
   b=light_b(light_lvl,b)
   poke(ptr,b)
   ptr+=1
  end
 end
end

function postproc_water(water_y)
 -- copy framebuffer rows from the top to the bottom
 -- in reverse order to create the reflection effect
 local water_y=water_y or k_water_y
 local addr_w=0x6000+64*water_y
 local addr_r=addr_w
 local rip_c=(g and g.lvl and g.lvl.rip_clrs) or 0x11
 memset(addr_w,rip_c,64)  -- water line
 for y=k_water_y+1,127 do
  -- at every step, advance write position by 1 row
  addr_w+=64
  -- every other step, move read position back 1 row
  -- this means we're copying each input (above water)
  -- row to two below-water rows
  addr_r-=(y%2)*64
  -- figure out a pseudo random number from our
  -- pregenerated table (for stability)
  local offset=1+(flr(g_clk/4)+y)%#k_rnd
  local prand=k_rnd[offset]
  -- prand is now a pseudo-random int from 1 to 32
  if band_nz(prand,30) then -- 1 in 8 rows
   -- copy row from above water
   memcpy(addr_w,addr_r+prand%2*64,64)
  else
   -- use the water ripple color
   memset(addr_w,rip_c,64)
  end
 end

end

-- starts playing the given level.
function start_lvl(lvl_no)
 assert(g_lvls[lvl_no])
 g=deep_copy(k_g_template)
 g.lvl_no=lvl_no
 g.lvl=g_lvls[lvl_no]
 g.next_cmd=0
 g.shield=get_shield_upg_lvl()
 if has_upgrade(k_upf_start_dbl) then
  pickup_weap(k_weap_dbl,false)
 end
 set_mode(k_mode_play)
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
 if new_mode~=k_mode_dying then
  -- start screen transition
  g_scrt=1
 end
 save_data()
end

-- adds an entity at the given position
function ent_add(eid,x,y)
 local e=overlay(k_e_template,
   g_ent_defs[eid] or g_ent_defs[0])
 e.eid,e.x,e.y=eid,x,y
 add(g.ents,e)
 return e
end

-- updates entity
function ent_update(e)
 -- increment entity's age
 e.age+=1
 -- apply ttl
 e.ttl=e.ttl and (e.ttl-1) or nil
 -- face player, if requested
 if e.face_plr then e.facing=e.x>g.x and -1 or 1 end
 -- bounce off edge, if requested
 if e.bounce_x then
  if e.x<8 then e.vx=abs(e.vx) end
  if e.x>100 then e.vx=-abs(e.vx) end
 end
 -- update zigzag behavior (influences velocity)
 if e.zigzags then ent_beh_zigzag(e) end
 -- give enemies a boost so they get to the visible
 -- part of the screen faster.
 if e.enemy and e.x>110 then
  e.x=e.x-(e.x>120 and 2 or 1)
 else
  -- apply velocity
  e.x=e.x+(
    (e.vx_div<=1 or g_clk%e.vx_div==0) and e.vx or 0)
  e.y=e.y+(
    (e.vy_div<=1 or g_clk%e.vy_div==0) and e.vy or 0)
 end
 -- update damage countdown
 e.dmg_cd=max(0,e.dmg_cd-1)
 -- apply other behaviors:
 if e.fires then ent_beh_fire(e) end
 -- delete entity if it's off screen or its time is up
 e.dead=e.dead or e.x<-8 or e.y<-8 or e.x>140 or
   e.y>140 or (e.ttl and e.ttl<1)
end

-- implements the firing behavior of an entity
function ent_beh_fire(e)
 -- if fire_cd not yet initialized, init with random
 e.fire_cd=e.fire_cd or irnd_incl(0,e.fire_int_max)
 e.fire_cd=max(0,e.fire_cd-1)
 if e.fire_cd>0 then return end
 -- if there are too many enemy projectiles on the
 -- screen, hold off
 local num_en_projs=g.num_en_projs
 if num_en_projs>=k_max_en_projs then return end
 -- fire!
 e.fire_cd=irnd_incl(e.fire_int_min,e.fire_int_max)
 -- fire each projectile according to the recipe
 for proj in all(e.fire_projs) do
  local off_x=proj.off_x or (e.facing>0 and
    proj.off_x_right or proj.off_x_left)
  assert(off_x)
  local off_y=proj.off_y
  local shot=ent_add(e.fire_eid,e.x+off_x,e.y+off_y)
  shot.vx=proj.vx or shot.vx
  shot.vy=proj.vy or shot.vy
  -- adjust x velocity accordging to facing direction,
  -- if requested
  if proj.vx_facing then
   shot.vx=e.facing*abs(shot.vx)
  end
  if e.laser_clr then
   shot.cmap={[12]=e.laser_clr}
  end
  num_en_projs+=1
  -- if we hit the maximum number of projectiles, stop
  if num_en_projs>=k_max_en_projs then break end
 end
end

-- zigzag behavior
function ent_beh_zigzag(e)
 if not e.zigzag_initted then
  e.vy=(rnd()>0.5 and 1 or -1)*e.zigzag_v
  e.zigzag_initted=true
 end
 if e.y<k_zigzag_min_y then e.vy=abs(e.vy) end
 if e.y>k_zigzag_max_y then e.vy=-abs(e.vy) end
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

-- loads the luminosity tables.
function init_lum()
 g_lum={}
 for l=1,3 do
  add(g_lum,load_lum(l))
 end
end

-- loads lum table for light level l
function load_lum(l)
 local t={}
 -- t[0] is not filled as it's always 0 anyway.
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

-- looks up the lit value for the given color in the
-- given lum level.
function lum_look_up(l,c)
 -- lum table is at the start of sprite rom.
 -- first find the row:
 local addr=(c%8)*64
 -- if c is between 8 and 15, it's in the second col.
 if c>7 then addr+=2 end
 -- locate the column that corresponds to the lum lvl
 if l==1 then
  -- color level 1 is the left pixel
  return lo_nibble(peek(addr))
 elseif l==2 then
  -- color level 2 is the right pixel
  return hi_nibble(peek(addr))
 else
  -- color level 3 is the left pixel of the
  -- following byte
  return lo_nibble(peek(addr+1))
 end
end

-- returns the low nibble of a byte
function lo_nibble(b)
 return band(b,0x0f)
end

-- returns the high nibble of a byte
function hi_nibble(b)
 return lshr(band(b,0xf0),4)
end

-- makes a byte from two nibbles
function make_byte(hi_nib,lo_nib)
 return bor(lo_nib,shl(hi_nib,4))
end

-- applies lum level to byte (pair of pixels)
function light_b(l,b)
 -- byte 0 is two black pixels, so that maps to 0
 -- regardless and it's not in the lum tables.
 -- also, light level 0 maps everything to black.
 if b==0 or l<=0 then return 0 end
 -- light level >=4 maps every color to itself.
 if l>3 then return b end
 -- use the mapping table
 return g_lum[l][b] 
end

-- overlays (deeply) the fields of table b over the
-- fields of table a. so if a={x=1,y=2,z=3} and
-- b={y=42,foo="bar"}, then this will return:
-- {x=1,y=42,z=3,foo="bar"}.
function overlay(a,b)
 local result=deep_copy(a)
 for k,v in pairs(b) do
  if result[k] and type(result[k])=="table" and
    type(v)=="table" then
   -- recursive overlay.
   result[k]=overlay(result[k],v)
  else
   result[k]=deep_copy(v)
  end
 end
 return result
end

-- determines whether the two given rectangles
-- intersect. each rectangle must have x,y,w,h.
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

-- deletes item i from table, does not preserve
-- indices (end element will be replaced with it)
function fast_del(t,i)
 if i<1 or i>#t then return end
 local last=#t
 t[i]=t[last]
 t[last]=nil
end

-- prints centered text
function print_c(str,x,y,clr)
 print(str,x-2*#str,y,clr)
end

-- returns the 'meta value' of the given sprite,
-- or the given default value if the sprite is
-- not a meta sprite
function meta_value(sp,deflt)
 return (sp>=k_sp_meta0 and sp<=k_sp_meta0+15) and
  sp-k_sp_meta0 or deflt
end

function has_upgrade(up)
 return band_nz(g_sav.upgrades,up)
end

function grant_upgrade(up)
 g_sav.upgrades=bor(g_sav.upgrades,up)
 save_data()
end

-- loads data from persistent memory
function load_data()
 local addr=0x5e00
 g_sav=deep_copy(g_sav_templ)
 -- read format signature
 local sig=peek16i(addr) addr+=2
 -- if signature is missing, we have no data
 -- or it's corrupt, etc.
 if sig~=0x1234 then return end
 -- read level (16 bit int)
 g_sav.lvl=peek16i(addr) addr+=2
 -- read coins (16 bit int)
 g_sav.coins=peek16i(addr) addr+=2
 -- read upgrades (16 bit int)
 g_sav.upgrades=peek16i(addr) addr+=2
 -- read stats
 g_sav.coins_collected=peek16i(addr) addr+=2
 g_sav.coins_spent=peek16i(addr) addr+=2
 g_sav.enemies_killed=peek16i(addr) addr+=2
 g_sav.levels_played=peek16i(addr) addr+=2
 g_sav.deaths=peek16i(addr) addr+=2
 g_sav.powerups_collected=peek16i(addr) addr+=2
 g_sav.gameplay_minutes=peek16i(addr) addr+=2
end

-- saves data to persistent memory
function save_data()
 local addr=0x5e00
 local d=g_sav
 -- format signature (16 bit int)
 poke16i(addr,0x1234) addr+=2
 -- level (16 bit int)
 poke16i(addr,d.lvl) addr+=2
 -- coins (16 bit int)
 poke16i(addr,d.coins) addr+=2
 -- upgrades (16 bit int)
 poke16i(addr,d.upgrades) addr+=2
 -- write stats
 poke16i(addr,d.coins_collected) addr+=2
 poke16i(addr,d.coins_spent) addr+=2
 poke16i(addr,d.enemies_killed) addr+=2
 poke16i(addr,d.levels_played) addr+=2
 poke16i(addr,d.deaths) addr+=2
 poke16i(addr,d.powerups_collected) addr+=2
 poke16i(addr,d.gameplay_minutes) addr+=2
end

-- read 32bit fixed point number
--function peek32f(addr)
-- local n=0
-- n=bor(n,lshr(peek(addr),16))
-- n=bor(n,lshr(peek(addr+1),8))
-- n=bor(n,peek(addr+2))
-- n=bor(n,shl(peek(addr+3),8))
-- return n
--end

-- write 32bit fixed point number
--function poke32f(addr,v)
-- poke(addr,shl(band(v,0x0000.00ff),16))
-- poke(addr+1,shl(band(v,0x0000.ff00),8))
-- poke(addr+2,band(v,0x00ff))
-- poke(addr+3,lshr(band(v,0xff00),8))
--end

-- read 16bit integer
function peek16i(addr)
 local n=0
 n=bor(n,peek(addr))
 n=bor(n,shl(peek(addr+1),8))
 return n
end

-- returns an random integer in [a,b]
function irnd_incl(a,b)
 return a+flr(rnd(b-a+1))
end

-- write 16bit integer (ignores fractional part)
function poke16i(addr,v)
 poke(addr,band(v,0x00ff))
 poke(addr+1,lshr(band(v,0xff00),8))
end

-- gets the current background offset
function get_bg_off()
 -- offset is driven by the g_aclk clock so that it
 -- doesn't reset when we switch from k_mode_play
 -- to k_mode_dying, for instance.
 return band(shr(g_aclk,1),0x7f)
 -- 0x7f means mod 128 (128 is the screen width)
end

-- draw screen transition
function draw_scrt()
 if not g_scrt then return end
 local off=k_scrt_seq[g_scrt]

 local ptr=0x6000
 local tmp=ptr+64*127
 for y=0,126 do
  -- make a copy of the row below
  memcpy(tmp,ptr,64)
  if y%2==0 then
   -- shift row to the right
   memcpy(ptr+off,tmp,64-off)
   memset(ptr,0,off)
  else
   -- shift row to the left
   memcpy(ptr,tmp+off,64-off)
   memset(ptr+64-off,0,off)
  end
  ptr+=64
 end

 g_scrt+=1
 if g_scrt>#k_scrt_seq then g_scrt=nil end
end

function update_stats()
 -- special code to clear memory: hold down up
 -- and left, then hold down O, then tap X.
 if g_btn_up and g_btn_left then
  if g_btn_o and g_btnp_x then
   poke(0x5e00,0)
   load_data()
   set_mode(k_mode_title)
  end
 elseif g_btnp_x or g_btnp_o then
  set_mode(k_mode_hangar)
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

-- update/draw functions for each game mode
g_update_fun={
 [k_mode_title]=update_title,
 [k_mode_play]=update_play,
 [k_mode_dying]=update_dying,
 [k_mode_hangar]=update_hangar,
 [k_mode_shop]=update_shop,
 [k_mode_map]=update_map,
 [k_mode_stats]=update_stats,
 [k_mode_win]=update_win,
}
g_draw_fun={
 [k_mode_title]=draw_title,
 [k_mode_play]=draw_play,
 [k_mode_dying]=draw_dying,
 [k_mode_hangar]=draw_hangar,
 [k_mode_shop]=draw_shop,
 [k_mode_map]=draw_map,
 [k_mode_stats]=draw_stats,
 [k_mode_win]=draw_win,
}

