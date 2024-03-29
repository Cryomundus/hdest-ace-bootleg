// ------------------------------------------------------------
// Spectre
// ------------------------------------------------------------
class NinjaPirate:HDMobBase{ //replaces Spectre{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Ninja Pirate"
		//$Sprite "SARGA1"

		monster;
		renderstyle "translucent";
		translation "64:79=24:44";
		damagefactor "Balefire",0.3;
		hdmobbase.shields 120;
		tag "ninja pirate";
		seesound "";
		painsound "demon/pain";
		deathsound "demon/death";
		activesound "demon/active";
		health 200;
		gibhealth 200;
		painchance 200;
		height 50;
		radius 18;
		meleerange 48;
		meleethreshold 512;
		+hdmobbase.climber
		+hdmobbase.climbpastdropoff
		maxdropoffheight 64;
		maxstepheight 32;
		speed 16;
		mass 300;
		damage 8;
		//obituary "%o died.";
		dropitem "HDBlurSphere",4;
	}
	override string getobituary(actor victim,actor inflictor,name mod,bool playerattack){
		return "";
	}
	bool cloaked;
	void Cloak(bool which=true){cloaked=which;}
	override void postbeginplay(){
		super.postbeginplay();
		resize(frandom(0.9,1.1));
		cloaked=false;
		bbiped=bplayingid;
	}
	void A_BlurWander(bool dontlook=false){
		A_HDWander(dontlook?0:CHF_LOOK);
		A_SpawnItemEx("NinjaPirateBlurA",frandom(-2,2),frandom(-2,2),frandom(-2,2),flags:SXF_TRANSFERSPRITEFRAME);
	}
	void A_BlurChase(){
		speed=getdefaultbytype(getclass()).speed;
		A_HDChase();
		A_SpawnItemEx("NinjaPirateBlurA",frandom(-2,2),frandom(-2,2),frandom(-2,2),flags:SXF_TRANSFERSPRITEFRAME);
	}
	void A_CloakedChase(){
		bfrightened=health<90;
		frame=(level.time&(1|2|4|8))>>2;
		if(!(level.time&3)){
			alpha=!random(0,7);
			A_SetTranslucent(alpha,alpha?2:0);
			if(!(level.time&4))GiveBody(1);
		}
		bshootable=alpha||random(0,15);
		speed=(bshootable&&alpha)?5:getdefaultbytype(getclass()).speed;
		A_Chase("melee",flags:CHF_NIGHTMAREFAST);

		bool tsighted=target&&checksight(target);

		if(
			!random(0,15)
			&&health>160
			&&!tsighted
		)setstatelabel("uncloak");
		else if(
			target
			&&health<100
			&&!random(0,63)
		){
			let rrr=spawn("DeadRingerNinjaPirate2",(pos.xy,floorz),ALLOW_REPLACE);
			rrr.scale=scale;
		}
	}
	void A_Uncloak(){
		for(int i=0;i<3;i++)A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),frandom(4,24),vel.x,vel.y,vel.z+frandom(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
		cloaked=false;
		bfrightened=false;
		bsolid=true;
		bshootable=true;
		bnopain=false;
		bshadow=false;
		bnotarget=false;
	}
	states{
	spawn:
		TNT1 A 0 nodelay A_JumpIf(cloaked,"SpawnUnCloak");
	spawn2:
		TNT1 A 0 A_JumpIf(!bambush,"spawnwander");
		TNT1 A 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(4,24),vel.x,vel.y,vel.z+random(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
		TNT1 A 0 Cloak();
	spawnstillcloaked:
		TNT1 A 0 GiveBody(2);
		TNT1 A 10 A_HDLook();
		loop;
	spawnwander:
		SARG ABCD 8 A_BlurWander();
		TNT1 A 0 A_Jump(48,"spawnstill");
		TNT1 A 0 A_Jump(48,1);
		loop;
		TNT1 A 0 A_StartSound("demon/active",CHAN_VOICE);
		TNT1 A 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(4,24),vel.x,vel.y,vel.z+random(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
		TNT1 A 0 Cloak();
	spawnwandercloaked:
		TNT1 A 0 GiveBody(2);
		TNT1 A 0 A_HDLook();
		TNT1 A 7 A_Wander();
		TNT1 A 0 A_Jump(12,1);
		loop;
		TNT1 A 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(4,24),vel.x,vel.y,vel.z+random(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
		TNT1 A 0 A_UnCloak();
		TNT1 A 0 A_StartSound("demon/active",CHAN_VOICE);
	spawnstill:
		SARG E 10 A_Jump(48,"spawnwander");
		TNT1 A 0 A_HDLook();
		SARG E 10 A_SetAngle(angle+random(-20,20));
		SARG EEFF 10 A_HDLook();
		loop;
	spawnuncloak:
		SARG G 0 A_Uncloak();
		SARG B 0 A_SetTranslucent(0,0);
		SARG B 2 A_SetTranslucent(0.2);
		SARG B 2 A_SetTranslucent(0.4);
		SARG B 2 A_SetTranslucent(0.6);
		SARG B 2 A_SetTranslucent(0.8);
		SARG B 2 A_SetTranslucent(1);
		goto spawn2;
	see:
		TNT1 A 0 A_JumpIf(cloaked,"seecloaked");
		TNT1 A 0{bnopain=false;}
		goto seerunnin;
	seerunnin:
		SARG ABCD 4 A_BlurChase();
		TNT1 A 0 Cloak(randompick(0,0,0,1));
		---- A 0 setstatelabel("see");
	seecloaked:
		SARG A 1 A_CloakedChase();
		loop;
	uncloak:
		SARG G 0 A_Uncloak();
		SARG G 0 A_SetTranslucent(0,0);
		SARG G 1 A_SetTranslucent(0.2);
		SARG G 1 A_SetTranslucent(0.4);
		SARG G 1 A_SetTranslucent(0.6);
		SARG G 1 A_SetTranslucent(0.8);
		SARG G 0 A_SetTranslucent(1);
		---- A 0 setstatelabel("see");
	melee:
		SARG G 0 A_JumpIf(cloaked,"Uncloak");
		SARG E 0 A_StartSound("demon/melee",CHAN_VOICE);
		SARG E 4 A_FaceTarget();
		SARG F 5 A_FaceTarget();
		SARG F 0{
			A_CustomMeleeAttack(random(1,3)*2,"misc/bulletflesh","","piercing",true);

			//he kills to heal himself
			if(!target||target.health<1)GiveBody(spawnhealth());

			if(
				target
				&&distance3dsquared(target)<(50*50)
				&&checkmove(0.5*(pos.xy+target.pos.xy),PCM_NOACTORS)
				&&(random(0,3))
			){
				setstatelabel("latch");
			}
		}
		SARG GGGG 0 A_CustomMeleeAttack(random(1,18),"misc/bulletflesh","","teeth",true);
	meleeend:
		SARG G 10;
		---- A 0 setstatelabel("see");
	latch:
		SARG EEF 1{
			A_FaceTarget();
			A_ChangeVelocity(1,0,0,CVF_RELATIVE);
			if(!random(0,19))A_Pain();else if(!random(0,9))A_StartSound("babuin/bite",CHAN_WEAPON);
			if(!random(0,200)){
				A_ChangeVelocity(-1,0,0,CVF_RELATIVE);
				A_ChangeVelocity(-2,0,2,CVF_RELATIVE,AAPTR_TARGET);
				setstatelabel("see");
				return;
			}
			if(
				!target
				||target.health<1
				||distance3d(target)>50
			){
					setstatelabel("meleeend");
					return;
			}
			A_ScaleVelocity(0.2,AAPTR_TARGET);
			A_ChangeVelocity(random(-1,1),random(-1,1),random(-1,1),0,AAPTR_TARGET);
			A_DamageTarget(random(0,5),random(0,3)?"teeth":"jointlock",0,"none","none",AAPTR_DEFAULT,AAPTR_DEFAULT);

			//he kills to heal himself
			if(!target||target.health<1)GiveBody(spawnhealth());
		}loop;
	pain:
		SARG G 1 {bnopain=true;}
		SARG G 0 A_Jump(48,"DeadRinger");
		SARG G 3 A_Pain();
		goto cloak;
	deadringer:
		SARG G 0 A_Scream();
		SARG G 0 A_SpawnItemEx("DeadRingerNinjaPirate",0,0,0,vel.x,vel.y,vel.z,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
		goto cloak;
	cloak:
		SARG GGG 0 A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),frandom(4,24),vel.x,vel.y,vel.z+random(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
		SARG G 0{
			bnopain=true;
			bfrightened=true;
			bnotarget=true;
			bshadow=true;
			Cloak();
		}
		SARG G 1 A_SetTranslucent(0.8);
		SARG G 1 A_SetTranslucent(0.4);
		SARG G 1 A_SetTranslucent(0.2,2);
		TNT1 AAAAA 0 A_Chase(null);
		---- A 0 setstatelabel("see");
	death:
		---- A 0 A_SpawnItemEx("BFGNecroShard",0,0,0,0,0,5,0,SXF_TRANSFERPOINTERS|SXF_SETMASTER,196);
		TNT1 A 0 A_Jump(128,2);
		TNT1 A 0 A_JumpIf(cloaked,"DeathCloaked");
		SARG GGG 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(4,24),vel.x,vel.y,vel.z+random(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
	deathend:
		TNT1 A 0 A_SetTranslucent(1);
		SARG I 8;
		SARG J 8 A_Scream();
		SARG K 4;
		SARG L 4 A_NoBlocking();
		SARG M 4;
	dead:
	death.spawndead:
		TNT1 A 0 A_FadeIn(0.01);
		SARG M 3 canraise A_JumpIf(floorz>pos.z-6,1);
		loop;
		SARG N 5 canraise A_JumpIf(floorz<=pos.z-6,"dead");
		loop;
	deathcloaked:
		TNT1 A 20 A_SetTranslucent(1);
		TNT1 A 4 A_NoBlocking;
		TNT1 A 4 A_SetTranslucent(0,0);
		SARG N 350 A_SetTics(random(10,15)*35);
		goto dead;
		SARG NNNNNNNNNN 20 A_FadeIn(0.1);
		SARG N -1;
		stop;
	raise:
		SARG N 4 A_SetTranslucent(1,0);
		TNT1 A 0 A_JumpIf(cloaked,"raisecloaked");
		SARG NMLKJI 6;
		#### A 0 A_Jump(256,"see");
	raisecloaked:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(4,24),vel.x,vel.y,vel.z+random(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
		SARG NNNNNN 4 A_FadeOut(0.15);
		TNT1 A 0 A_SetTranslucent(0,0);
		#### A 0 A_Jump(256,"see");
	ungib:
		SARG U 6{
			cloaked=false;
			if(alpha<1.){
				A_SetTranslucent(1);
				A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(4,24),vel.x,vel.y,vel.z+random(1,3),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,0);
			}
			A_SpawnItemEx("MegaBloodSplatter",0,0,4,
				vel.x,vel.y,vel.z+3,0,
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
		}
		SARG UT 8;
		SARG SRQ 6;
		SARG PO 4;
		#### A 0 A_Jump(256,"see");
	xdeath:
		SARG O 0 A_XScream();
		SARG O 0 A_NoBlocking();
		SARG OPQ 4 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		SARG RST 4;
		goto xdead;
	xxxdeath:
		SARG O 0 A_XScream();
		SARG O 4 A_NoBlocking();
		SARG PQRST 4;
	xdead:
		SARG T 0 A_FadeIn(0.01);
		SARG T 5 canraise{
			if(abs(vel.z)<2)frame++;
		}loop;
	}
}
class DeadRingerNinjaPirate:HDActor{
	default{
		+nointeraction
	}
	states{
	spawn:
		TNT1 A 0 A_SetTranslucent(1);
		SARG JJJJJJJJKKKKLLLLMMMM 1 {vel*=0.8;}
		SARG N 350 {vel=(0,0,0);}
		SARG N 20 A_FadeOut(0.1);
		wait;
	}
}
class DeadRingerNinjaPirate2:DeadRingerNinjaPirate{
	default{
		alpha 0;
	}
	states{
	spawn:
		TNT1 A random(0,TICRATE*5);
	idle:
		SARG N 5 A_FadeIn(0.01);
		SARG N 0 A_JumpIf(alpha>=1.,"death");
		loop;
	death:
		SARG N 350;
		SARG N 20 A_FadeOut(0.1);
		wait;
	}
}
class NinjaPirateBlurA:HDActor{
	default{
		+nointeraction
		alpha 0.6;
	}
	states{
	spawn:
		SARG # 0 nodelay A_ChangeVelocity(frandom(-1,3),frandom(-1,1),frandom(-1,1));
		SARG # 1 A_FadeOut(0.05);
		wait;
	}
}




// ------------------------------------------------------------
// Spectre Spawner
// ------------------------------------------------------------
class SpectreSpawner:RandomSpawner replaces Spectre{
	default{
		+ismonster
		dropitem "NinjaPirate",256,5;
		dropitem "SpecBabuin",256,20;
		dropitem "ShellShade",256,1;
	}
}
class BabuSpectreSpawner:RandomSpawner replaces Demon{
	default{
		+ismonster
		dropitem "Babuin",256,17;
		dropitem "NinjaPirate",256,1;
		dropitem "SpecBabuin",256,2;
	}
}

class DeadSpectre:NinjaPirate{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
	states{
	death:spawndead:
		---- A 0{
			A_NoBlocking();
			A_SetTranslucent(1,0);
		}
		goto super::dead;
	}
}

