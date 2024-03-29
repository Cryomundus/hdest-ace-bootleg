// ------------------------------------------------------------
// Brontornis Cannon
// ------------------------------------------------------------
class TerrorSabotPiece:HDDebris{
	default{
		xscale 1;yscale 2.2;height 2;radius 2;
		translation "ice";
		bouncesound "misc/casing2";
	}
	states{
	spawn:
		TNT1 A 0 nodelay{
			int blh=random(20,35);
			A_ChangeVelocity(cos(pitch)*blh,frandom(-1,1),-sin(pitch)*blh,CVF_RELATIVE);
		}
	spawn2:
		RBRS A 2{angle+=45;}
		loop;
	death:
		---- A -1;
		stop;
	}
}
class TerrorCasing:HDDebris{
	default{
		scale 0.3;height 4;radius 4;bouncefactor 0.6;
		bouncesound "misc/casing4";
	}
	states{
	spawn:
		BSHX A 0 nodelay A_ChangeVelocity(cos(pitch),0,sin(-pitch)+1,CVF_RELATIVE);
	spawn2:
		BSHX ACBC random(1,3){angle+=45;}
		loop;
	death:
		---- A -1{
			A_FaceMovementDirection();
			angle+=90;
		}
		stop;
	}
}




class BrontornisRound:HDAmmo{
	default{
		+inventory.ignoreskill
		inventory.pickupmessage "Picked up a bolt.";
		tag "Brontornis shell";
		inventory.icon "BROCA0";
		hdpickup.refid HDLD_BROBOLT;
		hdpickup.bulk ENC_BRONTOSHELL;
		scale 0.3;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("Brontornis");
	}
	states{
	spawn:
		BROC A -1;
		stop;
	}
}


class Brontornis:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Brontornis"
		//$Sprite "BLSTA0"

		+hdweapon.fitsinbackpack
		weapon.selectionorder 60;
		weapon.slotnumber 7;
		weapon.slotpriority 2;
		weapon.kickback 100;
		weapon.bobrangex 0.21;
		weapon.bobrangey 0.86;
		scale 0.6;
		inventory.pickupmessage "You got the Brontornis!";
		obituary "%o was terrorized by %k's Brontornis cannon.";
		hdweapon.barrelsize 24,1,2;
		tag "Brontornis cannon";
		hdweapon.refid HDLD_BRONTO;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void tick(){
		super.tick();
		drainheat(BRONS_HEAT,12);
	}
	override void beginplay(){
		super.beginplay();
		weaponstatus[BRONS_DOT]=3;
	}
	override double gunmass(){
		double amt=weaponstatus[BRONS_CHAMBER];
		return 6+amt*amt;
	}
	override double weaponbulk(){
		return 75+(weaponstatus[BRONS_CHAMBER]>1?ENC_BRONTOSHELLLOADED:0);
	}
	override string,double getpickupsprite(){return "BLSTA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("BROCA0",(-48,-10),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.7,0.7));
			sb.drawnum(hpl.countinv("BrontornisRound"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[BRONS_CHAMBER]>1)sb.drawrect(-21,-13,5,3);
		sb.drawwepnum(
			hpl.countinv("BrontornisRound"),
			(HDCONST_MAXPOCKETSPACE/ENC_BRONTOSHELL)
		);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.." or "..WEPHELP_FIREMODE.."  Toggle zoom\n"
		..WEPHELP_RELOADRELOAD
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int scaledyoffset=-4;
		if(scopeview&&hdw.weaponstatus[0]&BRONF_ZOOM){

			double degree=6.;
			int scaledwidth=50;
			int scaledyoffset=scaledwidth>>1;
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(
				bob.x-(scaledwidth>>1),bob.y+scaledyoffset-(scaledwidth>>1),
				scaledwidth,scaledwidth,
				sb.DI_SCREEN_CENTER
			);

			//the new circular view code that doesn't work with LZDoom 3.87c
			sb.fill(color(255,0,0,0),
				bob.x-27,scaledyoffset+bob.y-27,
				54,54,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			texman.setcameratotexture(hpc,"HDXCAM_BRON",degree);
			let cam=texman.CheckForTexture("HDXCAM_BRON",TexMan.Type_Any);
			double camSize=texman.GetSize(cam);
			sb.DrawCircle(cam,(0,scaledyoffset)+ bob*5, .085,usePixelRatio:true);
			
			screen.SetClipRect(cx,cy,cw,ch);

			sb.drawimage(
				"rlret",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(0.82,0.82)
			);
			sb.drawimage(
				"libscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(0.72,0.72)
			);


		}else{
			double dotoff=max(abs(bob.x),abs(bob.y));
			if(dotoff<2.4){
				string whichdot=sb.ChooseReflexReticle(hdw.weaponstatus[BRONS_DOT]);
				sb.drawimage(
					whichdot,(0,0)+bob*3,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.8-dotoff*0.04,scale:(1.2,1.2),
					col:0xFF000000|sb.crosshaircolor.GetInt()
				);
			}
			sb.drawimage(
				"brontorearsight",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1.,1.)
			);
		}
	}
	override void SetReflexReticle(int which){weaponstatus[BRONS_DOT]=which;}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory("BrontornisRound",1);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_SetInventory("BrontornisRound",1);
	}
	states{
	select0:
		BLSG A 0;
		goto select0small;
	deselect0:
		BLSG A 0;
		goto deselect0small;
	ready:
		BLSG A 1 A_WeaponReady(WRF_ALL);
		goto readyend;
	altfire:
	firemode:
		BLSG A 1 offset(0,34);
		BLSG A 1 offset(0,36);
		BLSG A 2 offset(2,37){invoker.weaponstatus[0]^=BRONF_ZOOM;}
		BLSG A 1 offset(1,36);
		BLSG A 1 offset(0,34);
		goto nope;
	fire:
		BLSG A 1 offset(0,34){
			if(invoker.weaponstatus[BRONS_CHAMBER]<2){
				setweaponstate("nope");
				return;
			}
			A_GunFlash();
			A_StartSound("weapons/bronto",CHAN_WEAPON);
			A_StartSound("weapons/bronto",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("weapons/bronto2",CHAN_WEAPON,CHANF_OVERLAP);
			let tb=HDBulletActor.FireBullet(self,"HDB_bronto");
			invoker.weaponstatus[BRONS_CHAMBER]=1;
			invoker.weaponstatus[BRONS_HEAT]+=32;
		}
		BLSG B 2;
		goto nope;
	flash:
		BLSF A 1 bright{
			HDFlashAlpha(0,true);
			A_Light1();

			if(gunbraced())A_GiveInventory("IsMoving",2);
			else A_GiveInventory("IsMoving",7);
			if(!binvulnerable
				&&(
					countinv("IsMoving")>6
					||floorz<pos.z
				)
			){
				givebody(max(0,11-health));
				damagemobj(invoker,self,10,"bashing");
				A_GiveInventory("IsMoving",5);
				A_ChangeVelocity(
					cos(pitch)*-frandom(2,4),0,sin(pitch)*frandom(2,4),
					CVF_RELATIVE
				);
			}
		}
		TNT1 A 2{
			A_ZoomRecoil(0.5);
			A_Light0();
		}
		TNT1 A 0{
			int recoilside=randompick(-1,1);
			if(gunbraced()){
				hdplayerpawn(self).gunbraced=false;
				A_ChangeVelocity(
					cos(pitch)*-frandom(0.8,1.4),0,
					sin(pitch)*frandom(0.8,1.4),
					CVF_RELATIVE
				);
				A_MuzzleClimb(
					recoilside*5,-frandom(3.,5.),
					recoilside*5,-frandom(3.,5.)
				);
			}else{
				A_ChangeVelocity(
					cos(pitch)*-frandom(1.8,3.2),0,
					sin(pitch)*frandom(1.8,3.2),
					CVF_RELATIVE
				);
				A_MuzzleClimb(
					recoilside*5,-frandom(5.,13.),
					recoilside*5,-frandom(5.,13.)
				);
				A_MuzzleClimb(
					recoilside*5,-frandom(5.,13.),
					recoilside*5,-frandom(5.,13.),
					wepdot:true
				);
			}
		}
		stop;
	reload:
		BLSG A 0{
			invoker.weaponstatus[0]&=~BRONF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[BRONS_CHAMBER]>1
				||!countinv("BrontornisRound")
			)setweaponstate("nope");
		}goto unloadstart;
	unload:
		BLSG A 0{
			invoker.weaponstatus[0]|=BRONF_JUSTUNLOAD;
		}goto unloadstart;

	unloadstart:
		BLSG A 1;
		BLSG BBB 2 A_MuzzleClimb(
			-frandom(0.5,0.6),frandom(0.5,0.6),
			-frandom(0.5,0.6),frandom(0.5,0.6)
		);
		BLSG B 1 offset(1,34);
		BLSG B 1 offset(2,44) A_SetTics(invoker.weaponstatus[BRONS_HEAT]>>3);
		BLSG B 12 offset(4,54){
			int chm=invoker.weaponstatus[BRONS_CHAMBER];
			int bheat=invoker.weaponstatus[BRONS_HEAT];
			invoker.weaponstatus[BRONS_CHAMBER]=0;
			if(chm<1){
				A_SetTics(6+max(0,bheat-20));
				return;
			}

			A_StartSound("weapons/brontoload",8,CHANF_OVERLAP);
			if(chm>1){
				if(
					PressingUnload()
					&&!A_JumpIfInventory("BrontornisRound",0,"null")
				){
					A_SetTics(18);
					A_StartSound("weapons/pocket",9);
					A_GiveInventory("BrontornisRound");
				}
				else A_SpawnItemEx("BrontornisRound",
					cos(pitch)*2,0,height-10-sin(pitch)*2,
					vel.x,vel.y,vel.z-frandom(-1,1),
					random(-3,3),SXF_ABSOLUTEMOMENTUM|
					SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH|
					SXF_TRANSFERTRANSLATION
				);
			}else if(chm==1){
				A_StartSound("weapons/brontopop",8,CHANF_OVERLAP,
					volume:0.04*bheat
				);
				A_SpawnItemEx("TerrorCasing",
					cos(pitch)*4,0,height-10-sin(pitch)*4,
					vel.x,vel.y,vel.z+min(0.12*bheat,4),
					frandom(-1,1),SXF_ABSOLUTEMOMENTUM|
					SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH|
					SXF_TRANSFERTRANSLATION
				);
			}
		}
		BLSG B 1 offset(0,56) A_JumpIf(invoker.weaponstatus[0]&BRONF_JUSTUNLOAD,"reloadend");
		BLSG B 1 offset(0,51) A_StartSound("weapons/pocket",9,CHANF_OVERLAP);
		BLSG B 1 offset(0,54);
		BLSG B 3 offset(0,56);
		BLSG B 3 offset(0,54);
		BLSG B 3 offset(0,55);
		BLSG B 4 offset(0,54){
			invoker.weaponstatus[BRONS_CHAMBER]=2;
			A_TakeInventory("BrontornisRound",1,TIF_NOTAKEINFINITE);
			A_StartSound("weapons/brontoload",8,CHANF_OVERLAP);
		}
		BLSG B 6 offset(0,53);
	reloadend:
		BLSG B 6 offset(0,52);
		BLSG B 2 offset(0,44);
		BLSG B 1 offset(0,38);
		BLSG B 1 offset(0,34);
		BLSG BA 4;
		BLSG A 0 A_StartSound("weapons/brontoclose",8,CHANF_OVERLAP);
		goto ready;

	spawn:
		BLST A -1;
		stop;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[BRONS_CHAMBER]=2;
		if(!idfa){
			weaponstatus[0]=0;
			weaponstatus[BRONS_HEAT]=0;
			weaponstatus[BRONS_DOT]=4;
		}
	}
	override void loadoutconfigure(string input){
		int zoom=getloadoutvar(input,"zoom",1);
		if(!zoom)weaponstatus[0]&=~BRONF_ZOOM;
		else if(zoom>0)weaponstatus[0]|=BRONF_ZOOM;

		int xhdot=getloadoutvar(input,"dot",3);
		if(xhdot>=0)weaponstatus[BRONS_DOT]=xhdot;
	}
}
enum brontostatus{
	BRONF_ZOOM=1,
	BRONF_JUSTUNLOAD=2,

	BRONS_STATUS=0,
	BRONS_CHAMBER=1,
	BRONS_HEAT=2,
	BRONS_DOT=3,
};



//map pickup
class BrontornisSpawner:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_SpawnItemEx("BrontornisRound",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("BrontornisRound",3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("BrontornisRound",1,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("BrontornisRound",-3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("Brontornis",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		}stop;
	}
}
