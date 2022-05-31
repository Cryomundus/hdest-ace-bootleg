// ------------------------------------------------------------
// Gyro - Grenades and H.E.A.T.
// ------------------------------------------------------------
extend class HDWeapon{
	int airburst;
	action void A_FireHDGL(){
		A_StartSound("weapons / grenadeshot", CHAN_WEAPON, CHANF_OVERLAP);
		let ggg = gyrogrenade(spawn("GyroGrenade", pos+(
				0, 0, HDWeapon.GetShootOffset(
					self, invoker.barrellength, 
					invoker.barrellength - HDCONST_SHOULDERTORADIUS
				)-2
			), 
			ALLOW_REPLACE)
		);
		ggg.angle = angle;ggg.pitch = pitch - 2;ggg.target = self;ggg.master = self;
		ggg.primed = false;
		if (invoker.airburst){
			ggg.airburst = max(1000, invoker.airburst)*HDCONST_ONEMETRE * 0.01;
			if (!player||!(player.cmd.buttons&BT_ZOOM))invoker.airburst = 0;
		}
	}
	action void A_AirburstReady(){
		A_WeaponReady(WRF_NONE);
		int iab = invoker.airburst;
		int cab = 0;
		int mmy = GetMouseY(true);
		if (justpressed(BT_ATTACK))cab=-100;
		else if (justpressed(BT_ALTATTACK))cab = 100;
		else if (mmy){
			cab=-mmy;
			if (abs(cab)>(1 << 1))cab>>=1;else cab = clamp(cab, -1, 1);
		}
		iab += cab;
		if (iab < 1000){
			if (cab > 0)iab = 1000;
			else iab = 0;
		}
		invoker.airburst = clamp(iab, 0, 99900);
	}
	ui void DrawRifleGrenadeStatus(hdstatusbar sb, hdweapon hdw){
		int ab = hdw.airburst;
		sb.drawstring(
			sb.mAmountFont, ab?string.format("%.2f", ab * 0.01):"--.--", 
			(-30, -25), sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT, 
			ab?Font.CR_WHITE:Font.CR_BLACK
		);
		sb.drawrect(-34, -43 + min(16, ab >> 9), 4, 1);
		sb.drawrect(-31, -42, 1, 16);
		sb.drawrect(-33, -42, 1, 16);
	}
	states{
	abadjust:
		---- A 1 A_AirburstReady();
		---- A 0 A_Jumpif (pressingfiremode(), "abadjust");
		goto readyend;
	}
}
extend class HDHandlers{
	void SetAirburst(HDPlayerPawn ppp, int abi){
		abi = max(abi > 0?10:0, abi);
		let www = hdweapon(ppp.player.readyweapon);
		if (www){
			www.airburst = abi * 100;
			ppp.A_Log(string.format("Airburst set to %.2f metres", abi), true);
		}
		return;
	}
}
class GyroGrenade:SlowProjectile{
	bool isrocket;
	default{
		-noextremedeath -noteleport +bloodlessimpact
		height 2; radius 2; scale 0.33;
		speed HDCONST_MPSTODUPT * 76;
		mass 600; accuracy 0; woundhealth 0;
		obituary "%o was fragged by %k.";
		stamina 5; //used for fuel
	}
	override void postbeginplay(){
		super.postbeginplay();
		if (isrocket)speed *= 2;
		A_ChangeVelocity(speed * cos(pitch), 0, speed * sin(-pitch), CVF_RELATIVE);
	}
	override void ExplodeSlowMissile(line blockingline, actor blockingobject){
		if (max(abs(skypos.x), abs(skypos.y))>=32768){destroy();return;}
		bmissile = false;

		//bounce
		if (!primed&&random(0, 20)){
			if (speed > 50)painsound="misc / punch";else painsound="misc / fragknock";
			actor a = spawn("IdleDummy", pos, ALLOW_REPLACE);
			a.stamina = 10;a.A_StartSound(painsound, CHAN_AUTO);
			[bmissileevenmore, a]=A_SpawnItemEx("DudRocket", 0, 0, 0, 
				random(30, 60), random(-10, 10), random(-10, 10), 
				random(0, 360), SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS, 0
			);
			dudrocket(a).isrocket = isrocket;
			destroy();
			return;
		}

		//damage
		//NOTE: basic impact damage calculation is ALREADY in base SlowProjectile!
		if (blockingobject){
			int dmgg = random(32, 128);
			if (primed&&isrocket){
				double dangle = absangle(angle, angleto(blockingobject));
				if (dangle < 20){
					dmgg += random(200, 600);
					if (hd_debug)A_Log("CRIT!");
				}else if (dangle < 40)dmgg += random(100, 400);
			}
			blockingobject.damagemobj(self, target, dmgg, "Piercing");
		}else doordestroyer.destroydoor(self, maxdepth:isrocket?7:frandom(4, 6));

		//explosion
		if (!inthesky){
			A_SprayDecal("Scorch", 16);
			A_HDBlast(
				pushradius:256, pushamount:128, fullpushradius:96, 
				fragradius:HDCONST_ONEMETRE*(10 + 0.2 * stamina), fragtype:"HDB_frag", 
				immolateradius:128, immolateamount:random(3, 60), 
				immolatechance:isrocket?random(1, stamina):25
			);
			actor xpl = spawn("Gyrosploder", pos-(0, 0, 1), ALLOW_REPLACE);
			xpl.target = target;xpl.master = master;xpl.stamina = stamina;
		}else{
			distantnoise.make(self, "world / rocketfar");
		}
		A_SpawnChunksFrags("HDB_frag", 180, 0.8 + 0.05 * stamina);
		destroy();return;
	}
	states{
	spawn:
		ROCQ A 0;
	spawn1:
		#### B 1;
		#### A 0{
			if (isrocket)setstatelabel("spawnrocket");
		}
	spawngrenade:
		#### AB 1;
		#### A 0{primed = true;}
	spawngrenadefinal:
		#### AB 1;
		loop;
	spawnrocket:
		---- A 0{
			primed = true;
			if (!inthesky){
				brockettrail = true;
				Gunsmoke();
				A_StartSound("weapons / rocklaunch", CHAN_VOICE);
			}
		}
		---- AAA 0{
			actor sss = spawn("HDGunSmoke", pos - vel * 0.1+(0, 0, -4), ALLOW_REPLACE);
			sss.vel = vel*-0.06+(frandom(-2, 2), frandom(-2, 2), frandom(-2, 2));
		}
	spawnrocket2:
		#### BA 1{
			if (self is "HDHEAT")frame = 0;
			if (stamina > 0){  
				if (!inthesky){
					brockettrail = true;
					actor sss = spawn("HDGunsmoke", pos, ALLOW_REPLACE);
					sss.vel = vel * 0.1;
				}else{
					brockettrail = false;
					bgrenadetrail = false;
				}
				A_ChangeVelocity(
					cos(pitch)*60, 0, 
					sin(-pitch)*60 + 1, CVF_RELATIVE
				);
				stamina--;
			}
		}
		---- A 0{
			if (primed){
				if (!inthesky)A_StartSound("weapons / rocklaunch", 5);
			}else{
				primed = true;
				brockettrail = false;
				if (!inthesky)bgrenadetrail = true;
			}
		}loop;
	death:
		TNT1 A 1;
		stop;
	}
}
class HDHEAT:GyroGrenade{
	default{
		+forcepain
		scale 0.37; woundhealth 1800;
		decal "BrontoScorch";
	}
	override void ExplodeSlowMissile(line blockingline, actor blockingobject){
		if (max(abs(skypos.x), abs(skypos.y))>=32768){destroy();return;}
		bmissile = false;
		//bounce
		//nothing here - HEAT will always explode

		//explosion
		A_SpawnChunksFrags("HDB_fragRL", 180);
		if (!inthesky){
			A_HDBlast(
				pushradius:256, pushamount:96, fullpushradius:72, 
				fragradius:HDCONST_ONEMETRE * 10, fragtype:"HDB_fragRL", 
				immolateradius:96, immolateamount:random(1, 40), 
				immolatechance:random(1, stamina)
			);
			actor xpl = spawn("Gyrosploder", self.pos-(0, 0, 1), ALLOW_REPLACE);
			xpl.target = target;xpl.master = master;xpl.stamina = stamina;

			//damage
			HEATShot(self, 128);

			A_SprayDecal("BrontoScorch", 16);

		}else distantnoise.make(self, "world / rocketfar");

		destroy();return;
	}
	states{
	spawn:
		MISL A 0 nodelay{
			primed = true;
			if (Wads.CheckNumForName("id", 0)!=-1){scale.x = 0.24;scale.y = 0.24;}
		}
		goto spawnrocket;
	}
	static void HEATShot(actor caller, double squirtamt){
		vector3 originalpos = caller.pos;

		//do a series of linetracers to drill through everything
		caller.A_SprayDecal("BigScorch", squirtamt);
		array < actor > hitactors;hitactors.clear();
		flinetracedata sqtrace;
		do{
			caller.linetrace(
				caller.angle, 
				squirtamt, 
				caller.pitch, 
				data:sqtrace
			);

			caller.setorigin(sqtrace.hitlocation - sqtrace.hitdir, false);
			if (sqtrace.hitactor){
				int dmgg = int(frandom(70, 240 + squirtamt));
				int dangle = int(absangle(caller.angle, caller.angleto(sqtrace.hitactor)));
				bool crapshot = dangle > 40;
				if (dangle < 20){
					dmgg += int((180 - dangle)*squirtamt * frandom(0.4, 0.45));
					if (hd_debug)console.printf("CRIT!");
				}else if (!crapshot)dmgg += int(frandom(100, 400 - dangle + squirtamt * 2));
				int originalhealth = sqtrace.hitactor.health;
				sqtrace.hitactor.damagemobj(
					caller, caller.target, dmgg, crapshot?"Slashing":"Piercing", 
					crapshot?0:DMG_NO_ARMOR
				);
				int fdmg = 0;
				if (sqtrace.hitactor){
					fdmg = originalhealth - sqtrace.hitactor.health;
					if (
						sqtrace.hitactor.health > 0
						&&(fdmg << 3)<sqtrace.hitactor.spawnhealth()
					)break;
					else{
						hitactors.push(sqtrace.hitactor);
						sqtrace.hitactor.bnonshootable = true;
					}
				}
				squirtamt -= max(8, fdmg >> 6);
			}else{
				doordestroyer.destroydoor(caller, maxwidth:squirtamt * frandom(1.3, 1.6), dedicated:true);
				squirtamt -= max(16, sqtrace.distance);
			}
		}while(squirtamt > 0);
		for(int i = 0;i < hitactors.size();i++){
			if (hitactors[i])hitactors[i].bnonshootable = false;
		}
		vector3 finalpos = caller.pos;
		caller.setorigin(originalpos, false);

		if (finalpos != originalpos){
			int iii = int((finalpos - originalpos).length());
			vector3 trailpos=(0, 0, 0);
			vector3 vu = caller.vel.unit();
			vector3 vu2 = vu * 4;
			for(int i = 0;i < iii;i++){
				trailpos += vu;
				caller.A_SpawnParticle(
					"white", 
					SPF_FULLBRIGHT, 
					5, 
					frandom(0.04, 0.07)*(iii - i * 0.5), 
					caller.angle, 
					trailpos.x + frandom(-12, 12), trailpos.y + frandom(-12, 12), trailpos.z + frandom(-12, 12), 
					vu2.x, vu2.y, vu2.z, 
					0, 0, 0.6, 
					sizestep:4
				);
			}
		}
	}
}

class Gyrosploder:HDActor{
	int ud;
	default{
		+noblockmap +missile +nodamagethrust
		gravity 0;height 6;radius 6;
		damagefactor(0);
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_ChangeVelocity(1, 0, 0, CVF_RELATIVE);
		distantnoise.make(self, "world / rocketfar");
	}
	states{
	death:
		TNT1 A 0{
			if (ceilingz - pos.z<(pos.z - floorz)*3) ud=-5;
			else ud = 5;
		}
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("HugeWallChunk", -1, 0, ud, 
			frandom(-7, 7), frandom(-7, 7), ud * frandom(1, 3), 
			frandom(0, 360), SXF_NOCHECKPOSITION
		);
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk", -1, 0, ud, 
			frandom(-1, 6), frandom(-4, 4), ud * frandom(1, 4), 
			frandom(0, 360), SXF_NOCHECKPOSITION
		);
		TNT1 AA 0 A_SpawnItemEx("HDSmoke", -1, 0, ud, 
			frandom(-2, 2), frandom(-2, 2), 0, 
			frandom(-15, 15), SXF_NOCHECKPOSITION
		);
	xdeath:
	spawn:
		TNT1 A 0 nodelay;
		TNT1 AA 0 A_SpawnItemEx("HDExplosion", 
			random(-1, 1), random(-1, 1), 2, 0, 0, 0, 
			0, SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		TNT1 A 2 A_SpawnItemEx("HDExplosion", 0, 0, 0, 
			0, 0, 2, 
			0, SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		TNT1 AAAAAAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk", 0, 0, 1, 
			random(-1, 6), random(-4, 4), random(4, 18), 
			random(-15, 15), SXF_NOCHECKPOSITION
		);
	death2:
		TNT1 AA 0 A_SpawnItemEx("HDSmoke", -1, 0, 1, 
			random(-2, 3), random(-2, 2), 0, 
			random(-15, 15), SXF_NOCHECKPOSITION
		);
		TNT1 A 21{
			A_AlertMonsters();
			DistantQuaker.Quake(self, 4, 35, 512, 10);
		}stop;
	}
}





class HDRocketAmmo:HDAmmo replaces RocketAmmo{
	default{
		//$Category "Ammo / Hideous Destructor/"
		//$Title "Rocket Grenade"
		//$Sprite "ROQPA0"

		inventory.pickupmessage "Picked up a rocket grenade.";
		scale 0.33;
		tag "rocket grenade";
		hdpickup.refid HDLD_ROCKETS;
		hdpickup.bulk ENC_ROCKET;
		inventory.maxamount (60 + 40); //never forget
		inventory.icon "ROQPA0";
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDRL");
		itemsthatusethis.push("Blooper");
		itemsthatusethis.push("HDIEDKit");
	}
	override bool IsUsed(){
		if (!owner)return true;
		for(int i = 0;i < itemsthatusethis.size();i++){
			if (owner.CountInv(itemsthatusethis[i]))return true;
		}
		let zzz = HDWeapon(owner.FindInventory("ZM66AssaultRifle"));
		if (zzz&&!(zzz.weaponstatus[0]&ZM66F_NOLAUNCHER))return true;
		let lll = HDWeapon(owner.FindInventory("LiberatorRifle"));
		if (lll&&!(lll.weaponstatus[0]&LIBF_NOLAUNCHER))return true;
		return false;
	}
	states{
	spawn:
		ROQP A -1;
		stop;
	}
}
class HEATAmmo:HDAmmo{
	default{
		//$Category "Ammo / Hideous Destructor/"
		//$Title "H.E.A.T. Rocket"
		//$Sprite "ROCKA0"

		+inventory.ignoreskill
		inventory.maxamount (60 + 40); //never forget
		inventory.pickupmessage "Picked up a H.E.A.T. round.";
		tag "H.E.A.T. rocket";
		hdpickup.refid HDLD_HEATRKT;
		hdpickup.bulk ENC_HEATROCKET;
		xscale 0.24;
		yscale 0.3;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDRL");
	}
	states{
	spawn:
		ROCK A -1;
		stop;
	}
}
class DudRocketAmmo:HDAmmo{
	default{
		+hdpickup.cheatnogive
		inventory.pickupmessage "picked up a defused rocket grenade.";
		inventory.Amount 1;
		inventory.maxamount (60 + 40); //never forget
		radius 2;height 2;
		scale 0.33;
		tag "dud rocket";
		hdpickup.bulk ENC_ROCKET;
		inventory.icon "ROCQA7A3";
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDIEDKit");
	}
	states{
	spawn:
		ROCQ A -1;stop;
	}
}
class DudRocket:HDUPK{
	bool isrocket;
	default{
		projectile; -nogravity -noteleport +bounceonactors
		-noblockmap -grenadetrail -floorclip +forcexybillboard
		+nodamagethrust +noblood
		bouncetype "doom"; decal "none";
		mass 30; pushfactor 3.4; bouncefactor 0.3; gravity 1;
		deathsound "misc / fragknock";
		bouncesound "misc / fragknock";
		wallbouncesound "misc / fragknock";
		obituary "%o was fragged by %k.";
		hdupk.pickupmessage "picked up (and defused) a rocket grenade.";
		damagefactor(0);
		radius 2; height 2; scale 0.33;
	}
	states{
	spawn:
		ROCQ A 0 A_Jump(256, "clean");
		ROCQ AB 2 A_SetAngle(angle + 45);
		loop;
	death:
		ROCQ A 0{
			return; //why did we have these flags anyway?
			bmissile = false;
			bpushable = true;
			bshootable = true;
			bsolid = true;
		}
	dead:
		ROCQ A 0 A_Jump(64, "clean");
		ROCQ A 1 A_SetTics(random(21000, isrocket?random(21000, 100000):100000));
		ROCQ A 0 A_Jump(64, "dead");
		goto explode;
	clean:
		ROCQ A -1;
		stop;
	explode:
		---- A 0{
			A_SprayDecal("Scorch", 16);
			A_HDBlast(
				pushradius:256, pushamount:128, fullpushradius:96, 
				fragradius:HDCONST_ONEMETRE*(10 + 0.2 * stamina), fragtype:"HDB_frag", 
				immolateradius:128, immolateamount:random(3, 60), 
				immolatechance:isrocket?random(1, stamina):25
			);
			actor xpl = spawn("Gyrosploder", pos-(0, 0, 1), ALLOW_REPLACE);
			xpl.target = target;xpl.master = master;xpl.stamina = stamina;
			A_SpawnChunksFrags("HDB_frag", 180, 0.8 + 0.05 * stamina);
		}stop;
	give:
		---- A 0 A_JumpIfInTargetInventory("DudRocketAmmo", 0, 3);
		---- A 0 A_GiveToTarget("DudRocketAmmo", 1);
		---- A 0 A_StartSound("weapons / grenopen", CHAN_BODY);
		stop;
		ROCQ A 0 A_Jump(1, "Explode");
		ROCQ A 0 spawn("DudRocketAmmo", pos, ALLOW_REPLACE);
		stop;
	}
}

