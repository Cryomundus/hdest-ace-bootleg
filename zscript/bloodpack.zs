//-------------------------------------------------
// Blood Substitute
//-------------------------------------------------
class SecondBlood:HDInjectorMaker{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Synhetic Blood"
		//$Sprite "PBLDA0"

		scale 0.5;
		-hdpickup.droptranslation
		inventory.pickupmessage "Picked up a synthblood pack.";
		inventory.icon "PBLDA0";
		hdpickup.bulk ENC_STIMPACK*2;
		tag "synthetic blood";
		hdpickup.refid HDLD_BLODPAK;
		+inventory.ishealth
		hdinjectormaker.injectortype "SecondBloodSticker";
	}
	states{
	spawn:
		PBLD A -1;
		stop;
	}
}
class SecondBloodSticker:HDWoundFixer{
	default{
		+weapon.wimpy_weapon
		weapon.selectionorder 1012;
	}
	override inventory CreateTossable(int amt){
		HDWoundFixer.DropMeds(owner,0);
		return null;
	}
	override string gethelptext(){
		return "\cuSynthetic Blood\n"
		..WEPHELP_FIRE.."  Attach"
		..(owner.countinv("BloodBagWorn")?"\n"..WEPHELP_ALTRELOAD.."  Remove":"")
	;}
	states{
	spawn:
		PBLD A 0;
		stop;
	select:
		TNT1 A 10{
			if(getcvar("hd_helptext"))
			A_WeaponMessage("\cr::: \cgSECOND BLOOD \cr:::\c-\n\n\nPress and hold Fire\nto attach.",175);
		}
		goto super::select;
	altreload:
	unload:
		TNT1 A 0 A_StartSound("weapons/pocket",CHAN_BODY);
		TNT1 A 15 A_JumpIf(!countinv("BloodBagWorn")||HDWoundFixer.CheckCovered(self,true),"nope");
		TNT1 A 10{
			A_DropInventory("BloodBagWorn");
			A_ClearRefire();
		}goto nope;
	reload:
		TNT1 A 14 {HDPlayerPawn.CheckStrip(self,self);}
		TNT1 A 0 A_Refire();
		goto readyend;
	ready:
		TNT1 A 0{
			if(!countinv("SecondBlood")){
				A_SelectWeapon("HDFist");
				setweaponstate("deselect");
				invoker.goawayanddie();
			}
		}
		TNT1 A 1 A_WeaponReady(WRF_ALLOWRELOAD|WRF_ALLOWUSER1|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
		goto readyend;
	fire:
	altfire:
		TNT1 A 0 A_JumpIf(!countinv("SecondBlood"),"nope");
		TNT1 A 10 A_StartSound("bloodpack/open",CHAN_WEAPON);
		TNT1 AAA 8 A_StartSound("bloodpack/shake",CHAN_WEAPON,CHANF_OVERLAP);
		TNT1 A 4;
		TNT1 A 0 A_Refire();
		goto ready;
	hold:
	althold:
		TNT1 A 1{
			hdplayerpawn patient=null;
			int bt=player.cmd.buttons;
			if(bt&BT_ATTACK){
				patient=hdplayerpawn(self);
				A_MuzzleClimb(frandom(-0.3,0.3),pitch<45?0.4:0.);
			}else if(bt&BT_ALTATTACK){
				//get the patient
				flinetracedata blt;
				LineTrace(
					angle,
					32,
					pitch,
					0,
					offsetz:height-10.,
					data:blt
				);
				actor tracbak=invoker.tracer;
				invoker.tracer=blt.hitactor;
				if(
					!tracbak
					||tracbak!=blt.hitactor
					||!hdplayerpawn(tracbak)
				){
					A_WeaponMessage("No valid patient in range.");
					invoker.weaponstatus[SBS_INJECTCOUNTER]=0;
					return;
				}
				patient=hdplayerpawn(tracbak);
			}
			if(patient)invoker.weaponstatus[SBS_INJECTCOUNTER]++;else{
				invoker.weaponstatus[SBS_INJECTCOUNTER]=0;
				return;
			}
			if(
				patient.countinv("BloodBagWorn")
			){
				A_WeaponMessage(((bt&BT_ALTATTACK)?"Patient has":"You have").." a blood injector already!");
				invoker.weaponstatus[SBS_INJECTCOUNTER]=0;
				return;
			}
			let blockinv=HDWoundFixer.CheckCovered(patient,false);
			if(blockinv){
				if(
					bt&BT_ATTACK
					&&getcvar("hd_autostrip")
				){
					setweaponstate("reload");
				}else{
					A_WeaponMessage("Remove "..((bt&BT_ALTATTACK)?"their":"your").." "..blockinv.gettag().." first.");
					invoker.weaponstatus[SBS_INJECTCOUNTER]=0;
				}
				return;
			}
			if(
				!countinv("SecondBlood")
			){
				A_WeaponMessage("Where did the blood pack go?");
				invoker.weaponstatus[SBS_INJECTCOUNTER]=0;
				return;
			}
			if(invoker.weaponstatus[SBS_INJECTCOUNTER]>30){
				A_TakeInjector("SecondBlood");
				patient.A_GiveInventory("BloodBagWorn");
				A_StartSound("bloodbag/inject",CHAN_WEAPON,CHANF_OVERLAP);
				A_SetBlend("7a 3a 18",0.1,4);
				A_MuzzleClimb(0,2);
				hdweaponselector.select(self,"HDFist");
				setweaponstate("nope");
				invoker.goawayanddie();
			}
		}
		TNT1 A 0 A_Refire();
		goto ready;
	}
	enum SecondBloodNums{
		SBS_INJECTCOUNTER=1,
	}
}
const HDCONST_BLOODBAGAMOUNT=256;
class BloodBagWorn:HDPickup{
	int bloodleft;
	default{
		-solid -noblockmap
		+rollsprite
		-inventory.invbar
		-hdpickup.fitsinbackpack
		+hdpickup.nevershowinpickupmanager
		inventory.maxamount 1;
		height 2;radius 2;
		scale 0.5;
	}
	override void beginplay(){
		super.beginplay();
		bloodleft=HDCONST_BLOODBAGAMOUNT;
	}
	override void Consolidate(){
		let hp=hdplayerpawn(owner);
		if(hp)hp.bloodloss=max(0,hp.bloodloss-4*bloodleft);
		destroy();
	}
	override void touch(actor toucher){}
	override inventory createtossable(int amt){
		let onr=hdplayerpawn(owner);
		if(
			onr
			&&onr.player
		){
			if(
				!onr.player.readyweapon
				||(
					!(onr.player.readyweapon is "HDWoundFixer")
					&&!(onr.player.readyweapon is "SecondBlood")
				)
			)onr.woundcount++;
			else onr.oldwoundcount++;
		}
		return super.createtossable(amt);
	}
	override void DoEffect(){
		let hp=HDPlayerPawn(owner);
		if(!hp){destroy();return;}
		if(!hp.beatcount&&bloodleft>0){
			bloodleft--;
			hp.bloodloss=max(0,hp.bloodloss-4);
			if(hp.fatigue<HDCONST_SPRINTFATIGUE)hp.fatigue++;
		}
		//fall off
		if(
			(
				hp.inpain>0
				||hp.incapacitated
			)
			&&bloodleft<random(-20,5)
		)hp.dropinventory(self);
	}

	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		bool am=hdflags&HDSB_AUTOMAP;
		sb.drawimage(
			"PBLDA0",
			am?(8,134):(68,-10),
			am?sb.DI_TOPLEFT:(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM),
			scale:(0.6,0.6)
		);
		sb.drawstring(
			sb.pnewsmallfont,sb.formatnumber(bloodleft),
			am?(14,136):(72,-10),
			am?(sb.DI_TOPLEFT|sb.DI_TEXT_ALIGN_RIGHT)
			:(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT),
			Font.CR_RED,scale:(0.5,0.5)
		);
	}

	//there is never any reason ingame to pick this thing up.
	override bool cancollidewith(actor other,bool passive){
		return false;
	}

	states(actor){
	spawn:
		PBLD B 0 nodelay{
			if(!random(0,1))scale.x=-scale.x;
			roll=frandom(-20,20);
		}
		PBLD B 3{
			if(bloodleft>0){
				if(floorz==pos.z&&vel!=(0,0,0))A_SpawnItemEx("HDBloodTrailFloor");
				if(!(level.time%2))bloodleft--;
				angle+=frandom(3,6);
				A_SpawnParticle("red",
					SPF_RELATIVE,70,frandom(1.6,1.9),0,
					0,2,4,
					frandom(-0.4,0.4),frandom(-0.4,0.4),frandom(5.,5.2),
					frandom(-0.1,0.1),frandom(-0.1,0.1),-1.
				);
			}
		}
		wait;
	}
}
