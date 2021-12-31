// ------------------------------------------------------------
// The heart
// ------------------------------------------------------------
const HDCONST_MAXBLOODLOSS=4096;
const HDCONST_MINHEARTTICS=5; //35/5*60=420 beats per minute!
extend class HDPlayerPawn{
	int beatcount;
	int beatmax;
	int beatcap;
	int beatcounter;

	int bloodpressure;

	int stimcount;
	int regenblues;
	int secondflesh;
	int zerk;

	actor lastthingthatwoundedyou;

	int woundcount;
	int burncount;
	int unstablewoundcount;
	int oldwoundcount;
	int aggravateddamage;

	int bloodloss;

	double strength;
	double basestrength(){
		double strmult=min(
			hd_maxstrength,
			(hd_strength?clamp(hd_strength.getfloat(),0.2,11.):11.)
		)*(1./11.);
		return max(0.1,(
			0.7
			+healthcap*0.003
			-fatigue*0.001  //intentionally stacks on top of effect on maxhealth
		)*strmult);
	}

	int healthcap;
	int maxhealth(){
		if(regenblues<0)regenblues=0;
		if(woundcount<0)woundcount=0;
		if(oldwoundcount<0)oldwoundcount=0;
		if(unstablewoundcount<0)unstablewoundcount=0;
		if(burncount<0)burncount=0;
		if(aggravateddamage<0)aggravateddamage=0;
		if(stunned<0)stunned=0;
		if(bloodloss<0)bloodloss=0;
		return max(0,100
			+min(0,
				-aggravateddamage
				-burncount
				-oldwoundcount
				-woundcount
				-unstablewoundcount
				-(bloodloss>>6)
			)
			+max(fatigue-HDCONST_SPRINTFATIGUE,0)
		);
	}

	void HeartTicker(double fm,double sm,int input){
		//these will be used repeatedly
		healthcap=maxhealth();
		int ismv=countinv("IsMoving");

		if(deathmatch&&sv_nohealth){
			//force sv_nohealth
			zerk=0;
			stimcount=0;
			regenblues=0;
			secondflesh=0;
			A_TakeInventory("HDZerk");
			A_TakeInventory("HDStim");
			A_TakeInventory("HDBlues");
			A_TakeInventory("SecondFlesh");
		}else{
			//convert to new inventory system
			if(countinv("PowerStrength")){
				A_SetInventory("HDZerk",HDZerk.HDZERK_MAX);
				A_TakeInventory("PowerStrength");
			}
			if(zerk)A_GiveInventory("HDZerk",zerk);
			if(stimcount)A_GiveInventory("HDStim",stimcount);
			if(regenblues)A_GiveInventory("HDBlues",regenblues);
			if(secondflesh)A_GiveInventory("SecondFlesh",secondflesh);
		}
		zerk=0;
		stimcount=0;
		regenblues=0;
		secondflesh=0;



		//strength gravitates back to normal
		double sss=basestrength();
		if(strength>sss)strength=max(sss,strength-0.002);
		else if(strength<sss)strength=min(sss,strength+0.002);



		//on every beat
		if(beatcount>0){
			beatcount--;
			muzzleclimb1.y-=0.0002*bloodpressure;
		}else{
			if(bloodloss&&hd_debug>1)console.printf(gettag().." bled: "..bloodloss);

			muzzleclimb1.y+=0.0002*beatmax*bloodpressure;
			beatmax=min(beatmax,max(1,beatcap-random(0,aggravateddamage>>2)));

			//heartbeat sound
			if(bloodpressure>5||health<30||beatmax<20){
				double bp=0.05*bloodpressure;
				if(beatmax<15||health<30)bp*=2;
				A_StartSound("misc/heart",7778,CHANF_LOCAL,0.05*max(bloodpressure,22-beatmax));
			}

			if(woundcount){
				int dm=(random(10,woundcount)-random(0,bloodpressure))*4/10;
				if(dm>0){
					damagemobj(
						self,lastthingthatwoundedyou,dm,"bleedout",
						DMG_THRUSTLESS
						|(bloodloss>HDCONST_MAXBLOODLOSS?DMG_FORCED:0)
					);
				}
			}

			if(binvulnerable){
				fatigue=0;
				stunned=0;
			}

			//fatigue
			if(fatigue>HDCONST_DAMAGEFATIGUE*1.4){
				damagemobj(self,self,2,"internal");
				stunned=min(10,stunned);
			}

			//enforce health cap
			if(healthcap<health)damagemobj(self,null,1,"maxhpdrain");

			//limit beatmax
			if(beatmax<HDCONST_MINHEARTTICS)beatmax++;
			else if(beatmax>TICRATE)beatmax--;

			if(fatigue>random(0,(bloodloss>>6)))fatigue--;
			if(
				beatmax<HDCONST_MINHEARTTICS+3
				||fatigue>HDCONST_DAMAGEFATIGUE  
			){
				damagemobj(self,null,1,"internal");
				stunned=min(10,stunned);
			}else if(
				health<healthcap
				&&random(1,30)+ismv<beatmax
			){
				givebody(1);
			}

			//reset beatcount
			beatcount=beatmax;
//			if(bloodpressure>3)A_SetBlend("20 12 0f",0.003*min(bloodpressure,100),beatcount);
			beatcounter++;

			//sprinting
			if(
				cansprint
				&&runwalksprint>0
				&&(fm||sm)
			){
				fatigue+=2+max(0,(bloodloss>>6));
				if(
					overloaded>2.
					||(frandom(0,overloaded)>1.)
				)fatigue++;
				if(fatigue>=HDCONST_SPRINTFATIGUE){
					fatigue+=20;
					stunned+=400;
					A_StartSound(painsound,CHAN_VOICE);
				}
				if(!random(0,35))bloodpressure++;
			}

			//blood pressure
			if(bloodpressure>0)bloodpressure--;

			//don't go negatives
			if(stunned<0)stunned=0;
			if(aggravateddamage<0)aggravateddamage=0;
			if(bloodpressure<0)bloodpressure=0;

			if(woundcount<0)woundcount=0;
			if(oldwoundcount<0)oldwoundcount=0;
			if(unstablewoundcount<0)unstablewoundcount=0;
			if(burncount<0)burncount=0;


			//every 4 beats
			int minbeatmax=HDCONST_MINHEARTTICS+random(random(-2,5),5);
			if(beatcounter%4==0){ //==0, !() both 3 characters
				//recovering heart rate
				if(fatigue){
					if(beatmax>minbeatmax){
						beatmax=max(minbeatmax,min(beatmax,35-fatigue));
					}
					if(fatigue>20)stunned=clamp(stunned,stunned+10,fatigue*10);
					if(bloodpressure<fatigue)bloodpressure=fatigue;
				}
				if(beatmax<beatcap)beatmax++;
				if(bloodpressure>0)bloodpressure=max(bloodpressure-1,0);
				if(aggravateddamage>0)bloodpressure+=(random(-aggravateddamage,aggravateddamage)>>1);
			}


			if(beatcounter%20==0){	//every 20 beats
				beatcap=clamp(beatcap+8,1,35);

				//blood starts growing back
				if(bloodloss>0)bloodloss--;

				//updating beatcap (minimum heart rate)
				if(health<40) beatcap=clamp(beatcap,1,24);
				else if(health<60) beatcap=clamp(beatcap,1,32);

				//bandages come undone
				if(unstablewoundcount && countinv("IsMoving")>random(0,12)){
					unstablewoundcount--;
					if(flip)oldwoundcount++;else woundcount++;
				}
				//wounds start settling
				if(!random(0,unstablewoundcount+woundcount)){
					if(unstablewoundcount>0){
						unstablewoundcount--;
						oldwoundcount++;
					}
				}



			}
			if(beatcounter==120){	//every 120 beats
				beatcounter=0;	//reset
				if(random(1,health)>70){
					oldwoundcount--;
					burncount--;
				}
			}


			//too cool to do drugs
			//cool to do drugs
			//to do drugs
			//do drugs
			//drugs
			HDDrug drg=null;
			thinkeriterator drugfinder=thinkeriterator.create("HDDrug");
			while(drg=HDDrug(drugfinder.next())){
				if(drg.owner==self)drg.OnHeartbeat(self);
			}

			//a lot of weapons divide tics by strength, do not let this hit zero!
			strength=max(strength,0.01);
		}

		//spawn shards
		if(
			hd_shardrate>0
			&&level.time>0
			&&!(level.time%hd_shardrate)
		)spawn("BFGNecroShard",pos);
	}
}



