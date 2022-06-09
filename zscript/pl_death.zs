// ------------------------------------------------------------
// Death and corpses
// ------------------------------------------------------------
extend class HDPlayerPawn{
	bool silentdeath;
	states{
	death.bleedout:
	death.invisiblebleedout:
	death.internal:
		---- A 0{
			if(playercorpse)playercorpse.A_StopSound(CHAN_VOICE);
			A_StopSound(CHAN_VOICE);
		}
	death:
	xdeath:
		---- A 50{
			binvisible=true;
			A_NoBlocking();
		}
		---- A 20 A_CheckPlayerDone();
		wait;
	}
	int deathcounter;
	int respawndelay;
	override void DeathThink(){
		if(player.cheats&CF_PREDICTING){
			super.DeathThink();
			return;
		}
		if(player){
			if(
				respawndelay>0
			){
				player.attacker=null;
				player.cmd.buttons&=~BT_USE;
				if(!(level.time&(1|2|4|8|16))){
					switch(CheckPoF()){
					case -1:
						//start losing sequence
						let hhh=hdlivescounter.get();
						if(hhh.endgametypecounter<-35)hhh.startendgameticker(hdlivescounter.HDEND_WIPE);
						break;
					case 1:
						respawndelay--;
						A_Log(player.getusername().." friend wait time: "..respawndelay);
						break;
					default:
						respawndelay=HDCONST_POFDELAY;
						break;
					}
				}
			}else if(hd_pof){
				player.cmd.buttons|=BT_USE;
				let hhh=hdhandlers(eventhandler.find("hdhandlers"));
				hhh.corpsepos[playernumber()]=(pos.xy,floor(pos.z)+0.001*angle);
			}

			if(!player.bot){
				if(deathcounter==144&&!(player.cmd.buttons&BT_USE)){
					showgametip();
					specialtip=specialtip.."\n\n\clPress \cdUse\cl to continue.";
					deathcounter=145;
				}else if(
					deathcounter<144
					&&player
				){
					player.cmd.buttons&=~BT_USE;
					deathcounter++;
				}
				if(playercorpse){
					setorigin((playercorpse.pos.xy+angletovector(angle)*3,playercorpse.pos.z),true);
				}
			}
		}

		if(hd_dropeverythingondeath){
			array<inventory> keys;keys.clear();
			for(inventory item=inv;item!=null;item=item.inv){
				if(item is "Key"){
					keys.push(item);
					item.detachfromowner();
				}else if(item is "HDPickup"||item is "HDWeapon"){
					DropInventory(item);
				}
				if(!item||item.owner!=self)item=inv;
			}
			for(int i=0;i<keys.size();i++){
				keys[i].attachtoowner(self);
			}
		}


		viewbob=0;

		double oldangle=angle;
		double oldpitch=pitch;
		super.DeathThink();

		vel=(0,0,0);
		angle=oldangle;
		pitch=min(oldpitch+1,45);

		if(deathcounter<80)setviewpos((viewpos.offset.xy+0.02*(80-deathcounter)*heightmult*(cos(angle),sin(angle)),0));
	}
	override void Die(actor source,actor inflictor,int dmgflags,name MeansOfDeath){

		//forced delay for respawn to clear all persistent damagers
		//exemption made for suicide
		if(
			(source==self&&health<-50000)
			||(
				!multiplayer&&!level.allowrespawn
			)
		)deathcounter=145;
		else deathcounter=1;

		AddBlackout(256,12,4,24);

		if(hd_pof){
			if(deathmatch){
				cvar.findcvar("hd_pof").setbool(false);
				respawndelay=0;
			}else respawndelay=HDCONST_POFDELAY;
		}else respawndelay=0;


		if(player){
			let www=hdweapon(player.readyweapon);
			if(www)www.OnPlayerDrop();
			if(player.attacker is "HDFire")player.attacker=player.attacker.master;
		}

		if(hd_disintegrator){
			A_SpawnItemEx("Telefog",0,0,0,vel.x,vel.y,vel.z,0,SXF_ABSOLUTEMOMENTUM);
			A_TakeInventory("Heat");
		}else{
			playercorpse=HDPlayerCorpse(spawn("HDPlayerCorpse",pos,ALLOW_REPLACE));
			playercorpse.vel=vel;playercorpse.corpsegiver=self;
			if(player)playercorpse.settag(player.getusername());

			playercorpse.translation=translation;
			ApplyUserSkin(true);
			playercorpse.sprite=sprite;
			playercorpse.standsprite=standsprite;
			playercorpse.scale=skinscale;

			if(
				(!inflictor||!inflictor.bnoextremedeath)
				&&(-health>gibhealth||aggravateddamage>40)
			){
				playercorpse.bodydamage+=max(-health,aggravateddamage<<2);
			}else{
				if(!silentdeath)A_StartSound(deathsound,CHAN_VOICE);
			}

			//transfer heat to corpse
			let htht=Heat(findinventory("Heat"));
			if(htht){
				playercorpse.A_GiveInventory("Heat",1);
				Heat(playercorpse.findinventory("Heat")).realamount+=htht.realamount;
				htht.destroy();
			}

			bsolid=false;
			bshootable=false;
			bnointeraction=true;
		}

		double vheight=height*0.9;

		super.die(source,inflictor,dmgflags,MeansOfDeath);

		player.viewheight=vheight;
	}
	//-1 if tpk
	//0 if not gathered
	//1 if gathered
	int CheckPoF(){
		if(!hd_pof)return 1;
		bool everyonedead=true;
		bool someoneoutside=false;
		for(int i=0;i<MAXPLAYERS;i++){
			if(!playeringame[i])continue;
			let ppp=players[i].mo;
			if(
				ppp
				&&ppp.health>0
			){
				everyonedead=false;
				if(
					!checksight(ppp, SF_IGNOREVISIBILITY)
					||distance3d(ppp)>256
				){
					someoneoutside=true;
					break;
				}
			}
		}
		if(everyonedead)return -1;
		if(someoneoutside)return 0;
		return 1;
	}
	void healthreset(){
		woundcount=0;
		oldwoundcount=0;
		unstablewoundcount=0;
		burncount=0;
		aggravateddamage=0;
		stunned=0;
		bloodloss=0;
	}
}

enum HDPlayerDeath{
	HDCONST_POFDELAY=11,
}



//call the lives counter thinker when someone dies
extend class HDHandlers{
	override void PlayerDied(PlayerEvent e){
		hdlivescounter.playerdied(e.playernumber);
	}
}


//corpse substituter
class HDPlayerCorpse:HDHumanoid{
	hdplayerpawn corpsegiver;
	int standsprite;
	default{
		monster; -countkill +friendly +nopain +activatepcross
		health 100;mass 160;
	}
	override bool CanResurrect(actor other,bool passive){
		if(hd_pof)return false;
		return super.CanResurrect(other,passive);
	}
	override void Tick(){
		super.Tick();
		if(
			hd_pof
			&&(
				!corpsegiver
				||corpsegiver.health>0
			)
		){
			destroy();
			return;
		}
		if(
			corpsegiver
			&&corpsegiver.health>0
			&&!hd_pof
		){
			corpsegiver.playercorpse=null;
			corpsegiver.healthreset();
			corpsegiver.levelreset();
			corpsegiver=null;
		}
		if(
			health>0
			&&!instatesequence(curstate,resolvestate("raise"))
			&&!instatesequence(curstate,resolvestate("ungib"))
		)A_Die();
	}
	states{
	spawn:
		#### AA -1;
		PLAY A 0;
	forcexdeath:
		#### A -1;
	death:
		#### H 10{
			if(
				corpsegiver
				&&corpsegiver.incapacitated>(4<<2)
			)setstatelabel("dead");
		}
		#### IJ 8;
		#### K 3;
	deadfall:
		#### K 2;
		#### LM 4 A_JumpIf(abs(vel.z)>1,"deadfall");
	dead:
		#### M 1; //used for bleeding out
		#### N 2 canraise A_JumpIf(abs(vel.z)>2,"deadfall");
		wait;
	xdeath:
		#### O 5{
			if(corpsegiver)A_StartSound(corpsegiver.gibbedsound,CHAN_BODY,CHANF_OVERLAP);
			else A_XScream();
			scale.x=abs(scale.x);
		}
		#### PQRSTUV 5;
	xdead:
		#### W 10 A_JumpIf(!hd_pof,1);
		wait;
		#### W -1 canraise;
		stop;
	xxxdeath:
		#### O 5;
		#### P 5 A_XScream();
		#### QRSTUV 5;
		goto xdead;
	ungib:
		---- A 0{
			let aaa=HDOperator(spawn("ReallyDeadRifleman",pos));
			RaiseActor(aaa,RF_NOCHECKPOSITION);
			aaa.settag(gettag());
			aaa.angle=angle;
			aaa.translation=translation;
			aaa.master=master;
			aaa.target=target;
			aaa.sprite=standsprite;
			aaa.givensprite=sprite;
			aaa.A_SetFriendly(bfriendly);
			aaa.scale=scale;
			bnotargetswitch=false;
		}
		stop;
	raise:
		#### MLKJIH 5;
		---- A 0{
			let aaa=HDOperator(spawn("UndeadRifleman",pos));
			aaa.settag(gettag());
			aaa.angle=angle;
			aaa.translation=translation;
			aaa.master=master;
			aaa.target=target;
			aaa.sprite=standsprite;
			aaa.givensprite=sprite;
			aaa.A_SetFriendly(bfriendly);
			aaa.scale=scale;
		}
	falldown:
		stop;
	}
}

