//-------------------------------------------------
// Stims and berserk
//-------------------------------------------------
class HDInjectorMaker:HDMagAmmo{
	class<weapon>injectortype;
	property injectortype:injectortype;
	override bool IsUsed(){return true;}
	default{
		+inventory.invbar
	}
	states{
	use:
		TNT1 A 0{
			A_GiveInventory(invoker.injectortype);
			A_SelectWeapon(invoker.injectortype);
		}
		fail;
	}
}

class HDDrug:HDDamageHandler{
	default{
		+inventory.undroppable
		inventory.maxamount 1000000;
		HDDamageHandler.priority -1000;
		HDPickup.overlaypriority -1;
	}
	override void PreTravelled(){amount=0;}
	override void OwnerDied(){amount=0;}
	states{
	spawn:
		TNT1 A 0;
		stop;
	}
	/*
		There's no prioritization system in place for these
		the way there is for worn items. This is an intentional
		design choice - everything *should* be fighting each other.

		To avoid anything stupid (in the bad sense) happening,
		make sure no modifications involve setting absolutely or
		clamping the modified value - all things should be done as
		"if more/less than X, do Y".

		Anything that wins out over something else is doing so by
		virtue of faster rate and bigger numbers.
	*/
	virtual void OnHeartbeat(hdplayerpawn hdp){}
	override void Tick(){
		super.Tick();
		if(amount<1)destroy();
	}
}
class PortableStimpack:HDInjectorMaker{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Stimpack"
		//$Sprite "STIMA0"

		scale 0.37;
		-hdpickup.droptranslation
		inventory.pickupmessage "Picked up a stimpack.";
		inventory.icon "STIMA0";
		hdpickup.bulk ENC_STIMPACK;
		tag "stimpack";
		hdpickup.refid HDLD_STIMPAK;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDStimpacker";
	}
	states{
	spawn:
		STIM A -1;
	}
}
class SpentZerk:HDDebris{
	default{
		xscale 0.32;yscale 0.28;radius 3;height 3;
		bouncesound "misc/fragknock";
	}
	states{
	spawn:
		SYRB A 0;
	spawn2:
		---- A 1{
			A_SetRoll(roll+60,SPF_INTERPOLATE);
		}wait;
	death:
		---- A -1{
			roll=0;
			if(!random(0,1))scale.x*=-1;
		}stop;
	}
}
class SpentStim:SpentZerk{
	default{
		translation "176:191=80:95";
	}
	states{
	spawn:
		SYRG A 0 nodelay A_JumpIf(Wads.CheckNumForName("id",0)==-1,1);
		goto spawn2;
		STIM A 0 A_SetScale(0.37,0.37);
		STIM A 0 A_SetTranslation("FreeStimSpent");
		goto spawn2;
		death:
		---- A -1{
			if(Wads.CheckNumForName("id",0)!=-1)roll=0;
			else if(abs(roll)<20)roll+=40;
			if(!random(0,1))scale.x*=-1;
		}stop;
	}
}
class SpentBottle:SpentStim{
	default{
		alpha 0.6;renderstyle "translucent";
		bouncesound "misc/casing";bouncefactor 0.4;scale 0.3;radius 4;height 4;
		translation "10:15=241:243","150:151=206:207";
	}
	override void ondestroy(){
		plantbit.spawnplants(self,7,33);
		actor.ondestroy();
	}
	states{
	spawn:
		BON1 A 0;
		goto spawn2;
	death:
		---- A 100{
			if(random(0,7))roll=randompick(90,270);else roll=0;
			if(roll==270)scale.x*=-1;
		}
		---- A random(2,4){
			if(frandom(0.1,0.9)<alpha){
				angle+=random(-12,12);pitch=random(45,90);
				actor a=spawn("HDGunSmoke",pos,ALLOW_REPLACE);
				a.scale=(0.4,0.4);a.angle=angle;
			}
			A_FadeOut(frandom(-0.03,0.032));
		}wait;
	}
}
class SpentCork:SpentBottle{
	default{
		bouncesound "misc/casing3";scale 0.6;
		translation "224:231=64:71";
	}
	override void ondestroy(){
		plantbit.spawnplants(self,1,0);
		actor.ondestroy();
	}
	states{
	spawn:
		PBRS A 2 A_SetRoll(roll+90,SPF_INTERPOLATE);
		wait;
	}
}
class HDStimpacker:HDWoundFixer{
	class<actor> injecttype;
	class<actor> spentinjecttype;
	class<inventory> inventorytype;
	string noerror;
	property injecttype:injecttype;
	property spentinjecttype:spentinjecttype;
	property inventorytype:inventorytype;
	property noerror:noerror;
	override inventory CreateTossable(int amt){
		HDWoundFixer.DropMeds(owner,0);
		return null;
	}
	override string,double getpickupsprite(){return "STIMA0",1.;}
	override string gethelptext(){return WEPHELP_INJECTOR;}
	default{
		+hdweapon.dontdisarm
		hdstimpacker.injecttype "InjectStimDummy";
		hdstimpacker.spentinjecttype "SpentStim";
		hdstimpacker.inventorytype "PortableStimpack";
		hdstimpacker.noerror "No stimpacks.";
		weapon.selectionorder 1003;
		hdwoundfixer.injectoricon "STIMA0";
		hdwoundfixer.injectortype "PortableStimpack";
		tag "stimpack";
	}
	states{
	spawn:
		TNT1 A 1;
		stop;
	select:
		TNT1 A 0{
			bool helptext=getcvar("hd_helptext");
			if(!countinv(invoker.inventorytype)){
				if(helptext)A_WeaponMessage(invoker.noerror);
				A_SelectWeapon("HDFist");
			}else if(helptext)A_WeaponMessage("\cd<<< \cjSTIMPACK \cd>>>\c-\n\n\nStimpacks help reduce\nbleeding temporarily\n\nand boost performance when injured.\n\n\Press altfire to use on someone else.\n\n\cgDO NOT OVERDOSE.");
		}
		goto super::select;
	deselecthold:
		TNT1 A 1;
		TNT1 A 0 A_Refire("deselecthold");
		TNT1 A 0{
			A_SelectWeapon("HDFist");
			A_WeaponReady(WRF_NOFIRE);
		}goto nope;
	fire:
	hold:
		TNT1 A 1;
		TNT1 A 0{
			if(hdplayerpawn(self))hdplayerpawn(self).gunbraced=false;
			bool helptext=getcvar("hd_helptext");
			if(!countinv(invoker.inventorytype)){
				if(helptext)A_WeaponMessage(invoker.noerror);
				return resolvestate("deselecthold");
			}
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				if(helptext)A_WeaponMessage("Take off your "..blockinv.gettag().." first!",2);
				return resolvestate("nope");
			}
			if(pitch<55){
				A_MuzzleClimb(0,8);
				A_Refire();
				return resolvestate(null);
			}
			return resolvestate("inject");
		}goto nope;
	inject:
		TNT1 A 1{
			A_TakeInjector(invoker.inventorytype);
			A_SetBlend("7a 3a 18",0.1,4);
			A_MuzzleClimb(0,2);
			if(hdplayerpawn(self))A_StartSound(hdplayerpawn(self).medsound,CHAN_VOICE);
			else A_StartSound("*usemeds",CHAN_VOICE);
			A_StartSound("misc/injection",CHAN_WEAPON);
			actor a=spawn(invoker.injecttype,pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=self;
		}
		TNT1 AAAA 1 A_MuzzleClimb(0,-0.5);
		TNT1 A 6;
		TNT1 A 0{
			actor a=spawn(invoker.spentinjecttype,pos+(0,0,height-8),ALLOW_REPLACE);
			a.angle=angle;a.vel=vel;a.A_ChangeVelocity(3,1,2,CVF_RELATIVE);
			a.A_StartSound("weapons/grenopen",8);
		}
		goto injectedhold;
	altfire:
		TNT1 A 10;
		TNT1 A 0 A_Refire();
		goto nope;
	althold:
		TNT1 A 0{
			if(!countinv(invoker.inventorytype)){
				if(getcvar("hd_helptext"))A_WeaponMessage(invoker.noerror);
				A_Refire("deselecthold");
			}
		}
		TNT1 A 8{
			bool helptext=getcvar("hd_helptext");
			flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:height-12,
				data:injectorline
			);
			let c=HDPlayerPawn(injectorline.hitactor);
			if(!c){
				let ccc=HDHumanoid(injectorline.hitactor);
				if(
					ccc
					&&invoker.getclassname()=="HDStimpacker"
				){
					if(
						ccc.stunned<100
						||ccc.health<10
					){
						if(helptext)A_WeaponMessage("They don't need it.",2);
						return resolvestate("nope");
					}
					A_TakeInjector(invoker.inventorytype);
					ccc.A_StartSound(ccc.painsound,CHAN_VOICE);
					ccc.stunned=max(0,ccc.stunned>>1);
					if(!countinv(invoker.inventorytype))return resolvestate("deselecthold");
					return resolvestate("injected");
				}
				if(helptext)A_WeaponMessage("Nothing to be done here.\n\nStimulate thyself? (press fire)",2);
				return resolvestate("nope");
			}
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				if(helptext)A_WeaponMessage("You'll need them to take off their "..blockinv.gettag().."...");
				return resolvestate("nope");
			}
			if(c.countinv("IsMoving")>4){
				bool chelptext=c.getcvar("hd_helptext");
				if(c.stimcount){
					if(chelptext)c.A_Print(string.format("Run away!!!\n\n%s is trying to overdose you\n\n(and possibly bugger you)...",player.getusername()));
					if(helptext)A_WeaponMessage("They seem a bit fidgety...");
				}else{
					if(chelptext)c.A_Print(string.format("Stop squirming!\n\n%s only wants to\n\ngive you some drugs...",player.getusername()));
					if(helptext)A_WeaponMessage("You'll need them to stay still...");
				}
				return resolvestate("nope");
			}
			if(
				//because poisoning people should count as friendly fire!
				(teamplay || !deathmatch)&&
				(
					(
						invoker.injecttype=="InjectStimDummy"
						&& c.stimcount
					)||
					(
						invoker.injecttype=="InjectZerkDummy"
						&& c.zerk
					)
				)
			){
				if(c.getcvar("hd_helptext"))c.A_Print(string.format("Run away!!!\n\n%s is trying to overdose you\n\n(and possibly bugger you)...",player.getusername()));
				if(getcvar("hd_helptext"))A_WeaponMessage("They seem a bit fidgety already...");
				return resolvestate("nope");
			}
			//and now...
			A_TakeInjector(invoker.inventorytype);
			c.A_StartSound(hdplayerpawn(c).medsound,CHAN_VOICE);
			c.A_SetBlend("7a 3a 18",0.1,4);
			actor a=spawn(invoker.injecttype,c.pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=c;
			if(!countinv(invoker.inventorytype))return resolvestate("deselecthold");
			return resolvestate("injected");
		}
	injected:
		TNT1 A 0{
			actor a=spawn(invoker.spentinjecttype,pos+(0,0,height-8),ALLOW_REPLACE);
			a.angle=angle;a.vel=vel;a.A_ChangeVelocity(-2,1,4,CVF_RELATIVE);
			A_StartSound("weapons/grenopen",CHAN_VOICE);
		}
	injectedhold:
		TNT1 A 1 A_ClearRefire();
		TNT1 A 0 A_JumpIf(pressingfire(),"injectedhold");
		TNT1 A 10 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		goto readyend;
	}
}
class InjectStimDummy:IdleDummy{
	hdplayerpawn tg;
	states{
	spawn:
		TNT1 A 6 nodelay{
			tg=HDPlayerPawn(target);
			if(!tg||tg.bkilled){destroy();return;}
			if(tg.zerk)tg.aggravateddamage+=int(ceil(accuracy*0.01*random(1,3)));
		}
		TNT1 A 1{
			if(!target||target.bkilled){destroy();return;}
			HDF.Give(target,"HDStim",HDStim.HDSTIM_DOSE);
		}stop;
	}
}
class HDStim:HDDrug{
	enum StimAmounts{
		HDSTIM_DOSE=400,
		HDSTIM_MAX=480,
	}
	override void doeffect(){
		let hdp=hdplayerpawn(owner);

		double ret=min(0.1,amount*0.003);
		if(hdp.strength<1.+ret)hdp.strength+=0.003;
	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;
		int amt=amount;amount--;

		if(amt>HDSTIM_MAX){

			if(hdp.beatcap>max(6,20-(amount>>5)))hdp.beatcap--;

			if(hdp.stunned<10)hdp.stunned+=2;

			if(
				hdp.bloodpressure<50-(hdp.bloodloss>>4)
			)hdp.bloodpressure+=4;

		}else{

			if(hdp.beatcap>30)hdp.beatcap--;

			if(
				hdp.runwalksprint<1
			){
				if(hdp.fatigue>0)hdp.fatigue--;
				if(hdp.stunned>0)hdp.stunned--;
			}

			if(
				hdp.bloodpressure<14-(hdp.bloodloss>>4)
			)hdp.bloodpressure+=3;
		}

		if(
			hdp.beatmax>=HDCONST_MINHEARTTICS+3
			&&hdp.fatigue<=HDCONST_SPRINTFATIGUE
			&&hdp.health<hdp.healthcap+(amt>>4)
			&&random(1,300)<amt
		){
			hdp.givebody(1);
			if(hdp.fatigue>0)hdp.fatigue--;
		}

		if(hd_debug>=4)console.printf("STIM "..amt.."/"..HDSTIM_MAX.."  = "..hdp.strength);
	}
}



class PortableBerserkPack:hdinjectormaker{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Berserk"
		//$Sprite "PSTRA0"

		inventory.pickupmessage "Picked up a berserk pack.";
		inventory.icon "PSTRA0";
		scale 0.3;
		hdpickup.bulk ENC_STIMPACK;
		tag "berserk pack";
		hdpickup.refid HDLD_BERSERK;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDBerserker";
	}
	states{
	spawn:
		PSTR A -1 nodelay{if(invoker.amount>2)invoker.scale=(0.4,0.35);else invoker.scale=(0.3,0.3);}
	}
}
class HDBerserker:HDStimpacker{
	default{
		hdstimpacker.injecttype "InjectZerkDummy";
		hdstimpacker.spentinjecttype "SpentZerk";
		hdstimpacker.inventorytype "PortableBerserkPack";
		hdstimpacker.noerror "No berserk packs.";
		weapon.selectionorder 1002;
		hdwoundfixer.injectoricon "PSTRA0";
		hdwoundfixer.injectortype "PortableBerserkPack";
		tag "berserk pack";
	}
	override string,double getpickupsprite(){return "PSTRA0",1.;}
	states{
	select:
		TNT1 A 0{
			if(!countinv(invoker.inventorytype)){
				if(getcvar("hd_helptext"))A_WeaponMessage(invoker.noerror);
				A_SelectWeapon("HDFist");
			}else if(getcvar("hd_helptext"))A_WeaponMessage("\cr*** \caBERSERK \cr***\c-\n\n\nBerserk packs help increase\ncombat capabilities temporarily.\n\n\Press altfire to use on someone else.");
		}
		goto HDWoundFixer::select;
	}
}
class InjectZerkDummy:InjectStimDummy{
	states{
	spawn:
		TNT1 A 60 nodelay{
			tg=HDPlayerPawn(target);
		}
		TNT1 A 1{
			if(!tg||tg.bkilled){destroy();return;}
			if(tg.zerk<666){
				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).xdeathsound,CHAN_VOICE);
				else tg.A_StartSound("*xdeath",CHAN_VOICE);
				HDPlayerPawn.Disarm(self);
				tg.A_SelectWeapon("HDFist");
			}else{
				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).painsound,CHAN_VOICE);
				else tg.A_StartSound("*pain",CHAN_VOICE);
			}
			if(tg.stimcount)tg.aggravateddamage+=int(ceil(tg.stimcount*0.05*random(1,3)));
			else tg.aggravateddamage++;

			let zzz=tg.findinventory("HDZerk");
			if(!zzz||zzz.amount<1){
				tg.A_GiveInventory("HDZerk",HDZerk.HDZERK_MAX);
			}else{
				if(zzz.amount>HDZerk.HDZERK_COOLOFF){
					zzz.amount+=HDZerk.HDZERK_DURATION;
				}else{
					zzz.amount=HDZerk.HDZERK_MAX+(zzz.amount>>5);
				}
			}
		}stop;
	}
}
class HDZerk:HDDrug{
	enum ZerkAmounts{
		HDZERK_DURATION=TICRATE*60*4,
		HDZERK_COOLOFF=TICRATE*60*5,
		HDZERK_MAX=HDZERK_COOLOFF+HDZERK_DURATION,
		HDZERK_OVER=HDZERK_MAX+HDZERK_COOLOFF,
	}
	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		sb.SetSize(0,320,200);
		sb.BeginHUD(forcescaled:true);
		sb.fill(
			amount<HDZERK_COOLOFF?
				color(min(100,amount>>5)+(hpl.beatcount?random[zerkshit](-1,1):random[zerkshit](-5,5)),0,0,0)
				:color(min(100,(amount-HDZERK_COOLOFF)>>5)+(hpl.beatcount>>2),90,14,12),
			0,0,screen.getwidth(),screen.getheight()
		);
	}
	override void DoEffect(){
		if(amount<1)return;
		int amt=amount;amount--;

		let hdp=hdplayerpawn(owner);
		if(amt==(HDZERK_COOLOFF+128))hdp.AddBlackout(256,2,4,24);

		bool iszerk=amt>HDZERK_COOLOFF;
		if(
			iszerk
			&&hdp.bloodloss<HDCONST_MAXBLOODLOSS
		){
			if(
				iszerk
				&&hdp.strength<3.
			)hdp.strength+=0.03;

			if(hdp.bloodpressure<40-(hdp.bloodloss>>4))hdp.bloodpressure++;
			if(amt>HDZERK_MAX){
				if(!random(0,7))hdp.damagemobj(hdp,hdp,random(1,5),"bashing",DMG_NO_ARMOR|DMG_NO_PAIN);
				if(!random(0,31))hdp.aggravateddamage++;
				if(hdp.beatcap>random(1,12))hdp.beatcap--;
			}else if(amt>(HDZERK_MAX-(TICRATE<<1))){
				if(hdp.strength<2.)hdp.strength+=0.05;
				hdp.stunned=max(hdp.stunned,10);
				hdp.muzzleclimb1+=(frandom(-2,2),frandom(-2,2));
				hdp.vel+=(frandom(-0.5,0.5),frandom(-0.5,0.5),frandom(-0.5,0.5));
				if(!random(0,3)){
					hdp.givebody(1);
					A_SetBlend("20 0a 0f",0.4,3);

					if(!random(0,int(8-amt*0.0005))){
						hdp.woundcount+=random(0,1);
						if(!random(0,7))hdp.A_StartSound(hdp.painsound,CHAN_VOICE);
						else if(!random(0,7))hdp.aggravateddamage++;
					}

					if(!HDFist(hdp.player.readyweapon)){
						hdp.Disarm(hdp);
						hdp.A_SelectWeapon("HDFist");
					}
				}
			}else if(amt>(HDZERK_MAX-(TICRATE<<3))){
				hdp.muzzleclimb1+=(frandom(-1,1),frandom(-1,1));
				hdp.vel+=(frandom(-0.1,0.1),frandom(-0.1,0.1),frandom(-0.1,0.1));
				if(hdp.fatigue>0)hdp.fatigue-=1;
				if(!random(0,3)){
					hdp.givebody(1);
					if(!HDFist(hdp.player.readyweapon)){
						hdp.Disarm(hdp);
						hdp.A_SelectWeapon("HDFist");
					}
				}
			}else if(iszerk){
				if(hdp.health<(hdp.healthcap<<2))hdp.givebody(1);
				if(hdp.stunned)hdp.stunned=hdp.stunned*4/5;
				if(hdp.fatigue>0&&!(level.time&(1|2)))hdp.fatigue-=1;
				if(hdp.incaptimer)hdp.incaptimer=hdp.incaptimer*14/15;
			}
		}else if(amt==HDZERK_COOLOFF){
			hdp.A_StartSound(hdp.painsound,CHAN_VOICE);
			if(!random(0,4))hdp.aggravateddamage+=random(1,3);
		}else if(amt>0){
			if(
				!countinv("HDStim")
				||!(level.time&(1|2|4))
			){
				if(hdp.stunned<40)hdp.stunned+=3;
				if(hdp.fatigue<HDCONST_SPRINTFATIGUE)hdp.fatigue++;
			}
		}

	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;

		double ret=(amount-HDZERK_COOLOFF);
		bool iszerk=ret>0;
		if(iszerk)ret*=3./HDZERK_DURATION;
		else ret=-ret*1./HDZERK_COOLOFF-1.;

		//fatigue eventually overrides zerk
		if(hdp.fatigue>HDCONST_DAMAGEFATIGUE*1.4)
			hdp.damagemobj(self,hdp,hdp.beatmax+4,"internal");

		if(iszerk){
			hdp.beatmax=clamp(hdp.beatmax,4,14);

			if(!(hdp.beatcount%12)){
				//twitchy
				if(!hdp.countinv("IsMoving")){
					if(hdp.floorz>=hdp.pos.z)
						hdp.A_ChangeVelocity(frandom(-2,3),frandom(-2,2),1,CVF_RELATIVE);

					if(!(hdp.player.cmd.buttons&BT_ATTACK))
						hdp.muzzledrift+=(random(-14,14),random(-24,14));
					else hdp.muzzledrift+=(frandom(-2,2),frandom(-3,2));

					if(!random(0,2)){
						sound yell=hdp.tauntsound;
						int stupid=random(1,100);
						if(stupid<30)yell=hdp.gruntsound;
						else if(stupid<50)yell=hdp.painsound;
						else if(stupid<70)yell=hdp.deathsound;
						else if(stupid<90)yell=hdp.xdeathsound;
						else{
							A_AlertMonsters();
							hdp.bspawnsoundsource=true;
						}
						hdp.A_StartSound(yell,CHAN_VOICE);
					}
				}
			}
		}else if(amount>0){
			if(hdp.beatcap>HDCONST_MINHEARTTICS+random(1,70+countinv("HDStim")))hdp.beatcap--;
		}

		if(hd_debug>=4)console.printf("ZERK "..amount.."/"..HDZERK_MAX.."  = "..ret);
	}
}





class BluePotion:hdinjectormaker{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Healing Potion"
		//$Sprite "BON1A0"

		hdmagammo.mustshowinmagmanager true;
		inventory.pickupmessage "Picked up a health potion.";
		inventory.pickupsound "potion/swish";
		inventory.icon "BON1A0";
		scale 0.3;
		tag "healing potion";
		hdmagammo.maxperunit HDBLU_BOTTLE;
		hdmagammo.magbulk ENC_BLUEPOTION*0.7;
		hdmagammo.roundbulk ENC_BLUEPOTION*0.04;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDBlueBottler";
	}
	override string,string,name,double getmagsprite(int thismagamt){
		return "BON1A0","TNT1A0","BluePotion",0.3;
	}
	override int getsbarnum(int flags){return mags.size()?mags[0]:0;}
	override bool Extract(){return false;}
	override bool Insert(){
		if(amount<2)return false;
		int lowindex=mags.size()-1;
		if(
			mags[lowindex]>=maxperunit
			||mags[0]<1
		)return false;
		mags[0]--;
		mags[lowindex]++;
		owner.A_StartSound("potion/swish",8);
		if(mags[0]<1){
			mags.delete(0);
			amount--;
			owner.A_StartSound("potion/open",CHAN_WEAPON);
			actor a=owner.spawn("SpentBottle",owner.pos+(0,0,owner.height-4),ALLOW_REPLACE);
			a.angle=owner.angle+2;a.vel=owner.vel;a.A_ChangeVelocity(3,1,4,CVF_RELATIVE);
			a=owner.spawn("SpentCork",owner.pos+(0,0,owner.height-4),ALLOW_REPLACE);
			a.angle=owner.angle+3;a.vel=owner.vel;a.A_ChangeVelocity(5,3,4,CVF_RELATIVE);
		}
		return true;
	}
	states{
	use:
		TNT1 A 0 A_JumpIf(
			player.cmd.buttons&BT_USE
			&&(
				!findinventory("hdbluebottler")
				||!hdbluebottler(findinventory("hdbluebottler")).bweaponbusy
			)
		,1);
		goto super::use;
	cycle:
		TNT1 A 0{
			invoker.syncamount();
			int firstbak=invoker.mags[0];
			int limamt=invoker.amount-1;
			for(int i=0;i<limamt;i++){
				invoker.mags[i]=invoker.mags[i+1];
			}
			invoker.mags[limamt]=firstbak;
			A_StartSound("potion/swish",CHAN_WEAPON,CHANF_OVERLAP,0.5);
			A_StartSound("weapons/pocket",9,volume:0.3);
		}fail;
	spawn:
		BON1 ABCDCB 2 light("HEALTHPOTION") A_SetTics(random(1,3));
		loop;
	}
}
class HDBlueBottler:HDWoundFixer{
	default{
		weapon.selectionorder 1000;
		hdwoundfixer.injectoricon "BON1A0";
		hdwoundfixer.injectortype "BluePotion";
		tag "healing potion";
	}
	override string,double getpickupsprite(){return "BON1A0",1.;}
	override string gethelptext(){
		return WEPHELP_FIRE.."  Drink\n"
		..WEPHELP_USE.." + "..WEPHELP_USE.."(item)  Cycle"
		;
	}
	override inventory CreateTossable(int amt){
		owner.A_DropInventory("BluePotion",amt);
		if(!owner.countinv("BluePotion"))destroy();
		return null;
	}
	states{
	spawn:
		TNT1 A 1;
		stop;
	select:
		TNT1 A 0{
			if(!countinv("BluePotion")){
				if(getcvar("hd_helptext"))A_WeaponMessage("No potion.");
				A_SelectWeapon("HDFist");
			}else if(getcvar("hd_helptext"))A_WeaponMessage("\ct\(\(\( \cnPOTION \ct\)\)\)\c-\n\n\nNot made\nby human hands.\n\nBeware.");
			A_StartSound("potion/swish",8,CHANF_OVERLAP);
		}
		goto super::select;
	deselecthold:
		TNT1 A 1;
		TNT1 A 0 A_Refire("deselecthold");
		TNT1 A 0{
			A_SelectWeapon("HDFist");
			A_WeaponReady(WRF_NOFIRE);
		}goto nope;
	fire:
		TNT1 A 0{
			if(!countinv("BluePotion")){
				if(getcvar("hd_helptext"))A_WeaponMessage("No potion.");
				A_Refire("deselecthold");
			}else{
				let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
				if(blockinv){
					if(getcvar("hd_helptext"))A_WeaponMessage("Take off your "..blockinv.gettag().." first!",2);
					A_Refire("nope");
				}
			}
		}
		TNT1 A 4 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 1{
			A_StartSound("potion/open",CHAN_WEAPON);
			A_Refire();
		}
		TNT1 A 0 A_StartSound("potion/swish",8);
		goto nope;
	hold:
		TNT1 A 1;
		TNT1 A 0{
			A_WeaponBusy();
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
			if(!countinv("BluePotion")){
				if(getcvar("hd_helptext"))A_WeaponMessage("No potion.");
				A_Refire("deselecthold");
			}else if(blockinv){
				if(getcvar("hd_helptext"))A_WeaponMessage("Take off your "..blockinv.gettag().." first!",2);
				A_Refire("nope");
			}else if(pitch>-55){
				A_MuzzleClimb(0,-8);
				A_Refire();
			}else{
				A_Refire("inject");
			}
		}
		TNT1 A 0 A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
		goto nope;
	inject:
		TNT1 A 7{
			let bp=BluePotion(findinventory("BluePotion"));
			if(!bp.mags.size()||bp.mags[0]<1){
				setweaponstate("injectend");
				return;
			}
			bp.mags[0]--;
			A_MuzzleClimb(0,-2);
			A_StartSound("potion/chug",CHAN_VOICE);
			let onr=HDPlayerPawn(self);
			if(onr)onr.A_GiveInventory("HDBlues",HDBLU_MOUTH);
		}
		TNT1 AAAAA 1 A_MuzzleClimb(0,0.5);
		TNT1 A 5 A_JumpIf(!pressingfire(),"injectend");
		goto hold;
	injectend:
		TNT1 A 6;
		TNT1 A 0{
			let bp=BluePotion(findinventory("BluePotion"));
			if(!bp){setweaponstate("nope");return;}
			if(bp.mags.size()&&bp.mags[0]>0){
				A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
				setweaponstate("nope");
				return;
			}
			bp.mags.delete(0);
			bp.amount--;
			A_StartSound("potion/open",8);
			actor a=spawn("SpentBottle",pos+(0,0,height-4),ALLOW_REPLACE);
			a.angle=angle+2;a.vel=vel;a.A_ChangeVelocity(3,1,4,CVF_RELATIVE);
			a=spawn("SpentCork",pos+(0,0,height-4),ALLOW_REPLACE);
			a.angle=angle+3;a.vel=vel;a.A_ChangeVelocity(5,3,4,CVF_RELATIVE);
		}
	injectedhold:
		TNT1 A 1 A_ClearRefire();
		TNT1 A 0 A_JumpIf(pressingfire(),"injectedhold");
		TNT1 A 10 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		goto readyend;
	}
}
class HDBlues:HDDrug{
	override void doeffect(){
		let hdp=hdplayerpawn(owner);

		double ret=min(0.1,amount*0.006);
		if(hdp.strength<1.+ret)hdp.strength+=0.003;
	}
	override void pretravelled(){
		let hdp=hdplayerpawn(owner);

		int toheal=min(
			amount,
			hdp.woundcount+hdp.unstablewoundcount,hdp.bloodloss/12
		);
		if(toheal>0){
			int wc=min(hdp.woundcount,toheal);
			hdp.woundcount-=wc;
			toheal-=wc;
			if(toheal>0){
				wc=min(hdp.unstablewoundcount,toheal);
				hdp.unstablewoundcount-=wc;
				toheal-=wc;
			}
			if(toheal>0){
				wc=min(hdp.bloodloss,toheal*12);
				hdp.bloodloss-=wc;
				toheal-=wc/12;
			}
		}

		int tohealbig=min(
			amount/12,
			max(hdp.oldwoundcount,hdp.burncount,hdp.aggravateddamage)
		);
		if(tohealbig>0){
			hdp.oldwoundcount=max(0,hdp.oldwoundcount-tohealbig);
			hdp.burncount=max(0,hdp.burncount-tohealbig);
			hdp.aggravateddamage=max(0,hdp.aggravateddamage-tohealbig);
		}

		amount=max(0,amount-max(toheal,tohealbig*12));
	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;

		if(hdp.beatcap<HDCONST_MINHEARTTICS){
			hdp.beatcap=max(hdp.beatcap,HDCONST_MINHEARTTICS+5);
			if(!random(0,99))amount--;
		}
		if(hdp.countinv("HDStim")){
			hdp.A_TakeInventory("HDStim",4);
			amount--;
		}
		if(hdp.bloodloss>0)hdp.bloodloss-=12;

		//heal shorter-term damage
		if(
			hdp.unstablewoundcount>0
			||hdp.woundcount>0
		){
			if(hdp.woundcount>0)hdp.woundcount--;else hdp.unstablewoundcount--;
			amount--;
		}

		if(hdp.beatcounter%12==0){
			//heal long-term damage
			if(
				hdp.oldwoundcount>0
				||hdp.burncount>0
				||hdp.aggravateddamage>0
			){
				hdp.oldwoundcount--;
				hdp.burncount--;
				hdp.aggravateddamage--;
				amount--;
			}

			if(
				hdp.beatcounter%60==0
				&&!random(0,7)
			){
				hdp.A_Log("You feel power coming out of you.",true);
				amount-=20;
				hdp.incaptimer=min(0,hdp.incaptimer);
				hdp.stunned=20;
				plantbit.spawnplants(hdp,33,144);
				switch(random(0,3)){
				case 0:
					blockthingsiterator rezz=blockthingsiterator.create(hdp,512);
					while(rezz.next()){
						actor rezzz=rezz.thing;
						if(
							hdp.canresurrect(rezzz,false)
							&&!rezzz.bboss
							&&rezzz.spawnhealth()<400
						){
							hdp.RaiseActor(rezzz,RF_NOCHECKPOSITION);
							rezzz.A_SetFriendly(true);
							rezzz.master=self;
							plantbit.spawnplants(rezzz,12,33);
							amount--;
							if(!random(0,2))break;
						}
					}
					break;
				case 1:
					blockthingsiterator fffren=
						blockthingsiterator.create(hdp,512);
					while(fffren.next()){
						actor ffffren=fffren.thing;
						if(
							ffffren.bismonster
							&&!ffffren.bfriendly
							&&!ffffren.bboss
							&&ffffren.health>0
							&&ffffren.spawnhealth()<400
						){
							ffffren.A_SetFriendly(true);
							if(hdmobbase(ffffren))
								hdmobbase(ffffren).A_Vocalize(ffffren.painsound);
								else ffffren.A_StartSound(ffffren.painsound,CHAN_VOICE);
							plantbit.spawnplants(ffffren,1,0);
							amount-=2;
							if(!random(0,3))break;
						}
					}
					break;
				default:
					hdp.aggravateddamage-=20;
					hdp.woundcount-=20;
					hdp.burncount-=20;

					blockthingsiterator healit=
						blockthingsiterator.create(hdp,1024);
					while(healit.next()){
						actor healthis=healit.thing;
						if(
							healthis.bshootable
							&&!healthis.bcorpse
							&&healthis.health>0
							&&healthis.health<healthis.spawnhealth()
						){
							healthis.GiveBody(512);
						}
					}

					if(!random(0,3))spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					break;
				}
			}
		}

		if(hd_debug>=4)console.printf("BLUE "..amount.."  = "..hdp.strength);
	}
}




