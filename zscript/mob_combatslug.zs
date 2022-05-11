// ------------------------------------------------------------
// Mancu, mancu very much.
// ------------------------------------------------------------
class manjuicelight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=164;
		args[1]=66;
		args[2]=18;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-20,4);
			if(args[3]<1)destroy();
		}else{
			setorigin(target.pos,true);
			if(target.bmissile)args[3]=random(28,44);
			else args[3]=random(32,64);
		}
	}
}
const CSLUG_BALLSPEED=56.;
class manjuicesmoke:HDFireballTail{
	default{
		deathheight 0.9;
		gravity 0;
	}
	states{
	spawn:
		RSMK A random(3,5);RSMK A 0 A_SetScale(scale.y*2);
		---- BCD -1{frame=random(1,3);}wait;
	}
}
class manjuice:hdfireball{
	default{
		missiletype "manjuicesmoke";
		missileheight 8;
		damagetype "hot";
		activesound "misc/firecrkl";
		decal "scorch";
		gravity HDCONST_GRAVITY*0.8;
		speed CSLUG_BALLSPEED;
		radius 7;
		height 8;
		hdfireball.firefatigue HDCONST_MAXFIREFATIGUE*0.2;
	}
	actor trailburner;
	override void ondestroy(){
		if(trailburner)trailburner.destroy();
		super.ondestroy();
	}
	states{
	spawn:
		MANF A 0 nodelay{
			actor mjl=spawn("manjuicelight",pos+(0,0,16),ALLOW_REPLACE);
			mjl.target=self;
		}
		MANF ABAB 2 A_FBTail();
	spawn2:
		MANF A 2 A_FBFloat();
		MANF B 2;
		loop;
	death:
		MISL B 0{
			vel.z+=1.;
			A_HDBlast(
				128,66,16,"hot",
				immolateradius:48,random(20,90),42,
				false
			);
			A_SpawnChunks("HDSmokeChunk",random(2,4),6,20);
			A_StartSound("misc/fwoosh",CHAN_WEAPON);
			scale=(0.9*randompick(-1,1),0.9);
		}
		MISL BBBB 1{
			vel.z+=0.5;
			scale*=1.05;
		}
		MISL CCCDDD 1{
			alpha-=0.15;
			scale*=1.01;
		}
		TNT1 A 0{
			A_Immolate(tracer,target,80,requireSight:true);
			addz(-20);
		}
		TNT1 AAAAAAAAAAAAAAA 4{
			if(tracer){
				setorigin((tracer.pos.xy,tracer.pos.z+frandom(0.1,tracer.height*0.4)),false);
				vel=tracer.vel;
			}
			A_SpawnItemEx("HDSmoke",
				frandom(-2,2),frandom(-2,2),frandom(0,2),
				vel.x+frandom(2,-4),vel.y+frandom(-2,2),vel.z+frandom(1,4),
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
		}stop;
	}
}

class CombatSlug:HDMobBase replaces Fatso{
	default{
		health 600;
		mass 1000;
		speed 8;
		monster;
		+floorclip
		+bossdeath
		seesound "fatso/sight";
		painsound "fatso/pain";
		deathsound "fatso/death";
		activesound "fatso/active";
		tag "$cc_mancu";

		+dontharmspecies
		deathheight 20;
		radius 28;
		height 60;

		meleerange 64;
		meleethreshold 128;

		damagefactor "hot", 0.7;
		damagefactor "cold", 0.8;
		hdmobbase.shields 500;
		obituary "%o was smoked by a $TAG.";
		painchance 80;
	}
	vector2 firsttargetaim;
	vector2 secondtargetaim;
	vector2 leadoffset;
	double targdist;
	override bool CanDoMissile(
		bool targsight,
		double targdist,
		out statelabel missilestate
	){
		return
		(
			targdist<(HDCONST_ONEMETRE*100)
			||!target
			||target.pos.z-pos.z<128
		)&&super.CanDoMissile(targsight,targdist,missilestate);
	}
	states{
	spawn:
		FATT AB 15 A_HDLook();
		loop;
	see:
		FATT ABCDEF 6 A_HDChase();
		loop;
	missile:
		FATT ABCD 3{
			A_FaceTarget(30,30);
			if(A_JumpIfTargetInLOS("null",10))setstatelabel("raiseshoot");
		}
		FATT E 0 A_JumpIfTargetInLOS("raiseshoot",30);
		FATT E 0 A_JumpIfTargetInLOS("missile");
		---- A 0 setstatelabel("see");
	raiseshoot:
		FATT G 4{
			A_StartSound("fatso/raiseguns",CHAN_VOICE);
			A_FaceTarget(40,40);
		}
		FATT G 4 A_FaceTarget(20,20);
		FATT GGGG 1 A_SpawnItemEx("HDSmoke",
			16,randompick(24,-24),bplayingid?18:40,
			random(2,4),flags:SXF_NOCHECKPOSITION
		);
	shoot:
		FATT G 2{
			A_FaceTarget(10,10);
			A_SpawnItemEx("HDSmoke",
				16,randompick(24,-24),bplayingid?18:40,
				random(2,4),flags:SXF_NOCHECKPOSITION
			);
			if(!hdmobai.TryShoot(self,24,128,48,32))setstatelabel("see");
		}
		FATT G 1{
			vector2 aimbak=(angle,pitch);
			A_FaceTarget(0,0);
			firsttargetaim=(angle,pitch);
			angle=aimbak.x;pitch=aimbak.y;
		}
		FATT G 2{
			vector2 aimbak=(angle,pitch);
			A_FaceTarget(0,0);
			secondtargetaim=(angle,pitch);
			angle=aimbak.x;pitch=aimbak.y;

			targdist=(target?max(1.,distance3d(target)):4096);

			if(targdist>2000)leadoffset=(frandom(-2.,2),frandom(-1.,1.));
			else leadoffset=(
				deltaangle(firsttargetaim.x,secondtargetaim.x),
				deltaangle(firsttargetaim.y,secondtargetaim.y)
			)*targdist*frandom(0.021,0.070);

			angle+=leadoffset.x;pitch+=leadoffset.y;
		}
		FATT H 10 bright{
			A_StartSound("weapons/bronto",CHAN_WEAPON);

			hdmobai.DropAdjust(self,"ManJuice");

			//lead target
			actor ppp;int bluh;
			[bluh,ppp]=A_SpawnItemEx(
				"manjuice",0,24,32,
				cos(pitch)*CSLUG_BALLSPEED,0,-sin(pitch)*CSLUG_BALLSPEED,
				atan(24/targdist),
				flags:SXF_NOCHECKPOSITION|SXF_SETTARGET|SXF_TRANSFERPITCH
			);

			//random
			int opt=random(0,2);
			if(opt==1){
				leadoffset*=frandom(-2.,0.2);
				angle+=leadoffset.x;
				pitch+=leadoffset.y;
			}else if(opt==2){
				angle+=frandom(-10,10)/targdist;
				pitch+=frandom(-1,1);
			}
			[bluh,ppp]=A_SpawnItemEx(
				"manjuice",0,-24,32,
				cos(pitch)*CSLUG_BALLSPEED,0,-sin(pitch)*CSLUG_BALLSPEED,
				-atan(24/targdist),
				flags:SXF_NOCHECKPOSITION|SXF_SETTARGET|SXF_TRANSFERPITCH
			);
		}
		FATT G 6;
		FATT G 10{
			if(
				accuracy<2
				&&(!random(0,4-(!!target&&target.health>0)))
			){
				accuracy++;
				setstatelabel("shoot");
			}else accuracy=0;
		}
		---- A 0 setstatelabel("see");

	melee:
		FATT D 3 A_FaceTarget(0,0);
		FATT E 2;
		FATT G 3 A_CustomMeleeAttack(random(1,40),"weapons/smack","","bashing",true);
		FATT H 1 bright;
		FATT H 2 bright{
			A_StartSound("mancubus/thrust",CHAN_WEAPON,CHANF_OVERLAP);
			actor iii;
			blockthingsiterator iiii=blockthingsiterator.create(self,meleerange);
			while(iiii.next()){
				iii=iiii.thing;
				double angoffset=absangle(angle,angleto(iii));
				if(
					iii.bshootable
					&&!iii.bdontthrust
					&&iii.mass>0
					&&angoffset<30
				){
					A_Immolate(iii,self,20);
					vector3 thr=iii.pos-pos;
					thr*=(40-(angoffset))/iii.mass;
					iii.vel+=thr;
				}
			}
		}
		FATT GFED 3;
		FATT A 0 setstatelabel("see");

	pain:
		FATT J 3;
		FATT J 3 A_Pain;
		---- A 0 setstatelabel("see");
	death:
		FATT K 6 A_SpawnItemEx("HDExplosion",0,0,36,flags:SXF_SETTARGET);
		FATT L 6 A_Scream();
		FATT MNOPQRS 6 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(26,32),
			0,0,frandom(1,4),
			0,SXF_NOCHECKPOSITION
		);
		FATT TTT 8 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(26,32),
			0,0,frandom(1,4),
			0,SXF_NOCHECKPOSITION
		);
		FATT T -1{
			A_BossDeath();
			balwaystelefrag=true; //not needed?
			bodydamage+=1200;
		}stop;
	raise:
		FATT ST 14 damagemobj(self,self,1,"maxhpdrain",DMG_NO_PAIN|DMG_FORCED|DMG_NO_FACTOR);
		FATT TSR 10;
		FATT QPONMLK 5;
		---- A 0 setstatelabel("see");
	death.maxhpdrain:
		FATT STST 14 A_SpawnItemEx("MegaBloodSplatter",
			frandom(-1,1),frandom(-1,1),frandom(10,16),
			vel.x,vel.y,vel.z,0,SXF_NOCHECKPOSITION
		);
		FATT T -1;
		stop;
	}
}
