// ------------------------------------------------------------
// Putto
// ------------------------------------------------------------
class Putto:HDMobBase{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Putto"
		//$Sprite "BOSFA0"

		monster; +nogravity +float +floatbob
		+avoidmelee +lookallaround
		+pushable +dontfall +cannotpush +thruspecies
		+hdmobbase.doesntbleed
		+hdmobbase.novitalshots
		+hdmobbase.headless
		-telestomp -solid
		species "BaronOfHell";
		tag "putto";
		damagefactor "hot", 1.2;
		damagefactor "Balefire", 0.1;
		health 80;
		radius 11;
		height 32;
		scale 0.666;
		speed 2;
		mass 60;
		painchance 80;
		obituary "Putti putti putti putti, everyone let's eat %o, giga-putti!";
		bloodcolor "22 22 24";
		seesound "putto/sight";
		painsound "putto/pain";
		deathsound "putto/death";
		activesound "putto/active";
		translation 0;
	}
	states{
	spawn:
		BOSF A 0 nodelay{
			if(Wads.CheckNumForName("BOSFA0",wads.ns_sprites,-1,false)<0)
				sprite=getspriteindex("PINVA0");
		}
	spawn2:
		#### ABCD 6{
			A_HDLook();
			if(!random(0,31)) A_StartSound(activesound);
		}
		loop;
	see:
		#### A 0{
			if(!random(0,16))vel.z+=frandom(-4,4);
		}
		#### ABCD 4 A_HDChase();
		loop;
	missile:
		#### AB 3;
		#### CDA 2;
		#### B 1 A_StartSound("putto/spit",CHAN_WEAPON);
		#### C 1 A_SpawnProjectile("BaleBall",16);
		#### DABCD 1;
		#### ABCD 2;
		#### ABCD 3;
		---- A 0 setstatelabel("see");
	pain:
		#### DAB 1;
		#### C 1 A_Recoil(4);
		#### D 1 A_Pain;
		#### ABCD 2 A_FastChase();
		#### ABCD 3;
		goto missile;
	death:
		#### AABB 1 A_SpawnItemEx(
			"HDSmoke", random(-2,2),random(-2,2),random(4,8),
			vel.x,vel.y,vel.z+2, flags:SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		TNT1 A 1{
			A_SpawnItemEx("HDExplosion",0,0,3,
				vel.x,vel.y,vel.z+1,0,
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
			A_Scream();
			A_NoBlocking();
			if(master)master.stamina--;
		}
		TNT1 AA 1 A_SpawnItemEx("HDSmokeChunk",0,0,3,
			vel.x+frandom(-4,4),vel.y+frandom(-4,4),vel.z+frandom(1,6),
			0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		stop;
	}
}
