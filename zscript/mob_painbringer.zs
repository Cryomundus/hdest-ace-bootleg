// ------------------------------------------------------------
// Pain Bringer
// ------------------------------------------------------------
class PainBringer:PainMonster replaces HellKnight{
	default{
		height 60;
		radius 14;
		mass 1000;
		painchance 50;
		health 500;
		seesound "knight / sight";
		activesound "knight / active";
		painsound "knight / pain";
		deathsound "knight / death";
		obituary "$ob_knight";
		hitobituary "$ob_knighthit";
		tag "$cc_hell";

		damagefactor "balefire", 0.3;
		damagefactor "hot", 0.8;
		damagefactor "cold", 0.7;
		hdmobbase.shields 500;
		scale 0.9;
		speed 12;
		meleedamage 10;
		meleerange 56;
		minmissilechance 42;

		+hdmobbase.climber
		maxdropoffheight 64;

		stamina 0;
	}

	override double bulletshell(vector3 hitpos, double hitangle){
		return frandom(3, 7);
	}
	override double bulletresistance(double hitangle){
		return max(0, frandom(0.8, 1.)-hitangle * 0.008);
	}

	override void postbeginplay(){
		super.postbeginplay();
		resize(0.9, 1.1);
	}
	double targetingangle;double targetingpitch;
	double targetdistance;

	actor puttopawn;

	states{
	spwander:
		BOS2 ABCDABCD 7 A_HDWander();
		BOS2 A 0{
			if (!random(0, 1))setstatelabel("spwander");
			else A_Recoil(-0.4);
		}//fallthrough to spawn
	spawn:
		BOS2 ABCD 12 A_HDLook();
		BOS2 A 0{
			if (bambush)setstatelabel("spawn");
			else{
				A_SetTics(random(1, 3));
				if (!random(0, 5))A_StartSound("knight / active", CHAN_VOICE);
				if (!random(0, 5))setstatelabel("spwander");
			}
		}loop;
	see:
		BOS2 ABCD 4 A_HDChase();
		loop;
	pain:
		BOS2 H 2;
		BOS2 H 2 A_Pain;
		---- A 0 setstatelabel("see");
	pain.balefire:
		BOS2 H 3{
			A_Recoil(0.4);
			GiveBody(20);
			if (!random(0, 3))A_KillChildren();
		}
		goto pain;
	missile:
		BOS2 ABCD 3{
			A_FaceTarget(30);
			if (A_JumpIfTargetInLOS("null", 10))setstatelabel("shoot");
		}
		BOS2 E 0 A_JumpIfTargetInLOS("shoot", 10);
		BOS2 E 0 A_JumpIfTargetInLOS("missile");
		---- A 0 setstatelabel("see");
	shoot:
		BOS2 E 0{
			if (target)targetdistance = distance3d(target);else targetdistance = 0;
			if (
				!puttopawn
				&&targetdistance > 1024
				&&!random(0, 4)
			){
				setstatelabel("putto");
			}
		}goto fireball;
	putto:
		BOS2 E 6 A_StartSound("knight / sight", CHAN_VOICE);
		BOS2 E 4 A_FaceTarget(10, 10);
		BOS2 E 2;
		BOS2 F 5;
		BOS2 E 3;
		BOS2 H 12{
			actor p = spawn("Putto", pos+(angletovector(angle, 32), 32), ALLOW_REPLACE);
			p.master = self;p.angle = angle;p.pitch = pitch;
			p.A_ChangeVelocity(cos(pitch)*5, 0, -sin(pitch)*5, CVF_RELATIVE);
			p.A_SetFriendly(bfriendly);
			p.target = target;
			puttopawn = p;
			firefatigue += int(HDCONST_MAXFIREFATIGUE * 0.8);
		}
		---- A 0 setstatelabel("see");
	fireball:
		BOS2 FE 3 A_FaceTarget(60, 60);
		BOS2 E 2{
			A_FaceTarget(6, 6);
			targetingangle = angle;targetingpitch = pitch;
		}
		BOS2 E 3{
			A_FaceTarget(6, 6);

			if (target&&targetdistance<(25 * 35 * 7)){
				double adj = targetdistance * frandom(0.008, 0.032);
				angle += deltaangle(targetingangle, angle)*adj;
				if (target.bfloat)pitch += deltaangle(targetingpitch, pitch)*adj;
				else pitch += clamp(deltaangle(targetingpitch, pitch)*adj, -10, 10);
			}else{
				angle += frandom(-4., 4.);
				pitch += frandom(-0.1, 0.1);
			}
		}
		BOS2 F 1;
		BOS2 G 4{
			actor aaa;int bbb;
			[bbb, aaa]=A_SpawnItemEx("BaleBall", 
				0, 0, 32, 
				cos(pitch)*25, 0, -sin(pitch)*25
			);
			aaa.vel += vel;aaa.tracer = target;
		}
		BOS2 GF 5;
		BOS2 A 0 A_Jumpif (firefatigue > HDCONST_MAXFIREFATIGUE * 1.6, "pain");
		BOS2 A 0 A_Jump(128, "missile");
		---- A 0 setstatelabel("see");
	melee:
		BOS2 E 6 A_FaceTarget();
		BOS2 F 2;
		BOS2 G 6{
			A_CustomMeleeAttack(random(20, 100), "baron / melee", "", "claws", true);
			if (!random(0, 3))return;
			actor aaa;int bbb;
			[bbb, aaa]=A_SpawnItemEx("BaleBall", 
				0, 0, 48, 
				8, 0, -12
			);
			aaa.vel += vel;
		}
		BOS2 F 5;
		---- A 0 setstatelabel("see");
	death:
		BOS2 I 8;
		BOS2 J 8 A_Scream();
		BOS2 KLMN 8;
		BOS2 O -1 A_BossDeath();
		stop;
	death.maxhpdrain:
		BOS2 H 5 A_StartSound("misc / gibbed", CHAN_BODY);
		BOS2 HIJKLMN 5;
		BOS2 O -1;
		stop;
	raise:
		BOS2 ONMLKJI 5;
		BOS2 H 8 A_StartSound("knight / sight", CHAN_VOICE);
		goto see;
	}
}




