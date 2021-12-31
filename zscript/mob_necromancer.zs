// ------------------------------------------------------------
// Necromancer
// ------------------------------------------------------------
class BloodyHellFire:HDMobBase{
	default{
		+noblood
		+bright
		+lookallaround
		+frightening
		+dontgib
		+nofear
		+float
		-countkill
		-solid
		-shootable
		renderstyle "add";
		gravity 0.1;
		speed 10;
		minmissilechance 16;
		health 120;
		damagefactor "hot",0;
		meleerange 48;
		radius 12;
		height 16;
		damage 24;
		maxstepheight 128;
		tag "$CC_FLAME";
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_GiveInventory("ImmunityToFire");
	}
	override void tick(){
		super.tick();
		if(
			!isfrozen()
			&&!(level.time&(1|2|4))
			&&bshootable
		){
			A_StartSound("misc/firecrkl",CHAN_BODY,CHANF_OVERLAP);
			if(!(level.time&(1|2|4|8))){
				A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),frandom(1,6),frandom(-1,1),frandom(-1,1),frandom(1,3),0,SXF_ABSOLUTE,64);
				A_Trail();
				damagemobj(null,null,3,"maxhpdrain");
			}
		}
	}
	states{
	spawn:
		TNT1 A 0 A_Jump(256,"idle");
		TNT1 AAAAAAA random(4,6) A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),frandom(1,6),frandom(-1,1),frandom(-1,1),frandom(1,3),0,SXF_ABSOLUTE);
		TNT1 AAAAAAA random(1,4) A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),frandom(1,6),frandom(-1,1),frandom(-1,1),frandom(1,3),0,SXF_ABSOLUTE);
		TNT1 A 0 A_StartSound("vile/firestrt",CHAN_VOICE,CHANF_OVERLAP);
		TNT1 A 0 A_JumpIf(
			master
			&&(
				!master.target
				||master.target.countinv("ImmunityToFire")
				||(
					!master.checksight(master.target)
					&&!random(0,3)
				)
			)
		,"putto");
		TNT1 A 0 A_SetShootable();
		TNT1 A 0 A_SpawnItemEx("NecroFireLight",flags:SXF_SETTARGET);
		TNT1 AAAAA 0 A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),frandom(1,6),frandom(-1,1),frandom(-1,1),frandom(1,3),0,SXF_ABSOLUTE);
	idle:
		FIRE A 2 A_HDWander(CHF_LOOK);
		FIRE BABAB 2;
		loop;
	see:
		FIRE A 1 A_HDChase();
		FIRE BAB 1;
		loop;
	missile:
		FIRE A 1 A_FaceTarget();
		FIRE B 1{
			A_Recoil(-1);
			if(!random(0,15))A_SpawnProjectile("HeckFire",16,0,8);
		}
		goto see;
	melee:
		FIRE ABABABCBCBCDCDCDEDEFGFGFGFGHGHGH 2 A_VileFireMelee();
		stop;
	heal:
		FIRE ABABCBCDCDEDEFGFGFGHGH 1;
		stop;
	death:
		FIRE A 2{
			bnointeraction=true;
			bnofear=true;
			A_QuakeEx(2,2,5,20,0,256,"",QF_SCALEDOWN|QF_WAVE,10,10,10);
			A_HDBlast(pushradius:128,pushamount:64,source:master);
			A_Immolate(null,master,80);
			A_StartSound("misc/fwoosh",CHAN_BODY,CHANF_OVERLAP);
		}
		FIRE AABBCCDEFGH 2{
			let aaa=spawn("HDFlameRedBig",(pos.xy,pos.z+frandom(10,40)),ALLOW_REPLACE);
			if(aaa){
				aaa.target=master;
				aaa.vel=vel+(frandom(-1,1),frandom(-1,1),frandom(0.1,2));
			}
		}
		stop;
	putto:
		TNT1 A 0{
			let hdmm=hdmobbase(master);
			if(hdmm)hdmm.firefatigue+=HDCONST_MAXFIREFATIGUE;
		}
		TNT1 AAAAA 0 A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),frandom(1,6),frandom(-1,1),frandom(-1,1),frandom(1,3),0,SXF_ABSOLUTE);
		TNT1 A 0 A_SpawnItemEx("Putto",flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		stop;
	}
	double lasttargetangle;
	void A_VileFireMelee(){
		if(!target)return;
		setorigin((
			target.pos.xy+angletovector(target.angle,frandom(1,7)),
			target.pos.z+target.height*0.7
			),true
		);
		vel=(vel+target.vel)*0.5;
		A_StartSound("misc/firecrkl",CHAN_VOICE,CHANF_OVERLAP);
		A_Immolate(target,master,2);
		HDF.Give(target,"Heat",6);
		target.vel.z+=tics*HDCONST_GRAVITY+0.04;

		if(
			target.health>0
			&&absangle(lasttargetangle,target.angle)>frandom(0,500)
		)target=null;
		else lasttargetangle=target.angle;
	}
}
class NecroFireLight:PointLight{
	bool triggered;
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=200;
		args[1]=160;
		args[2]=70;
		args[3]=64;
		args[4]=0;
		triggered=false;
	}
	override void tick(){
		if(!target||target.bnointeraction){destroy();return;}
		setorigin(target.pos,true);
		if(!target.bnofear){
			if(!triggered){
				args[3]=128;
				triggered=true;
			}else args[3]=int(frandom(0.8,1.)*args[3]);
		}
		else args[3]=random(50,72);
	}
}

class HeckFire:HDActor{
	default{
		projectile;
		-nogravity
		+hittracer
		+slidesonwalls
		+noexplodefloor
		+seekermissile
		+nodamagethrust
		+bloodlessimpact
		+bright
		-noblockmap
		gravity 0.6;
		damagetype "hot";
		renderstyle "add";
		alpha 0.7;
		speed 12;
		radius 8;
		height 16;
	}
	states{
	spawn:
		FIRE ABAB random(1,2);
		TNT1 A 0 A_Gravity();
		FIRE ABAB random(1,2) A_SeekerMissile(2,4);
	see:
		FIRE A 0 A_Setscale(randompick(-1,1)*frandom(0.8,1.2),frandom(0.8,1.2));
		FIRE A random(1,2) A_StartSound("misc/firecrkl",CHAN_BODY,CHANF_OVERLAP);
		FIRE B random(1,2) A_NoGravity();
		FIRE A 0 A_Setscale(randompick(-1,1)*frandom(0.8,1.2),frandom(0.8,1.2));
		FIRE ABAB random(1,2) A_SeekerMissile(4,8);
		FIRE A 0 A_Setscale(randompick(-1,1)*frandom(0.8,1.2),frandom(0.8,1.2));
		FIRE A random(1,2) A_Jump(24,2);
		FIRE B random(1,2) A_Gravity();
		loop;
	death:
	fade:
		FIRE CDCDEFEFGH 2;
		stop;
	xdeath:
		FIRE C 1{
			A_StartSound("misc/firecrkl",CHAN_BODY,CHANF_OVERLAP);
			if(tracer)A_Immolate(tracer,target?target.master:null,1);
		}
		FIRE DCDCB 1{
			if(!tracer)return;
			A_Face(tracer);
			A_Recoil(-speed*0.3);
		}
		FIRE CBABAB 1;
		FIRE B 0 A_Jump(8,"see");
		FIRE B 0{
			A_StartSound("misc/firecrkl",CHAN_BODY,CHANF_OVERLAP);
			if(tracer)bmissile=true;
		}
		goto see;
	}
}

class Necromancer:HDMobBase replaces ArchVile{
	string nickname;
	default{
		mass 500;
		maxtargetrange 896;
		seesound "vile/sight";
		painsound "vile/pain";
		deathsound "vile/death";
		activesound "vile/active";
		meleesound "vile/stop";
		obituary "%o met the firepower of the $TAG.";
		tag "$CC_ARCH";
		
		+shadow
		+nofear
		+seeinvisible
		+frightening
		+dontgib
		+floorclip
		+hdmobbase.doesntbleed
		+hdmobbase.biped;
		+hdmobbase.chasealert
		+nopain
		radius 16;
		height 56;
		scale 0.8;
		renderstyle "normal";
		bloodcolor "ff ff 44";
		damagetype "hot";
		speed 14;
		painchance 0;
		health 1000;
	}
	static void A_MassHeal(actor caller){
		actor aaa;
		blockthingsiterator it=blockthingsiterator.create(caller,256);
		while(it.next()){
			aaa=it.thing;
			if(
				aaa.bcorpse
				&&aaa.findstate("raise")
				&&aaa.checksight(caller)
			){
				int dist=int(max(
					abs(aaa.pos.x-caller.pos.x),
					abs(aaa.pos.y-caller.pos.y),
					abs(aaa.pos.z-caller.pos.z)
				));
				actor hhh=spawn("HDRaiser",aaa.pos,ALLOW_REPLACE);
				hhh.A_SetFriendly(caller.bfriendly);
				hhh.friendplayer=caller.friendplayer;
				hhh.master=aaa;
				hhh.tracer=caller;
				hhh.stamina=(dist>>3)+random(10,30);
			}
		}
	}
	override void beginplay(){
		hitsleft=bfriendly?7:6;
		super.beginplay();
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(
			!bfriendly
			&&hd_novilespam
			&&A_CheckProximity("null","Necromancer",2018,2,CPXF_NOZ)
		){
			A_Die("mapmorph");
			return;
		}

		voicepitch=1.+frandom(-1.,1.);

		//spawn shards instead if no archvile sprites
		if(Wads.CheckNumForName("VILER0",wads.ns_sprites,-1,false)<0){
			for(int i=0;i<99;i++){
				actor vvv;
				[bmissilemore,vvv]=A_SpawnItemEx("BFGNecroShard",
					frandom(-3,3),frandom(-3,3),frandom(1,6),
					frandom(0,30),0,frandom(1,12),frandom(0,360),
					SXF_SETMASTER|SXF_TRANSFERPOINTERS|SXF_ABSOLUTEPOSITION
				);
				vvv.A_SetFriendly(bfriendly);
			}
			A_AlertMonsters();
			destroy();
			return;
		}

		bsmallhead=bplayingid;

		nickname=RandomName();

		resize(0.8,1.3);
		A_GiveInventory("ImmunityToFire");
	}
	int hitsleft;
	void A_ChangeNecroFlags(bool attacking){
		if(!attacking){
			A_UnSetShootable();
			A_UnSetSolid();
			bnofear=false;
			bfrightened=true;
			maxstepheight=1024;
			maxdropoffheight=1024;
			A_SetRenderStyle(1.,STYLE_Add);
		}else{
			A_SetShootable();
			A_SetSolid();
			bnofear=true;
			bfrightened=false;
			maxstepheight=default.maxstepheight;
			maxdropoffheight=default.maxdropoffheight;
			A_SetRenderStyle(1.,STYLE_Normal);
		}
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			damage==TELEFRAG_DAMAGE
			||mod=="mapmorph"
		)return actor.damagemobj(inflictor,source,damage,mod,flags,angle);

		if(
			(
				(
					mod!="hot"
					&&mod!="balefire"
				)||(
					source
					&&source.target==self
					&&(
						Putto(source)
						||Necromancer(source)
					)
				)
			)
			&&damage>random(0,bfriendly?333:166)
		){
			if(hitsleft>0){
				hitsleft--;
				bshootable=false;
				if(!bfriendly)A_ChangeNecroFlags(false);

				if(
					!bfriendly
					&&!target
				){
					setstatelabel("painedandgone");
					DistantNoise.Make(self,painsound,pitch:voicepitch);
					target=source;
					A_AlertMonsters();
					return -1;
				}

				if(!target)target=source;
				setstatelabel("pain");

				DistantNoise.Make(self,"world/rocketfar");
				A_SpawnItemEx("SpawnFire",0,0,28,flags:SXF_NOCHECKPOSITION);
				A_Explode(46,196);
				A_Quake(3,36,0,360);
				A_AlertMonsters();
				A_Vocalize(painsound);
				for(int i=0;i<3;i++)A_SpawnItemEx("BFGNecroShard",
					0,0,42,flags:SXF_SETMASTER|SXF_TRANSFERPOINTERS
				);
			}else return actor.damagemobj(
				inflictor,source,health,
				mod,DMG_FORCED|DMG_THRUSTLESS
			);
		}
		return -1;
	}
	states{
	spawn:
		VILE A 0 A_JumpIf(!bshootable,"painedandgone");
		VILE AB 10 A_HDLook();
		loop;
	see:
		VILE A 0 A_JumpIf(!bfriendly,2);
		VILE H 0 A_ClearTarget();
		VILE ABCDEF 5 A_HDChase();
		loop;
	missile:
		VILE G 10 bright{
			bnopain=false;
			A_FaceTarget();
		}
		VILE H 2 bright light("CANF") A_ChangeNecroFlags(true);
		VILE HHH 3 bright light("CANF");
		TNT1 A 0 A_FaceTarget();
		VILE IJ 4 bright light("CANF");
		VILE KKL 4 bright light("HECK");
		VILE L 8 bright light("HELL") A_FaceTarget();
		VILE MN 2 bright light("HELL");
		TNT1 A 0 A_FaceTarget();
		VILE NOO 2 bright;
		VILE P 0{
			A_FaceTarget();
			let ppp=spawn("BloodyHellFire",lasttargetpos,ALLOW_REPLACE);
			if(ppp){
				ppp.master=self;
				ppp.target=target;
				ppp.A_SetFriendly(bfriendly);
				ppp.friendplayer=friendplayer;
				firefatigue+=HDCONST_MAXFIREFATIGUE;
			}
		}
		VILE PO 4 bright light("HELL");
		VILE N 8 bright light("HELL");
		---- A 0 setstatelabel("see");
	heal:
		VILE A 0 A_ChangeNecroFlags(true);
		VILE \\ 8 bright light("HEAL");
		VILE # 8 bright light("HEAL"){
			if(bfriendly){
				hitsleft=7;
				flinetracedata hlt;
				linetrace(
					angle,radius*3,0,
					flags:TRF_THRUBLOCK|TRF_THRUHITSCAN|TRF_ALLACTORS,
					offsetz:8,
					data:hlt
				);
				if(hlt.hitactor){
					let hdmb=hdmobbase(hlt.hitactor);
					if(hdmb)hdmb.bodydamage=0;
					hlt.hitactor.A_SetFriendly(bfriendly);
				}
			}else{
				A_MassHeal(self);
				A_SetTics(16);
			}
		}
		---- A 0 setstatelabel("see");
	pain:
		VILE Q 20 light("HELL");
		VILE H 0 A_JumpIf(bfriendly,"see");
	pained:
		VILE A 1 A_Chase(null,null);
		VILE AA 0 A_Chase(null,null);
		VILE B 1 A_Chase(null,null);
		VILE AA 0 A_Chase(null,null);
		VILE C 1 A_Chase(null,null);
		VILE AA 0 A_Chase(null,null);
		VILE F 0 A_SetTranslucent(alpha-0.2,1);
		VILE D 1 A_Chase(null,null);
		VILE AA 0 A_Chase(null,null);
		VILE E 1 A_Chase(null,null,CHF_RESURRECT);
		VILE AA 0 A_Chase(null,null,CHF_RESURRECT);
		VILE F 1 A_Chase(null,null,CHF_RESURRECT);
		VILE AA 0 A_Chase(null,null,CHF_RESURRECT);
		VILE F 0 A_SetTranslucent(alpha-0.2,1);
		VILE F 0 A_JumpIf(alpha<0.1,"painedandgone");
		loop;
	painedandgone:
		TNT1 AAAAAAAAA 0 A_Wander();
		TNT1 A 0 A_SetTics(random(350,3500));
		VILE F 0 A_ChangeNecroFlags(true);
		---- A 0 setstatelabel("see");
	death:
		VILE Q 0 A_ChangeNecroFlags(false);
		VILE Q 42 bright A_Vocalize(painsound);
		VILE Q 0 A_FaceTarget();
		VILE Q 0 A_Quake(2,40,0,768,0);
		VILE G 6 bright light("HELL") A_SetTranslucent(0.8,1);
		VILE G 6 A_SetTranslucent(0.4,1);
		VILE G 6 bright light("HELL") A_SetTranslucent(0.8,1);
		VILE G 6 A_SetTranslucent(0.4,1);
		VILE G 6 bright light("HELL") A_Vocalize(painsound);
		VILE Q 0 A_Quake(4,40,0,768,0);
		VILE G 4 bright light("HELL") A_SetTranslucent(0.8,1);
		VILE G 4 A_SetTranslucent(0.4,1);
		VILE G 4 bright light("HELL") A_SetTranslucent(0.8,1);
		VILE G 4 A_SetTranslucent(0.4,1);
		VILE G 4 bright light("HELL") A_Vocalize(painsound);
		VILE G 2 bright light("HELL") A_SetTranslucent(1,1);
		VILE G 2 A_SetTranslucent(0.5,1);
		VILE G 2 bright light("HELL") A_SetTranslucent(1,1);
		VILE G 2 A_SetTranslucent(0.5,1);
		VILE G 0 A_SetTranslucent(1,1);
		VILE Q 0 A_Quake(6,8,0,768,0);
		VILE GGG 2 bright light("HELL")A_Vocalize(painsound);
	xdeath:
		VILE Q 6 bright light("HELL"){
			A_Explode(72,196);
			A_StartSound("weapons/rocklx",CHAN_WEAPON);
			A_SpawnItemEx("NecroDeathLight",flags:SXF_SETTARGET);
			A_SpawnItem("spawnFire",0.1,28,0,0);
			A_Vocalize(deathsound);
			DistantNoise.Make(self,"world/rocketfar",2.);
		}
		VILE Q 14 bright light("HELL") A_Quake(8,14,0,768,0);
		VILE QQQQQQ 0 A_SpawnItemEx("SpawnFire",
			frandom(-3,3),frandom(-3,3),frandom(25,30),
			frandom(-3,3),frandom(-3,3),frandom(0.5,4),
			flags:SXF_ABSOLUTE
		);
		VILE Q 0 A_Quake(3,26,0,1024,0);
		VILE QQQQQ 8 A_SpawnItemEx("NecroShard",frandom(-8,8),frandom(-8,8),frandom(26,50),frandom(-1,1),0,0,frandom(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
	fade:
		VILE QQ 2 A_SpawnItemEx("NecroShard",frandom(-8,8),frandom(-8,8),frandom(26,50),frandom(-1,1),0,0,frandom(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,16);
		VILE Q 8 A_fadeOut(0.05);
		VILE Q 0 A_JumpIf(alpha < 0.10,1);
		loop;
		VILE Q 8 A_fadeOut(0.04);
		TNT1 A 8 A_SpawnItemEx("NecroShard",frandom(-8,8),frandom(-8,8),frandom(26,50),frandom(-1,1),0,0,frandom(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,16);
		TNT1 A 0 A_NoBlocking();
		TNT1 AAAAA 12 A_SpawnItemEx("NecroShard",frandom(-8,8),frandom(-8,8),frandom(26,50),frandom(-1,1),0,0,frandom(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,16);
	dead:
		TNT1 A 20;
		TNT1 A 0 A_Jump(1,"ghost");
		loop;
	ghost:
		TNT1 A 20 A_Warp(AAPTR_TARGET,0,0,32,0,WARPF_NOCHECKPOSITION);
		TNT1 A 80 A_Quake(1,40,0,512,"vile/curse");
		TNT1 AAAAAA 0 A_SpawnItemEx("NecroGhostShard",flags:SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION);
		TNT1 A 40;
		TNT1 A 1 A_MassHeal(self);
		stop;

	death.mapmorph:
		TNT1 A 0 A_Jump(128,"rep_np","rep_baron");
	rep_imp:
		TNT1 AAAA 0 A_SpawnItemEx("Regentipede",flags:SXF_NOCHECKPOSITION|SXF_TRANSFERAMBUSHFLAG);
		stop;
	rep_np:
		TNT1 AAA 0 A_SpawnItemEx("NinjaPirate",flags:SXF_NOCHECKPOSITION|SXF_TRANSFERAMBUSHFLAG);
		stop;
	rep_baron:
		TNT1 A 0 A_SpawnItemEx("PainLord",flags:SXF_NOCHECKPOSITION|SXF_TRANSFERAMBUSHFLAG);
		TNT1 AA 0 A_SpawnItemEx("PainBringer",flags:SXF_NOCHECKPOSITION|SXF_TRANSFERAMBUSHFLAG);
		stop;
	}
}
class NecroDeathLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=255;
		args[1]=200;
		args[2]=100;
		args[3]=256;
		args[4]=0;
	}
	override void tick(){
		if(isfrozen())return;
		if(!target||target.bnointeraction){destroy();return;}
		args[3]=int(target.alpha*randompick(1,3,7)*frandom(12,16));
		setorigin(target.pos,true);
	}
}
class LightBearer:Necromancer{
	default{
		+friendly
		+noclip
		+noblockmonst
		maxstepheight 4096;
		maxdropoffheight 4096;
		painchance 56;
		scale 1.0;
		speed 18;
		species "LightBearer";
	}
}
class HDRaiser:Actor{
	default{
		+nointeraction
	}
	void A_RaiseThis(){
		if(!master||master.health>0){destroy();return;}
		A_RaiseMaster(RF_TRANSFERFRIENDLINESS|RF_NOCHECKPOSITION);
		master.master=tracer;
	}
	states{
	spawn:
		TNT1 A 10 nodelay A_SetTics(stamina);
		TNT1 A 0 A_RaiseThis();
		stop;
	}
}

class NecroGhostShard:NecroShard{
	default{
		+ismonster
		-countkill
		+noclip
		+nogravity
		+lookallaround
		+nosector
		+nofear
		height 56;
		radius 20;
		speed 20;
	}
	states{
	spawn:
		TNT1 A 2 A_VileChase();
		loop;
	heal:
		TNT1 A 1{Necromancer.A_MassHeal(self);}
		stop;
	}
}
class NecroShard:HDActor{
	default{
		+ismonster
		+float
		+nogravity
		+noclip
		+lookallaround
		translation 1;
		scale 0.6;
		radius 0;
		height 0;
		renderstyle "add";
		speed 5;
	}
	states{
	spawn:
		APLS A 0;
		APLS A 0 A_SetGravity(0.1);
		APLS AB 1 bright A_Look();
		loop;
	see:
		APLS A 0 A_Jump(64,2);
		APLS A 0 {vel.z+=frandom(-4,8);}
		APLS A 2 bright A_JumpIf(alpha<0.1,"null");
		APLS B 2 A_Wander();
		APLS A 0 A_SpawnProjectile("NecroShardTail",0,random(-24,24),random(-24,24),2,random(-14,14));
		APLS A 2 bright;
		APLS A 0 A_Wander();
		APLS B 2 bright A_fadeOut(0.05);
		APLS A 0 A_Wander();
		loop;
	heal:
		TNT1 A 1;
		stop;
	}
}
class NecroShardTail:HDActor{
	default{
		projectile;
		+noclip
		+nogravity
		speed 2;
		scale 0.4;
		translation 1;
		renderstyle "add";
	}
	states{
	spawn:
		APLS AB 2 bright nodelay A_fadeOut(0.01);
		APLS A 0 ThrustThingZ(0,random(-4,8),0,0);
		loop;
	}
}

class iusearch:archvile{}
