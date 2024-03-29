// ------------------------------------------------------------
// Setting things on fire
// ------------------------------------------------------------
class ImmunityToFire:InventoryFlag{
	override void attachtoowner(actor user){
		super.attachtoowner(user);
		if(owner){
			actoriterator it=level.createactoriterator(-7677,"HDFire");
			actor fff;
			while(fff=it.next()){
				if(fff.target==owner){
					fff.destroy();
				}
			}
		}
	}
}
class HDFireEnder:InventoryFlag{
	default{
		inventory.maxamount 5;
	}
}
class HDFireDouse:InventoryFlag{
	default{
		inventory.maxamount 20;
	}
	override void DoEffect(){
		if(amount>0)amount--;
	}
}


//how to immolate
extend class HDActor{
	//A_Immolate(tracer,target);
	virtual void A_Immolate(
		actor victim,
		actor perpetrator,
		int duration=0,
		bool requireSight=false
	){
		if(victim&&victim.countinv("ImmunityToFire"))return;

		if (requireSight && victim && perpetrator && !perpetrator.CheckSight(victim, SF_IGNOREVISIBILITY))
		{
			return;
		}

		if(
			!victim
			||(
				perpetrator
				&&perpetrator.bdontharmspecies
				&&perpetrator.getspecies()==victim.getspecies()
			)
		){
			victim=spawn("PersistentDamager",self.pos,ALLOW_REPLACE);
			victim.target=perpetrator;
		}

		actor f=null;
		thinkeriterator fit=thinkeriterator.create("HDFire", STAT_DEFAULT);
		while(f=actor(fit.next(true))){
			if(f.target==victim){
				f.master=perpetrator;
				break;
			}
		}
		if(!f){
			f=victim.spawn("HDFire",victim.pos,ALLOW_REPLACE);
			f.target=victim;f.master=perpetrator;
			f.stamina=0;
		}

		if(duration<1)f.stamina+=random(40,80);
		else f.stamina+=duration;

		if(victim.player){
			f.changetid(-7677);
			victim.player.attacker=perpetrator;
		}
	}
}
//fire actor
class HDFire:IdleDummy{
	double halfrad,minz,maxz,lastheight;
	default{
		+bloodlessimpact
		obituary "%o was burned by %k.";
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(target){
			stamina=target.ApplyDamageFactor("hot",stamina);
			if(target.player || target is "HDPlayerCorpse"){
				changetid(-7677);
				stamina=int(max(1,hd_damagefactor*stamina));
			}
			if(!target.bshootable && stamina>20)stamina=20;
		}
		if(hd_debug)A_Log(string.format("fire duration \ci%i",stamina));
	}
	override void ondestroy(){
		if(PersistentDamager(target))target.destroy();
		super.ondestroy();
	}
	override void Tick(){
		if(isfrozen())return;
		if(accuracy>0){
			accuracy--;
			return;
		}

		if(target&&target.countinv("ImmunityToFire")){
			destroy();return;
		}

		if(!master)master=self;
		if(!target){
			target=spawn("PersistentDamager",self.pos,ALLOW_REPLACE);
			target.target=master;
			if(stamina>20)stamina=20;
		}
		setorigin(target.pos,false);


		if(
			stamina<=0
			||target.countinv("HDFireEnder")
		){
			A_TakeFromTarget("HDFireEnder");
			spawn("HDSmoke",pos,ALLOW_REPLACE);
			destroy();
			return;
		}


		int wlvl=target.waterlevel;
		if(wlvl>1){
			if(wlvl<2)spawn("HDSmoke",pos,ALLOW_REPLACE);
			destroy();
			return;
		}


		target.bspecialfiredamage=false;
		target.bspawnsoundsource=true;

		//check if player
		let tgt=HDPlayerPawn(target);
		if(tgt){
			if(tgt.playercorpse){
				target=tgt.playercorpse;
			}
			A_TakeFromTarget("PowerFrightener");
			HDF.Give(tgt,"IsMoving",4);
			HDWeapon.SetBusy(target);
		}else stamina-=3; //monsters assumed to be trying to douse


		int ds=target.countinv("HDFireDouse");
		if(ds){
			target.A_TakeInventory("HDFireDouse",ds);
			stamina-=ds;
		}
		stamina--;


		accuracy=(clamp(random(3,int(30-stamina*0.1)),2,12));


		//set flame spawn point
		if(lastheight!=target.height){ //poll only height
			halfrad=max(4,target.radius*0.5);
			lastheight=target.height;
			minz=lastheight*0.2;
			maxz=max(lastheight*0.75,4);
		}

		//position and spawn flame
		setorigin(pos+(
				frandom(-halfrad,halfrad),
				frandom(-halfrad,halfrad),
				frandom(minz,maxz)
		),false);
		actor sp=spawn("HDFlameRed",pos,ALLOW_REPLACE);
		sp.vel+=target.vel+(frandom(-2,2),frandom(-2,2),frandom(-1,3));
		A_StartSound("misc/firecrkl",CHAN_BODY,CHANF_OVERLAP,volume:0.4,attenuation:6.);


		//heat up the target
		target.A_GiveInventory("Heat",clamp(stamina,20,random(20,80)));
	}
	states{
	spawn:
		TNT1 A -1;
		stop;
	}
}




//an invisible actor that constantly damages anything it collides with
class PersistentDamager:HDActor{
	vector3 relpos;
	default{
		+noblockmap
		damagetype "hot";

		height 8;radius 8;
		stamina 8;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(master)relpos=self.pos-master.pos;
	}
	int ticker;
	override void tick(){
		if(isfrozen())return;

		if(master)setorigin(master.pos+relpos,false);
		if(ticker<4)ticker++;else{
			ticker=0;
			blockthingsiterator ccw=blockthingsiterator.create(self);
			while(ccw.next()){
				actor ccc=ccw.thing;
				if(
					ccc.bnodamage
					||!ccc.bshootable
					||ccc.pos.z<pos.z-ccc.height
					||!ccc.checksight(self)  //hope this doesn't bog things down too much
				)continue;
				stamina--;
				if(damagetype=="hot")HDF.Give(ccc,"Heat",stamina*10);
				ccc.damagemobj(self,target,stamina,damagetype);
			}
			stamina--;
			if(stamina<1){destroy();return;}
		}

		NextTic();
	}
	states{
	spawn:
		TNT1 A -1;
		stop;
	}
}



//heat tracker

class Heat:Inventory{
	double volume;
	double volumeratio;
	double inversevolumeratio;
	double baseinversevolumeratio;
	double realamount;
	int burnoutthreshold;
	int burnouttimer;
	actor heatfield;
	actor heatlight;
	BarrelExplodeMarker BarrelQueue; // [Ace] Not making a new thinker just for this. It's only used for barrels anyway.
	enum HeatNumbers{
		HEATNUM_DEFAULTVOLUME=12*12*48*4,
	}
	states{spawn:TNT1 A 0;stop;}
	default{
		+inventory.untossable //for some reason this works without it
		+inventory.keepdepleted
		inventory.amount 1;
		inventory.maxamount 9999999;
		obituary "%o was too hot to handle.";
	}
	static double GetAmount(actor heated){
		let htt=Heat(heated.findinventory("Heat"));
		if(!htt)return 0;
		return htt.realamount;
	}
	override void attachtoowner(actor user){
		super.attachtoowner(user);
		volume=(user.radius*user.radius*user.height)*4;
		baseinversevolumeratio=HEATNUM_DEFAULTVOLUME/max(0.000001,volume);
		inversevolumeratio=baseinversevolumeratio;
		volumeratio=1/baseinversevolumeratio;
		burnoutthreshold=max(40,((int(user.mass*(user.radius+user.height))+(user.gibhealth))>>5)+300);
		A_SetSize(owner.radius,owner.height);

		if (owner is 'HDBarrel')
		{
			BarrelQueue = BarrelExplodeMarker.Get();
		}

		if (!BarrelQueue || BarrelQueue.LightCount < HDBarrel.MaxBarrelLights)
		{
			heatlight=HDFireLight(spawn("HDFireLight",pos,ALLOW_REPLACE));
			heatlight.target=owner;hdfirelight(heatlight).heattarget=self;
			if (BarrelQueue)
			{
				BarrelQueue.LightCount++;
			}
		}
	}
	override void DoEffect(){
		if(!owner){destroy();return;}
		if(!owner.player&&isfrozen())return;

		//reset burnout if raised
		if(
			owner.bismonster
			&&!owner.bcorpse
			&&owner.health>=owner.spawnhealth()
		)burnouttimer=0;

		//make adjustments based on player status
		let hdp=hdplayerpawn(owner);
		if(hdp){
			inversevolumeratio=baseinversevolumeratio;
			if(
				hdp.health<1&&
				hdp.playercorpse
			){
				hdp.playercorpse.A_GiveInventory("Heat",1);
				Heat(hdp.playercorpse.findinventory("Heat")).realamount+=realamount;
				destroy();
				return;
			}
		}

		//convert given to real
		if(amount){
			realamount+=amount*inversevolumeratio;
			amount=0;
		}
		//clamp number to zero
		if(realamount<1){
			realamount=0;
			return;
		}
		int ticker=level.time;

		//flame
		if(
			!(ticker%3)
			&&realamount>frandom(100,140)
			&&owner.bshootable
			&&!owner.bnodamage
			&&!owner.countinv("ImmunityToFire")
			&&burnoutthreshold>burnouttimer
		){
			if(owner.bshootable){
				realamount+=frandom(1.2,3.0);
			}
			if(owner.waterlevel<=random(0,1)){
				actor aaa;
				if(
					owner is "PersistentDamager"
					||realamount<600
					||burnouttimer>((burnoutthreshold*7)>>3)
				){
					burnouttimer++;
					aaa=spawn("HDFlameRed",owner.pos+(
						frandom(-radius,radius),
						frandom(-radius,radius),
						frandom(0.1,owner.height*0.6)
					),ALLOW_REPLACE);
					aaa.ReactionTime = BarrelQueue ? BarrelQueue.LightCount : 0;
				}else{
					burnouttimer+=2;
					aaa=spawn("HDFlameRedBig",owner.pos+(
						frandom(-radius,radius)*0.6,
						frandom(-radius,radius)*0.6,
						frandom(5,owner.height*0.2)
					),ALLOW_REPLACE);
					aaa.scale=(randompick(-1,1)*frandom(0.9,1.2),frandom(0.9,1.1))*clamp((realamount-600)*0.0003,0.6,2.);
					aaa.ReactionTime = BarrelQueue ? BarrelQueue.LightCount : 0;
					
					if (heatlight)
					{
						heatlight.args[0]=200;
						heatlight.args[1]=150;
						heatlight.args[2]=90;
						heatlight.args[3]=int(min(realamount*0.1,256));
					}
				}
				aaa.target=owner;
				aaa.A_StartSound("misc/firecrkl",CHAN_BODY,CHANF_OVERLAP,volume:clamp(realamount*0.001,0,0.2));
			}
		}

		//reset timer so charred remains can be reignited
		else if(
			burnouttimer>=burnoutthreshold
			&&realamount<100
		)burnouttimer=random((burnoutthreshold*3)>>2,burnoutthreshold);

		//damage
		if(
			!(ticker%3)
			&&owner.bshootable&&!owner.bnodamage
		){
			double dmgamt=realamount*0.006;
			if(
				dmgamt<1.
				&&(frandom(0.,1.)<dmgamt)
			)dmgamt=1.;
			setxyz(owner.pos);
			owner.damagemobj(self,owner.player?owner.player.attacker:null,int(dmgamt),"hot",DMG_NO_ARMOR|DMG_THRUSTLESS);
			if(!owner){destroy();return;}
		}


		//convection, kinda
		if(ticker>20){
			flinetracedata hlt;
			double aimdist=max(10,realamount*0.01);
			owner.linetrace(
				frandom(0,360),aimdist,frandom(-80,-90),
				offsetz:0,
				data:hlt
			);
			if(
				hlt.hitactor
				&&(
					!hlt.hitactor.findinventory("Heat")
					||heat(hlt.hitactor.findinventory("Heat")).realamount<realamount
				)
			){
				let htt=heat(hlt.hitactor.findinventory("Heat"));
				if(!htt)htt=heat(hlt.hitactor.GiveInventoryType("heat"));
				double distdiff=hlt.distance/aimdist;
				double togive=realamount*(1.-distdiff)*0.01*volume/max(1.,htt.volume);
				if(togive>0){
					htt.realamount+=togive;
					realamount-=togive;
				}
				if(togive>2)hlt.hitactor.damagemobj(self,owner,1,"hot",DMG_THRUSTLESS);
				if(!owner){destroy();return;}
			}
		}


		//cooldown
		double reduce=inversevolumeratio*max(realamount*0.003,1.);
		if(owner.vel dot owner.vel > 4)reduce*=1.6;

		if(owner.waterlevel>2)reduce*=10;
		else if(owner.waterlevel>1)reduce*=4;
		else if(owner.countinv("HDFireDouse"))reduce*=2;

		double aang=absangle(angle,owner.angle);
		if(aang>4.)reduce*=clamp(aang*0.4,1.,4.);
		if((!skill)&&owner.player)reduce*=2;
		realamount-=reduce;
		angle=owner.angle;

//if(owner.player)A_LogFloat(realamount);
	}
}

class HDFireLight:PointLight{
	heat heattarget;
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=200;
		args[1]=150;
		args[2]=100;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!heattarget||!target){destroy();return;}
		if(isfrozen())return;
		setorigin(target.pos,true);
		if(args[3]<1){
			args[0]=0;
			args[1]=0;
			args[2]=0;
			args[3]=0;
		}
		else args[3]=int(frandom(0.9,0.99)*args[3]);
	}
}


