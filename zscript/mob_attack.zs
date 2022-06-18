// ------------------------------------------------------------
// AI stuff related to aiming and targeting.
// ------------------------------------------------------------
extend class HDMobBase{
	void A_LeadTarget(
		double tics,
		bool randomize=true
	){
		if(!target)return;
		if(randomize)tics=frandom(0,tics*1.2);
		let ltp=lasttargetpos+(target.pos-target.prev)*tics;
		double ach=deltaangle(hdmath.angleto(pos.xy,lasttargetpos.xy),hdmath.angleto(pos.xy,ltp.xy));
		double pch=hdmath.pitchto(pos,ltp)-hdmath.pitchto(pos,lasttargetpos);
		angle+=ach;
		pch+=ach;
	}
	void A_FaceLastTargetPos(
		double maxturn=180,
		double attackheight=-1,
		double targetheight=-1
	){
		if(!target)return;
		if(attackheight<0)attackheight=height*0.8;
		if(targetheight<0)targetheight=target.height*0.6;

		double targetpitch=hdmath.pitchto(
			(pos.xy,pos.z+attackheight),
			(lasttargetpos.xy,lasttargetpos.z+targetheight)
		);
		targetpitch-=pitch;
		pitch=clamp(pitch+clamp(targetpitch,-maxturn,maxturn),-90,90);

		double targetangle=hdmath.angleto(pos.xy,lasttargetpos.xy);
		targetangle=deltaangle(angle,targetangle);
		angle+=clamp(targetangle,-maxturn,maxturn);
	}
	void A_TurnToAim(
		double maxturn=180,
		double attackheight=-1,
		double targetheight=-1,
		statelabel shootstate="shoot",
		bool musthaveactualsight=false
	){
		if(!target)return;
		if(attackheight<0)attackheight=height*0.8;
		if(targetheight<0)targetheight=target.height*0.6;

		A_FaceLastTargetPos(maxturn,attackheight,targetheight);

		double targetpitch=hdmath.pitchto(
			(pos.xy,pos.z+attackheight),
			(lasttargetpos.xy,lasttargetpos.z+targetheight)
		);
		double targetangle=hdmath.angleto(pos.xy,lasttargetpos.xy);

		if(
			absangle(angle,targetangle)<1
			&&pitch-targetpitch<1
			&&(
				!musthaveactualsight
				||checksight(target)
			)
		){
			TriggerPullAdjustments();
			setstatelabel(shootstate);
		}
	}


	//returns whether a state was changed
	bool A_Watch(
		double randomturn=5.,
		statelabel seestate="see",
		statelabel missilestate="missile",
		statelabel meleestate="melee"
	){
		if(!target){
			target=lastenemy;
			if(target)OnAlert(seestate);
			else setstatelabel(seestate);
			return true;
		}
		if(CheckTargetInSight()){
			setstatelabel(lasttargetdist<meleerange?meleestate:missilestate);
			return true;
		}
		if(randomturn)angle+=frandom(-randomturn,randomturn);
		return false;
	}
	//points at lasttargetpos, checks for target, fires if no LOS anyway
	void A_Coverfire(
		statelabel shootstate="shoot",
		double randomturn=0
	){
		if(A_Watch(randomturn))return;
		if(frandom(0,1)<0.2){
			TriggerPullAdjustments();
			setstatelabel(shootstate);
		}else if(frandom(0,1)<0.1)setstatelabel("see");
		A_FaceLastTargetPos(10);
	}

	double spread;
	virtual void TriggerPullAdjustments(){
		if(spread){
			angle+=frandom(-spread,spread);
			pitch+=frandom(-spread,spread);
		}
	}
}
