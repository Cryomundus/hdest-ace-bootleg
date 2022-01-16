// ------------------------------------------------------------
// Rocket Launcher
// ------------------------------------------------------------
class HDRL:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Rocket Launcher"
		//$Sprite "LAUNA0"

		+weapon.explosive
		weapon.selectionorder 92;
		weapon.slotnumber 5;
		weapon.slotpriority 1;
		scale 0.6;
		inventory.pickupmessage "You got the rocket launcher!";
		obituary "$OB_ROCKET";
		hdweapon.barrelsize 32,3.1,5;
		hdweapon.refid HDLD_LAUNCHR;
		tag "rocket launcher";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void tick(){
		super.tick();
		drainheat(RLS_SMOKE,12);
	}
	override double gunmass(){
		return 10+weaponstatus[RLS_MAG]+weaponstatus[RLS_CHAMBER];
	}
	override double weaponbulk(){
		double blx=175+weaponstatus[RLS_MAG]*ENC_ROCKETLOADED;
		int chmb=weaponstatus[RLS_CHAMBER];
		if(chmb>1)blx+=ENC_HEATROCKETLOADED;
		else if(chmb==1)blx+=ENC_ROCKETLOADED;
		return blx;
	}
	override void beginplay(){
		super.beginplay();
		weaponstatus[RLS_DOT]=3;
	}
	override string,double getpickupsprite(){return "LAUNA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("ROQPA0",(-47,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
			sb.drawimage("ROCKA0",(-58,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
			sb.drawnum(hpl.countinv("HDRocketAmmo"),-41,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			sb.drawnum(hpl.countinv("HEATAmmo"),-54,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		int ab=hdw.airburst;
		if(
			hdw.weaponstatus[RLS_CHAMBER]>1||
			!(hdw.weaponstatus[0]&RLF_GRENADEMODE)
		){
			if(hdw.weaponstatus[RLS_CHAMBER]>1){
				ab=0;
				sb.drawrect(-22,-15,3,2);
				sb.drawrect(-18,-15,2,2);
				sb.drawrect(-26,-17,4,6);
				sb.drawrect(-30,-16,4,4);
			}else{
				sb.drawrect(-22,-13,3,1);
				sb.drawrect(-18,-13,2,1);
				sb.drawrect(-26,-14,4,3);
			}
		}else{
			sb.drawrect(-26,-27+min(16,ab>>9),4,1);
			sb.drawrect(-23,-26,1,16);
			sb.drawrect(-25,-26,1,16);
		}
		if(ab)sb.drawstring(
			sb.mAmountFont,string.format("%.2f",ab*0.01),
			(-32,-15),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
			ab?Font.CR_WHITE:Font.CR_DARKGRAY
		);
		sb.drawwepnum(hdw.weaponstatus[RLS_MAG],6);
		if(hdw.weaponstatus[RLS_CHAMBER]>0)sb.drawrect(-19,-11,3,1);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.."  "..(weaponstatus[0]&RLF_GRENADEMODE?"Rocket":"Grenade").." mode\n"
		..(weaponstatus[RLS_CHAMBER]>1?(
			WEPHELP_ALTRELOAD.." or "..WEPHELP_RELOAD.."  Remove H.E.A.T. round\n"
		):(
			WEPHELP_ALTRELOAD.."  Load H.E.A.T. round\n"
			..WEPHELP_RELOADRELOAD
		))
		..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Airburst\n"
		..WEPHELP_UNLOADUNLOAD
		;
	}
	int rangefinder;
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		if(hdw.weaponstatus[0]&RLF_GRENADEMODE)sb.drawgrenadeladder(hdw.airburst,bob);
		else{
			double dotoff=max(abs(bob.x),abs(bob.y));

			if(dotoff<3){
				string whichdot=sb.ChooseReflexReticle(hdw.weaponstatus[RLS_DOT]);
				sb.drawimage(
					whichdot,(0,0)+bob*3,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.8-dotoff*0.04,scale:(0.8,0.8),
					col:0xFF000000|sb.crosshaircolor.GetInt()
				);
			}
			sb.drawimage(
				"rlrearsight",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			if(hdw.weaponstatus[RLS_CHAMBER]<=1){
				int airburst=hdw.airburst;
				if(airburst)sb.drawnum(airburst/100,
					10+bob.x,9+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK
				);
			}


			if(scopeview){
				double degree=4.;
				double deg=1/degree;
				int scaledyoffset=40;
				int scaledwidth=56;
				int cx,cy,cw,ch;
				[cx,cy,cw,ch]=screen.GetClipRect();
				sb.SetClipRect(
					bob.x-(scaledwidth>>1),bob.y+scaledyoffset-(scaledwidth>>1),
					scaledwidth,scaledwidth,
					sb.DI_SCREEN_CENTER
				);

				if(HDMath.Pre460()){
					//the old square view code - kept until LZDoom supports Shape2D
					texman.setcameratotexture(hpc,"HDXHCAM3",degree);
					sb.drawimage(
						"HDXHCAM3",(0,scaledyoffset)+bob,
						sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
						scale:(0.5,0.5)
					);
					sb.drawimage(
						"scophole",(0,scaledyoffset)+bob*5,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
						scale:(0.95,0.95)
					);
				}else{
					//the new circular view code that doesn't work with LZDoom 3.87c
					sb.fill(color(255,0,0,0),
						bob.x-27,scaledyoffset+bob.y-27,
						54,54,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
					);
					texman.setcameratotexture(hpc,"HDXCAM_RLAUN",degree);
					let cam  = texman.CheckForTexture("HDXCAM_RLAUN",TexMan.Type_Any);
					double camSize = texman.GetSize(cam);
					sb.DrawCircle(cam, (0, scaledyoffset) + bob*5, .34, usePixelRatio: true);
				}
				screen.SetClipRect(cx,cy,cw,ch);

				sb.drawimage(
					"rlret",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.82,0.82)
				);
				sb.drawimage(
					"rlscop",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.82,0.82)
				);


				//readings
				if(
					(level.time&(1|2))
					||rangefinder>14
				)sb.drawnum(rangefinder,
					4+bob.x,17+bob.y,sb.DI_SCREEN_CENTER,Font.CR_RED,0.5
				);
				if(hdw.weaponstatus[RLS_CHAMBER]<=1){
					int airburst=hdw.airburst;
					if(airburst)sb.drawnum(max(10,airburst/100),
						4+bob.x,52+bob.y,sb.DI_SCREEN_CENTER,Font.CR_WHITE,0.5
					);
				}

			}
		}
	}
	override void SetReflexReticle(int which){weaponstatus[RLS_DOT]=which;}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			double angchange=owner.findinventory("HEATAmmo")?10:0;
			if(angchange)owner.angle-=angchange;
			owner.A_DropInventory("HDRocketAmmo",1);
			if(angchange){
				owner.angle+=angchange*2;
				owner.A_DropInventory("HEATAmmo",1);
				owner.angle-=angchange;
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("DudRocketAmmo");
		owner.A_SetInventory("HEATAmmo",1);
		owner.A_SetInventory("HDRocketAmmo",5);
	}
	states{
	select0:
		LAUG A 0 A_CheckDefaultReflexReticle(RLS_DOT);
		LAUG AB 0;
		MISG AB 0;
		MISG A 0 A_CheckIdSprite("LAUGA0","MISGA0");
		goto select0big;
	deselect0:
		MISG # 0 A_CheckIdSprite("LAUGA0","MISGA0");
		---- A 0;
		goto deselect0small;

	ready:
		MISG A 0 A_CheckIdSprite("LAUGA0","MISGA0");
		#### A 1{
			A_WeaponReady(WRF_ALL);

			//update rangefinder
			if(
				!(level.time&(1|2|4|8))
				&&max(abs(vel.x),abs(vel.y),abs(vel.z))<2
				&&(
					!player.cmd.pitch
					&&!player.cmd.yaw
				)
			){
				flinetracedata frt;
				linetrace(
					angle,512*HDCONST_ONEMETRE,pitch-0.8,flags:TRF_NOSKY,
					offsetz:height*0.88,
					data:frt
				);
				invoker.rangefinder=int(frt.distance*(1./HDCONST_ONEMETRE));
			}
		}
		goto readyend;

	firemode:
		goto abadjust;


	fire:
		#### A 1;
		goto shoot;
	althold:
	hold:
		---- A 0;
		goto nope;
	shoot:
		#### A 2{
			int chm=invoker.weaponstatus[RLS_CHAMBER];
			if(chm<1){
				setweaponstate("chamber_manual");
				return;
			}
			gyrogrenade rkt;
			if(
				invoker.weaponstatus[0]&RLF_GRENADEMODE
				&&chm==1
			){
				//shoot a grenade
				A_ZoomRecoil(0.995);
				A_FireHDGL();
				invoker.weaponstatus[RLS_SMOKE]+=5;
				invoker.weaponstatus[RLS_CHAMBER]=0;
				setweaponstate("chamber");
				A_MuzzleClimb(
					0,0,
					-0.4,-0.8,
					-0.1,-0.3
				);
			}else{
				//shoot a rocket
				class<actor> rrr;
				if(chm>1){
					rrr="HDHEAT";
					A_ChangeVelocity(cos(pitch),0,sin(pitch),CVF_RELATIVE);
				}else rrr="GyroGrenade";
				rkt=gyrogrenade(spawn(rrr,(
					pos.xy,
					pos.z+HDWeapon.GetShootOffset(
						self,invoker.barrellength,
						invoker.barrellength-HDCONST_SHOULDERTORADIUS
					)
				),ALLOW_REPLACE));
				invoker.weaponstatus[RLS_SMOKE]+=50;
				rkt.angle=angle;rkt.pitch=pitch;rkt.target=self;rkt.master=self;
				rkt.primed=false;
				rkt.isrocket=true;
				if(
					chm==1
					&&invoker.airburst
				)rkt.airburst=int(max(1000,abs(invoker.airburst))*HDCONST_ONEMETRE*0.01);
				if(!(player.cmd.buttons&BT_ZOOM))invoker.airburst=0;
				invoker.weaponstatus[RLS_CHAMBER]=0;
				A_StartSound("weapons/rockignite",CHAN_WEAPON,CHANF_OVERLAP);
				A_StartSound("weapons/rockboom",CHAN_WEAPON,CHANF_OVERLAP);
			}
		}
		#### A 2{
			A_ZoomRecoil(0.7);
			if(gunbraced()){
				hdplayerpawn(self).gunbraced=false;
				A_MuzzleClimb(
					0,0,
					frandom(1,1.2),-frandom(1,1.5),
					frandom(0.7,0.9),-frandom(1.5,2),
					-frandom(0.8,1.),frandom(2,3)
				);
				A_ChangeVelocity(cos(pitch)*-1,0,sin(pitch)*1,CVF_RELATIVE);
			}else{
				A_MuzzleClimb(
					0,0,
					frandom(1.2,1.7),-frandom(2,2.5),
					frandom(1.,1.2),-frandom(2.5,3),
					frandom(0.6,0.8),-frandom(2,3)
				);
				A_ChangeVelocity(cos(pitch)*-3,0,sin(pitch)*3,CVF_RELATIVE);
				if(self is "hdplayerpawn")hdplayerpawn(self).stunned+=10;
			}
			A_Gunflash();
		} 
		#### B 5;
		goto chamber;
	flash:
		LAUF ABCD 0;
		MISF ABCD 0;
		MISF A 2 bright{
			A_CheckIdSprite("LAUFA0","MISFA0",PSP_FLASH);
			A_StartSound("weapons/rocklaunch",CHAN_WEAPON,CHANF_OVERLAP,volume:0.6);
			HDFlashAlpha(128);
			A_Light1();
		}
		#### B 2 bright A_Light2();
		#### C 2 bright A_Light1();
		#### D 1 bright A_Light0();
		TNT1 A 0 A_AlertMonsters();
		stop;

	chamber:
		#### A 1 offset(0,34){
			if(invoker.weaponstatus[RLS_CHAMBER]>0){
				setweaponstate("nope");
				return;
			}
			A_StartSound("weapons/rockchamber",8);
		}
		#### A 1 offset(1,36){
			if(invoker.weaponstatus[RLS_MAG]>0){
				invoker.weaponstatus[RLS_CHAMBER]=1;
				invoker.weaponstatus[RLS_MAG]--;
			}
		}
		#### A 1 offset(0,34);
		goto nope;
	chamber_manual:
		#### A 1 offset(0,34){
			if(invoker.weaponstatus[RLS_CHAMBER]>0){
				setweaponstate("nope");
				return;
			}
			A_StartSound("weapons/rockchamber",8);
		}
		#### A 1 offset(0,37);
		#### A 2 offset(1,36){
			if(invoker.weaponstatus[RLS_MAG]>0){
				invoker.weaponstatus[RLS_CHAMBER]=1;
				invoker.weaponstatus[RLS_MAG]--;
			}
		}
		#### A 1 offset(0,34);
		goto nope;

	altfire:
	grenadeorrocket:
		#### A 1 offset(0,34){
			if(invoker.weaponstatus[RLS_CHAMBER]>1){
				invoker.weaponstatus[0]&=~RLF_GRENADEMODE;
				setweaponstate("nope");
				return;
			}
			A_WeaponBusy();
		}
		#### A 2 offset(0,36) A_StartSound("weapons/rockchamber",8);
		#### A 1 offset(0,37);
		#### A 2 offset(1,38);
		#### A 3 offset(2,37){
			invoker.weaponstatus[0]^=RLF_GRENADEMODE;
			A_SetHelpText();
		}
		#### A 2 offset(1,36);
		#### A 1 offset(0,34);
		goto nope;
	reload:
		#### A 0 A_JumpIf(invoker.weaponstatus[RLS_CHAMBER]>1,"altreload");
		#### A 0 A_JumpIf(
			(invoker.weaponstatus[RLS_CHAMBER]>0&&invoker.weaponstatus[RLS_MAG]>=5)
			||!countinv("HDRocketAmmo"),
			"nope"
		);
		#### B 1 offset(2,34);
		#### B 1 offset(4,36) A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		#### B 1 offset(10,38);
		#### B 4 offset(12,40){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			A_StartSound("weapons/rockopen",8);
		}
		#### B 10 offset(11,38) A_StartSound("weapons/rockopen2",8,CHANF_OVERLAP);
	reload2:
		#### B 0 A_JumpIf(
			(invoker.weaponstatus[RLS_CHAMBER]>0&&invoker.weaponstatus[RLS_MAG]>=5)
			||!countinv("HDRocketAmmo"),
			"reloadend"
		);
		#### B 9 offset(10,38) A_StartSound("weapons/pocket",9);
		#### B 0{
			if(health<40)A_SetTics(7);
			else if(health<60)A_SetTics(3);
		}
		#### B 2 offset(12,40)A_StartSound("weapons/rockreload",8);
		#### B 3 offset(10,38){
			if(!countinv("HDRocketAmmo"))return;
			A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
			if(invoker.weaponstatus[RLS_CHAMBER]<1)invoker.weaponstatus[RLS_CHAMBER]=1;
			else invoker.weaponstatus[RLS_MAG]++;
		}
		#### BB 1 offset(10,34) A_JumpIf(!pressingreload(),"reloadend");
		loop;
	reloadend:
		#### B 5 offset(10,36) A_StartSound("weapons/rockopen2",8);
		#### B 1 offset(8,38) A_StartSound("weapons/rockopen",8,CHANF_OVERLAP);
		#### B 1 offset(4,36);
		#### B 1 offset(2,34);
		goto nope;

	user1:
	altreload:
		#### A 4{
			if(
				invoker.weaponstatus[RLS_CHAMBER]<2
				&&!countinv("HEATAmmo")
			)setweaponstate("nope");
		}
		#### A 1 offset(0,34);
		#### A 1 offset(0,36);
		#### B 1 offset(0,38);
		#### B 4 offset(0,40) A_StartSound("weapons/rockopen",8);
		#### B 10 offset(0,38) A_StartSound("weapons/rockopen2",8);
		#### B 9 offset(1,38) A_StartSound("weapons/pocket",8);
		#### B 0{
			if(health<40)A_SetTics(7);
			else if(health<60)A_SetTics(3);
		}
		#### B 4 offset(0,40) A_StartSound("weapons/rockreload",8);

		#### B 6{
			int chh=invoker.weaponstatus[RLS_CHAMBER];
			if(chh>1){
				setweaponstate("removeheatfromchamber");
				return;
			}

			if(invoker.weaponstatus[RLS_CHAMBER]<1){
				setweaponstate("loadheatintoemptychamber");
				return;
			}else{
				invoker.weaponstatus[RLS_CHAMBER]=0;
				if(invoker.weaponstatus[RLS_MAG]<5){
					invoker.weaponstatus[RLS_MAG]++;
					return;
				}
				if(A_JumpIfInventory("HDRocketAmmo",0,"null"))A_SpawnItemEx(
					"HDRocketAmmo",10,0,10,vel.x,vel.y,vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
				);else A_GiveInventory("HDRocketAmmo",1);
			}
		}goto loadheatintoemptychamber;
	loadheatintoemptychamber:
		#### B 3 offset(0,38);
		#### B 2 offset(0,34){
			if(!countinv("HEATAmmo"))return;
			invoker.weaponstatus[RLS_CHAMBER]=2;
			A_SetHelpText();
			invoker.weaponstatus[0]&=~RLF_GRENADEMODE;
			A_TakeInventory("HEATAmmo",1,TIF_NOTAKEINFINITE);
		}goto altreloadend;
	removeheatfromchamber:
		#### B 10 offset(1,35){
			invoker.weaponstatus[RLS_CHAMBER]=0;
			A_SetHelpText();
			if(
				A_JumpIfInventory("HEATAmmo",0,"null")
				||(!PressingUnload()&&!PressingAltReload())
			){
				A_SpawnItemEx(
					"HEATAmmo",10,0,height-16,vel.x,vel.y,vel.z+2,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
				);
				setweaponstate("altreloadend");
			}else{
				A_StartSound("weapons/pocket",9);
				A_GiveInventory("HEATAmmo",1);
			}
		}goto altreloadend;
	altreloadend:
		#### B 5 offset(0,36) A_StartSound("weapons/rockopen2",8);
		#### B 0 A_StartSound("weapons/rockopen",8);
		#### B 1 offset(0,38);
		#### A 1 offset(0,36);
		#### A 1 offset(0,34);
		goto nope;

	user4:
	unload:
		#### B 4{
			if(
				invoker.weaponstatus[RLS_CHAMBER]>1
			)setweaponstate("altreload");
			else if(
				invoker.weaponstatus[RLS_CHAMBER]<1
				&&invoker.weaponstatus[RLS_MAG]<1
			)setweaponstate("nope");
		}
		#### B 1 offset(2,34);
		#### B 1 offset(4,36) A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		#### B 1 offset(10,38);
		#### B 4 offset(12,40){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			A_StartSound("weapons/rockopen",8);
		}
		#### B 2 offset(11,38) A_StartSound("weapons/rockopen2",8);
	unload2:
		#### B 0 A_JumpIf(invoker.weaponstatus[RLS_MAG]<1&&invoker.weaponstatus[RLS_CHAMBER]<1,"unloadend");
		#### B 10 offset(12,40) A_StartSound("weapons/rockreload",8,CHANF_OVERLAP);
		#### B 9 offset(10,38){
			if(!invoker.weaponstatus[RLS_CHAMBER]){
				invoker.weaponstatus[RLS_MAG]--;
			}else{
				invoker.weaponstatus[RLS_CHAMBER]=0;
			}
			if(
				A_JumpIfInventory("HDRocketAmmo",0,"null")
				||(!PressingUnload()&&!PressingReload())
			){
				A_SpawnItemEx(
					"HDRocketAmmo",10,0,height-16,vel.x,vel.y,vel.z+2,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
				);
			}else{
				A_StartSound("weapons/pocket",9);
				A_GiveInventory("HDRocketAmmo",1);
			}
		}
		#### B 5 offset(10,36) A_StartSound("weapons/rockopen2",8);
		#### B 4{
			if(health<40)A_SetTics(4);
			A_StartSound("weapons/rockopen",8,CHANF_OVERLAP);
		}
		#### B 0 A_JumpIf(!pressingunload(),"unloadend");
		goto unload2;
	unloadend:
		#### B 1 offset(8,38);
		#### B 1 offset(4,36);
		#### B 1 offset(2,34);
		goto nope;

	spawn:
		LAUN A -1;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[RLS_MAG]=5;
		if(idfa){
			weaponstatus[RLS_CHAMBER]=max(1,weaponstatus[RLS_CHAMBER]);
		}else{
			weaponstatus[0]=0;
			weaponstatus[RLS_CHAMBER]=1;
			airburst=0;
			if(!owner){
				weaponstatus[0]+=random(0,1)*RLF_GRENADEMODE;
			}
		}
	}
	override void loadoutconfigure(string input){
		int heatloaded=getloadoutvar(input,"heat",1);
		if(!heatloaded)weaponstatus[RLS_CHAMBER]=1;
		else if(heatloaded>0)weaponstatus[RLS_CHAMBER]=2;

		int xhdot=getloadoutvar(input,"dot",3);
		if(xhdot>=0)weaponstatus[RLS_DOT]=xhdot;

		//if no heat, evaluate grenade mode
		if(weaponstatus[RLS_CHAMBER]!=2){
			weaponstatus[RLS_CHAMBER]=1;
			int grenademode=getloadoutvar(input,"grenade",1);
			if(!grenademode)weaponstatus[0]&=~RLF_GRENADEMODE;
			else if(grenademode>0)weaponstatus[0]|=RLF_GRENADEMODE;
		}
	}
}
enum rocketstatus{
	RLF_GRENADEMODE=2,

	RLS_STATUS=0,
	RLS_MAG=1,
	RLS_CHAMBER=2,
	RLS_AIRBURST=3,
	RLS_SMOKE=4,
	RLS_DOT=5,
};








// ------------------------------------------------------------
// Bloop Launcher
// ------------------------------------------------------------
class Blooper:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Grenade Launcher"
		//$Sprite "BLOPA0"

		+weapon.explosive
		+hdweapon.fitsinbackpack
		weapon.selectionorder 93;
		weapon.slotnumber 5;
		weapon.slotpriority 1;
		scale 0.6;
		inventory.pickupmessage "You got the grenade launcher!";
		obituary "%o was blooped by %k.";
		hdweapon.barrelsize 24,1.6,3;
		tag "grenade launcher";
		hdweapon.refid HDLD_BLOOPER;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override double gunmass(){
		return weaponstatus[0]&BLOPF_LOADED?5:4;
	}
	override double weaponbulk(){
		return 60+(weaponstatus[0]&BLOPF_LOADED?ENC_ROCKETLOADED:0);
	}
	override string,double getpickupsprite(){return "BLOPA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("ROQPA0",(-52,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
			sb.drawnum(hpl.countinv("HDRocketAmmo"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[0]&BLOPF_LOADED)sb.drawrect(-21,-13,5,3);
		int ab=hdw.airburst;
		sb.drawstring(
			sb.mAmountFont,ab?string.format("%.2f",hdw.airburst*0.01):"--.--",
			(-28,-15),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
			ab?Font.CR_WHITE:Font.CR_BLACK
		);
		sb.drawwepnum(
			hpl.countinv("HDRocketAmmo"),
			(HDCONST_MAXPOCKETSPACE/ENC_ROCKET)
		);
		sb.drawrect(-28,-43+min(32,ab>>8),6,1);
		sb.drawrect(-23,-42,1,32);
		sb.drawrect(-25,-42,1,32);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.."  Reset airburst\n"
		..WEPHELP_RELOADRELOAD
		..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Airburst\n"
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		sb.drawgrenadeladder(hdw.airburst,bob);
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory("HDRocketAmmo",1);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("DudRocketAmmo");
		owner.A_SetInventory("HDRocketAmmo",1);
	}
	states{
	select0:
		BLOG A 0;
		goto select0small;
	deselect0:
		BLOG A 0;
		goto deselect0small;

	ready:
		BLOG A 1 A_WeaponReady(WRF_ALL);
		goto readyend;
	hold:
	altfire:
		BLOG A 0{invoker.airburst=0;}
		goto nope;
	firemode:
		goto abadjust;

	fire:
		BLOG B 0 A_JumpIf(invoker.weaponstatus[0]&BLOPF_LOADED,"reallyshoot");
		goto nope;
	reallyshoot:
		BLOG A 1{
			A_ZoomRecoil(0.9);
			A_FireHDGL();
			invoker.weaponstatus[0]&=~BLOPF_LOADED;
		}
		BLOG A 1 offset(0,37);
		BLOG B 0 A_MuzzleClimb(-frandom(2.,2.7),-frandom(3.4,5.2));
		goto nope;
	loadcommon:
		BLOG B 1 offset(2,36)A_StartSound("weapons/rockopen",8);
		BLOG C 1 offset(4,42)A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		BLOG C 1 offset(10,50);
		BLOG C 2 offset(12,60)A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		BLOG C 3 offset(13,72) A_StartSound("weapons/rockopen2",8,CHANF_OVERLAP);
		BLOG D 3 offset(14,74);
		BLOG D 3 offset(11,76)A_StartSound("weapons/pocket",9);
		BLOG D 7 offset(10,72);
		BLOG D 0{
			if(health<40)A_SetTics(7);
			else if(health<60)A_SetTics(3);
		}
		BLOG D 4 offset(12,74) A_StartSound("weapons/rockreload",8);
		BLOG D 2 offset(10,72){
			if(invoker.weaponstatus[0]&BLOPF_JUSTUNLOAD){
				if(
					!(invoker.weaponstatus[0]&BLOPF_LOADED)
				)setweaponstate("reloadend");else{
					invoker.weaponstatus[0]&=~BLOPF_LOADED;
					if(
						(!PressingUnload()&&!PressingReload())
						||A_JumpIfInventory("HDRocketAmmo",0,"null")
					)
					A_SpawnItemEx(
						"HDRocketAmmo",10,0,height-16,vel.x,vel.y,vel.z+2,
						0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
					);
					else{
						A_GiveInventory("HDRocketAmmo",1);
						A_StartSound("weapons/pocket",9);
						A_SetTics(4);
					}
				}
			}else{
				if(
					invoker.weaponstatus[0]&BLOPF_LOADED
					||!countinv("HDRocketAmmo")
				)setweaponstate("reloadend");else{
					A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
					invoker.weaponstatus[0]|=BLOPF_LOADED;
					A_SetTics(5);
				}
			}
		}
	reloadend:
		BLOG D 1 offset(12,80);
		BLOG D 1 offset(11,88);
		BLOG D 1 offset(10,90) A_StartSound("weapons/rockopen2",8);
		BLOG D 1 offset(10,94);
		TNT1 A 4;
		BLOG D 0 A_StartSound("weapons/rockopen",8,CHANF_OVERLAP);
		BLOG C 1 offset(8,78);
		BLOG C 1 offset(8,66);
		BLOG C 1 offset(8,52);
		BLOG B 1 offset(4,40);
		BLOG B 1 offset(2,34);
		goto ready;
	altreload:
	reload:
		BLOG B 0 A_JumpIf(
			invoker.weaponstatus[0]&BLOPF_LOADED
			||!countinv("HDRocketAmmo"),
			"nope"
		);
		BLOG B 0{
			if(
				invoker.weaponstatus[0]&BLOPF_LOADED
				||!countinv("HDRocketAmmo")
			)setweaponstate("nope");else{
				invoker.weaponstatus[0]&=~BLOPF_JUSTUNLOAD;
			}
		}goto loadcommon;
	unload:
		BLOG B 0{
			if(
				!(invoker.weaponstatus[0]&BLOPF_LOADED)
			)setweaponstate("nope");else{
				invoker.weaponstatus[0]|=BLOPF_JUSTUNLOAD;
			}
		}goto loadcommon;

	spawn:
		BLOP A -1;
	}
	override void loadoutconfigure(string input){
		//there isn't actually anything to configure,
		//but we need this to keep it loaded
		weaponstatus[0]|=BLOPF_LOADED;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[0]|=BLOPF_LOADED;
		if(!idfa && !owner){
			airburst=0;
		}
	}
}
enum bloopstatus{
	BLOPF_LOADED=1,
	BLOPF_JUSTUNLOAD=2,

	BLOPS_STATUS=0,
	BLOPS_AIRBURST=1,
};





// ------------------------------------------------------------
// Pickups
// ------------------------------------------------------------
class RocketBigPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of Rocket Grenades"
		//$Sprite "BROKA0"

		scale 0.5;
		hdupk.pickupmessage "Picked up a box of rockets.";
		hdupk.pickuptype "HDRocketAmmo";
		hdupk.amount 5;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("HEATAmmo",10,0,0,0,0,0,0,0,220);
		A_SpawnItemEx("HEATAmmo",13,0,0,0,0,0,0,0,220);
		A_SpawnItemEx("HEATAmmo",16,0,0,0,0,0,0,0,220);
	}
	states{
	spawn:
		BROK A -1;
		stop;
	}
}

class BloopMapPickup:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let wep=Blooper(spawn("Blooper",pos,ALLOW_REPLACE));
			if(!wep)return;
			HDF.TransferSpecials(self,wep);

			A_SpawnItemEx("RocketBigPickup",3);
			A_SpawnItemEx("HDRocketAmmo",5);
		}stop;
	}
}
