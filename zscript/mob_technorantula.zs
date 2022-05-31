// ------------------------------------------------------------
// Spider Mastermind
// ------------------------------------------------------------
class Technorantula:HDMobBase replaces SpiderMastermind{
	default{
		height 100;
		mass 1000;
		+boss
		+missilemore
		+floorclip
		+dontmorph
		+bossdeath
		+hdmobbase.headless
		seesound "spider / sight";
		attacksound "spider / attack";
		painsound "spider / pain";
		deathsound "spider / death";
		activesound "spider / active";
		tag "$cc_spider";

		+noblooddecals
		+nodropoff +nofear
		+noblooddecals bloodtype "NotQuiteBloodSplat";
		maxstepheight 72;
		maxdropoffheight 72;
		speed 24;
		painchance 80;
		damagefactor "hot", 0.9;
		damagefactor "cold", 0.8;
		hdmobbase.shields 8000;
		obituary "%o was operated upon by the $TAG.";
		maxtargetrange 0;
		health 3000;
		radius 76;
		radiusdamagefactor 0.8;
	}
	override void tick(){
		super.tick();
		if (
			bnofear&&
			health < 1000&&
			!random(0, max(10, health))
		)A_SpawnItemEx("HDSmoke", 
			random(-32, 32), random(-32, 32), random(46, 96), 
			0, 0, random(2, 4), 0, 160, 64
		);
	}
	int shotchannel;
	int shotcount;
	double spread;
	states{
	spawn:
		SPID A 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID AABBC 4 A_HDWander();
	spawn2:
		SPID C 1 A_Recoil(1);
		SPID C 3{
			A_Look();
			angle += random(-4, 4);
			if (!random(0, 12))setstatelabel("spawn3");
		}wait;
	spawn3:
		SPID # 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID DDEEF 4 A_HDWander();
	spawn4:
		SPID F 1 A_Recoil(1);
		SPID F 3{
			A_Look();
			angle += random(-4, 4);
			if (!random(0, 12))setstatelabel("spawn");
		}wait;
	see:
		SPID A 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID AAABBB 2 A_HDChase();
		SPID C 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID CCCDDD 2 A_HDChase();
		SPID E 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID EEEFFF 2 A_HDChase();
		SPID A 0 A_JumpIfTargetInLOS("see");
	roam:
		SPID # 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID AABB 3 A_HDWander(CHF_LOOK);
		SPID # 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID CC 3 A_HDWander(CHF_LOOK);
		SPID # 0 A_Jump(48, "roamc");
	roam2:
		SPID DD 3 A_HDWander(CHF_LOOK);
		SPID # 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID EEFF 3 A_HDWander(CHF_LOOK);
		SPID # 0 A_Jump(48, "roamf");
		SPID # 0 A_JumpIfTargetInLOS("see");
		goto roam;
	roamc:
		SPID # 0 A_Recoil(-1);
		SPID CC 2 A_Chase("missile", "missile", CHF_DONTMOVE);
		SPID # 0 A_Recoil(1);
	roamc2:
		SPID CCCCCC 1 A_Chase("missile", "missile", CHF_DONTMOVE);
		SPID # 0 A_Jump(48, 1);
		loop;
		SPID # 0 A_StartSound("spider / walk", CHAN_BODY);
		goto roam2;
	roamf:
		SPID # 0 A_Recoil(-1);
		SPID FF 2 A_Chase("missile", "missile", CHF_DONTMOVE);
		SPID # 0 A_Recoil(1);
	roamf2:
		SPID FFFFFF 1 A_Chase("missile", "missile", CHF_DONTMOVE);
		SPID # 0 A_Jump(48, "roam");
		loop;
	missile:
		SPID # 0{
			A_StartSound("spider / walk", CHAN_BODY);
			shotcount = 0;
		}
		SPID # 0 A_JumpIfTargetInLOS("aim", 10);
		SPID # 0 A_Recoil(-1);
		SPID AA 2 A_FaceTarget(18, 40);
		SPID # 0 A_Recoil(-1);
		SPID BB 2 A_FaceTarget(18, 40);
		SPID # 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID # 0 A_Recoil(-1);
		SPID CC 2 A_FaceTarget(18, 40);
		SPID # 0 A_JumpIfTargetInLOS("aim", 10);
		SPID # 0 A_Recoil(-1);
		SPID DD 2 A_FaceTarget(18, 40);
		SPID # 0 A_JumpIfTargetInLOS("aim", 10);
		SPID # 0 A_StartSound("spider / walk", CHAN_BODY);
		SPID # 0 A_Recoil(-1);
		SPID EE 2 A_FaceTarget(18, 40);
		SPID # 0 A_JumpIfTargetInLOS("aim", 10);
		SPID # 0 A_Recoil(-1);
		SPID FF 2 A_FaceTarget(18, 40);
		SPID # 0 A_JumpIfTargetInLOS("missile", 10);
		---- A 0 setstatelabel("see");
	aim:
		SPID # 4{
			shotcount = 0;
			shotchannel = 4;
			frame = randompick(2, 5);
			A_Recoil(-1);
		}
		SPID # 4{
			A_FaceTarget(8, 8);
			A_Recoil(2);
			double dist = target?distance3d(target):1000;
			A_SetTics(clamp(int(dist * 0.002), 4, 16));
			spread = 22./max(dist * 0.012, 1);
			pitch -= dist * 0.00002;
			shotcount = 0;
		}
	shoot:
		SPID GHGHGH 2 bright light("SPIDF"){
			A_StartSound("weapons / bigrifle", CHAN_WEAPON, CHANF_OVERLAP);
			HDBulletActor.FireBullet(self, "HDB_776", zofs:32, spread:1.);
		}
		SPID G 0 A_Jumpif (shotcount > 50, "stopshot");
		SPID # 0 A_JumpIfTargetInLOS("stopshot", 20);
		goto guard;
	stopshot:
		SPID G 0 A_Jump(220, "shoot");
		SPID # 10{
			frame = randompick(2, 5);
			A_Recoil(-1);
		}---- A 0 setstatelabel("see");
	guard:
		SPID # 1 A_JumpIfTargetInLOS("shoot", 20);
		SPID # 1 A_JumpIfTargetInLOS("missile");
		SPID # 1 A_Jump(12, "see");
		SPID # 0 A_JumpIfTargetInLOS("shoot", 20);
		SPID # 1 A_SetAngle(angle + random(-4, 4));
		SPID # 1 A_Jump(28, "shoot");
		SPID # 0 A_JumpIfTargetInLOS("shoot", 20);
		loop;
	pain:
		SPID I 4;
		SPID I 4 A_Pain();
		goto missile;
	death:
		SPID J 2{
			bnodropoff = false;
			A_HDBossScream();
		}
		SPID JJ 4 A_SpawnItemEx("HDSmokeChunk", frandom(-10, 10), frandom(-10, 10), frandom(38, 50), vel.x + frandom(-6, 6), vel.y + frandom(-6, 6), vel.z + frandom(3, 12), 0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);

		SPID AA 0 A_SpawnItemEx("HDSmokeChunk", frandom(-10, 10), frandom(-10, 10), frandom(38, 50), vel.x + frandom(-6, 6), vel.y + frandom(-6, 6), vel.z + frandom(3, 12), 0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);

		SPID JJJJJJJ 2 A_SpawnItemEx("HDSmoke", frandom(-36, 36), frandom(-36, 36), frandom(24, 80), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID K 0 bright A_SpawnItemEx("HDExplosion", frandom(-34, 34), frandom(-34, 34), frandom(12, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID KKKK 2 A_SpawnItemEx("HDSmoke", frandom(-36, 36), frandom(-36, 36), frandom(24, 80), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID K 0 bright A_SpawnItemEx("HDExplosion", frandom(-34, 34), frandom(-34, 34), frandom(12, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID K 2 A_SpawnItemEx("HDSmoke", frandom(-36, 36), frandom(-36, 36), frandom(24, 80), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID L 0 A_NoBlocking();
		SPID LLLL 2 A_SpawnItemEx("HDSmoke", frandom(-36, 36), frandom(-36, 36), frandom(24, 80), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID L 0 bright A_SpawnItemEx("HDExplosionBoss", frandom(-24, 24), frandom(-24, 24), frandom(24, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID L 2 A_SpawnItemEx("HDExplosion", frandom(-36, 36), frandom(-36, 36), frandom(12, 24), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID M 3 bright A_SpawnItemEx("HDExplosionBoss", frandom(-46, 46), frandom(-46, 46), frandom(24, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID M 2 bright A_SpawnItemEx("HDExplosion", frandom(-36, 36), frandom(-36, 36), frandom(12, 24), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID M 5 bright A_SpawnItemEx("HDExplosionBoss", frandom(-46, 46), frandom(-46, 46), frandom(24, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID AAA 0 A_SpawnItemEx("HDSmokeChunk", frandom(-10, 10), frandom(-10, 10), frandom(38, 50), vel.x + frandom(-6, 6), vel.y + frandom(-6, 6), vel.z + frandom(3, 12), 0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);

		SPID M 5 bright A_SpawnItemEx("HDExplosion", frandom(-46, 46), frandom(-46, 46), frandom(24, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

//REPLACE THIS
		SPID M 2{
			A_Explode(512, 16);
			DistantQuaker.Quake(self, 7, 120, 4096, 7, 400, 666, 256);
		}

		SPID AAA 0 A_SpawnItemEx("CyberGibs", frandom(-10, 10), frandom(-10, 10), frandom(38, 50), vel.x + frandom(-6, 6), vel.y + frandom(-6, 6), vel.z + frandom(1, 8), 0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);

		SPID N 3 bright A_SpawnItemEx("HDExplosion", frandom(-46, 46), frandom(-46, 46), frandom(24, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID N 4 bright A_SpawnItemEx("HDExplosionBoss", frandom(-46, 46), frandom(-46, 46), frandom(24, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID N 3 bright A_SpawnItemEx("HDExplosion", frandom(-46, 46), frandom(-46, 46), frandom(24, 40), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID AA 0 A_SpawnItemEx("CyberGibs", frandom(-10, 10), frandom(-10, 10), frandom(38, 50), vel.x + frandom(-6, 6), vel.y + frandom(-6, 6), vel.z + frandom(1, 8), 0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);

		SPID AAA 0 A_SpawnItemEx("HDSmokeChunk", frandom(-10, 10), frandom(-10, 10), frandom(38, 50), vel.x + frandom(-6, 6), vel.y + frandom(-6, 6), vel.z + frandom(1, 12), 0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);

		SPID O 3 bright A_SpawnItemEx("HDExplosionBoss", frandom(-46, 46), frandom(-46, 46), frandom(20, 36), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID AAAA 0 A_SpawnItemEx("HDSmokeChunk", frandom(-10, 10), frandom(-10, 10), frandom(38, 50), vel.x + frandom(-6, 6), vel.y + frandom(-6, 6), vel.z + frandom(1, 12), 0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);

		SPID O 3 bright A_SpawnItemEx("HDExplosion", frandom(-56, 56), frandom(-56, 56), frandom(20, 36), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID O 4 bright A_SpawnItemEx("HDExplosionBoss", frandom(-56, 56), frandom(-56, 56), frandom(20, 36), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));

		SPID PPQQR 4 bright A_SpawnItemEx("HDSmoke", frandom(-56, 56), frandom(-56, 56), frandom(12, 14), frandom(-1, 1), frandom(-1, 1), frandom(1, 3));
		SPID R 0{
			a_spawnitemex("SpiderRemains", flags:SXF_NOCHECKPOSITION|SXF_SETMASTER);
			bnofear = false;
		}
		SPID SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS 5 A_SpawnItemEx("HDSmoke", frandom(-66, 66), frandom(-56, 56), frandom(12, 14), frandom(-1, 1), frandom(-1, 1), frandom(1, 3), frandom(0, 255));
		SPID S 200;
		SPID S -1 A_BossDeath();
		stop;

	//When as yet there was none of them.
	death.telefrag:
		TNT1 A 100{
			bnofear = false;
			A_Pain();
			A_NoBlocking();
			A_SpawnItemEx("TeleFog", flags:SXF_NOCHECKPOSITION);
		}
		TNT1 A 200 A_Scream();
		TNT1 A 0 A_BossDeath();
		stop;
	}
}
class SpiderRemains:CyberRemains{
	states{
	spawn:
		SPID R 0;
	death:
		SPID S 4;
	spawn2:
		---- AA 1 A_SpawnItemEx("HDSmoke", 
			frandom(-30, 30), frandom(-30, 30), frandom(12, 14), 
			frandom(-1, 1), frandom(-1, 1), 0, 
			0, SXF_NOCHECKPOSITION
		);
		---- A 0 A_StartSound("misc / firecrkl", CHAN_AUTO, volume:1.0-(smokelag * 0.005));
		---- AAA 0 A_SpawnItemEx("HDFlameRed", 
			frandom(-66, 66), frandom(-56, 56), frandom(12, 14), 
			frandom(-1, 1), frandom(-1, 1), frandom(0, 2), 
			0, SXF_NOCHECKPOSITION
		);
		---- A 0 A_SpawnItemEx("HDSmokeChunk", 
			frandom(-30, 30), frandom(-30, 30), frandom(4, 12), 
			frandom(-3, 3), frandom(-3, 3), frandom(1, 4), 
			0, SXF_NOCHECKPOSITION, 160 + smokelag
		);
		---- AAA 0 A_SpawnItemEx("HugeWallChunk", 
			frandom(-30, 30), frandom(-30, 30), frandom(4, 12), 
			frandom(-6, 6), frandom(-6, 6), frandom(1, 4), 
			0, SXF_NOCHECKPOSITION, 64 + smokelag / 2
		);
		---- A 0{
			A_SetTics(random(1, smokelag / 7));
			smokelag++;
			if (alpha > 0.2)alpha -= 0.04;
			else A_FadeOut(0.001);
		}
		loop;
	}
}

