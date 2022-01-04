// ------------------------------------------------------------
// Because sometimes, things get caught in map geometry.
// ------------------------------------------------------------
class SectorDamageCounter:IdleDummy{
	double counter;
	override void tick(){
		super.tick();
		if(!isfrozen()&&accuracy>0)accuracy--;
	}
}
class doordestroyer:hdactor{
	vector2 v1pos;
	vector2 v2pos;
	vector2 vfrac;
	double llength;
	int llit;
	double bottom;
	double top;
	override void postbeginplay(){
		super.postbeginplay();
		vector2 vvv=(v2pos-v1pos);
		llit=int(max(1,llength/10)); //see chunkspeed
		vfrac=vvv/llit;
	}
	enum doorbusternums{
		SECTORDAMAGE_TID=4440,
	}
	void DoorChunk(class<actor>chunktype,int numpercolumn=1,double chunkspeed=10){
		chunkspeed*=0.1; //see vfrac
		for(int i=0;i<llit;i++){
			for(int j=0;j<numpercolumn;j++){
				actor aaa=spawn(chunktype,(
					(v1pos+vfrac*i)+(frandom(-vfrac.x,vfrac.x),frandom(-vfrac.y,vfrac.y)),
					frandom(bottom,top)
				),ALLOW_REPLACE);
				aaa.vel.xy=rotatevector(
						vfrac,randompick(90,-90)+frandom(-60,60)
					)*chunkspeed*frandom(0.4,1.4);
				aaa.vel.z=frandom(-6,12);
			}
			spawn("HDSmoke",(
				(v1pos+vfrac*i),
				bottom+frandom(1,32)
			),ALLOW_REPLACE);
		}
	}
	states{
	spawn:
		TNT1 A 0;
		TNT1 A 0 DoorChunk("HDExplosion",1,3);
		TNT1 AAA 1 DoorChunk("MegaWallChunk",7,15);
		TNT1 A 0 DoorChunk("HDExplosion",1,3);
		TNT1 A 0 DoorChunk("HDSmokeChunk",random(0,3),7);
		TNT1 AAAA 2 DoorChunk("HugeWallChunk",12);
		stop;
	}
	static const int doorspecials[]={
		//from https://github.com/coelckers/gzdoom/blob/master/src/p_lnspec.cpp#L3432
		//only affects raising doors, not lowering platforms designed to function as doors

		//these are all arg0
		10,11,12,13,14,
		105,106,194,195,198,
		202,
		249,252,262,263,265,266,268,274
	};
	static bool checkdoorspecial(int linespecial){
		int dlsl=doordestroyer.doorspecials.size();
		for(int i=0;i<dlsl;i++){
			if(linespecial==doordestroyer.doorspecials[i]){
				return true;
				break;
			}
		}
		return false;
	}
	static bool,double destroydoor(
		actor caller,
		double maxwidth=140,double maxdepth=32,
		double range=0,double ofsz=-1,
		double angle=361,double pitch=99,
		bool dedicated=false
	){
		if(!range)range=max(4,caller.radius*2);
		if(ofsz<0)ofsz=caller.height*0.5;
		if(angle==361)angle=caller.angle;
		if(pitch==99)pitch=caller.pitch;

		flinetracedata dlt;
		caller.linetrace(
			angle,range,pitch,
			flags:TRF_THRUACTORS,
			offsetz:ofsz,data:dlt
		);

		//gross hack because I can't handle whether it's a 3D floor otherwise
		if(!dlt.hitactor){
			caller.lineattack(
				angle,range,pitch,
				int(maxwidth*maxdepth),
				"piercing","CheckPuff",
				flags:LAF_OVERRIDEZ|LAF_NORANDOMPUFFZ|LAF_NOIMPACTDECAL,
				offsetz:ofsz
			);
		}
		if(
			hd_nodoorbuster==1
			||(
				!dedicated
				&&hd_nodoorbuster>1
			)
		)return false,0;

		//figure out if it hit above or below
		//0 top, 1 middle, 2 bottom - same as dlt.linepart
		int whichflat=dlt.hittype==TRACE_HitCeiling?0:dlt.hittype==TRACE_HitFloor?2:1;

		//if hitline, get the sector on the other side
		//otherwise get the floor or ceiling as appropriate
		sector othersector=null;
		if(dlt.hitline){
			othersector=hdmath.oppositesector(dlt.hitline,dlt.hitsector);

			let handler = HDHandlers(EventHandler.Find('HDHandlers'));
			HDPolyObjectInfo polyInfo;

			//polyobjs get special treatment
			if(
				(dlt.hitline.sidedef[0].flags&side.WALLF_POLYOBJ)
				&&(polyInfo = handler.FindPolyByLine(dlt.hitline))
			){
				//mirror tag 0 is ignored by polyobj specials
				if (polyInfo.mirrorTag == 0) polyInfo = handler.polyobjects[0];

				//see if we're going to kill or damage
				vector2 vdif=dlt.hitline.v1.p-dlt.hitline.v2.p;
				double durability=vdif dot vdif;
				double damageinflicted=maxdepth*maxwidth;
				bool blowitup=damageinflicted>frandom(5.,durability);
				if(hd_debug)caller.A_Log(damageinflicted.."   "..durability);

				if(!blowitup){
					if(!random(0,5)){
						actor puf=spawn("PenePuff",dlt.hitlocation-dlt.hitdir*2,ALLOW_REPLACE);
						puf.vel-=dlt.hitdir;
					}
					return false,0;
				}

				//spawn the DD actor for debris only
				for(int i=0;i<3;i++){
					let db=doordestroyer(spawn("doordestroyer",(
						(dlt.hitlocation.xy),caller.floorz
					),ALLOW_REPLACE));
					db.setz(db.floorz);
					db.v1pos=dlt.hitline.v1.p;
					db.v2pos=dlt.hitline.v2.p;
					db.target=caller.target;
					double ddd=dlt.hitline.frontsector.findlowestceilingpoint()
						-dlt.hitline.frontsector.findhighestfloorpoint();
					db.bottom=db.pos.z;
					db.top=db.pos.z+ddd;
				}

				for (int i = 0; i < polyInfo.lines.Size(); i++)
					polyInfo.lines[i].flags |= Line.ML_DONTDRAW;

				let mirrorInfo = polyInfo.GetMirrorPoly();
				if (mirrorInfo)
					for (int i = 0; i < mirrorInfo.lines.Size(); i++)
						mirrorInfo.lines[i].flags |= Line.ML_DONTDRAW;

				HDPolyObjectBlocker blocker;
				let iter = ThinkerIterator.Create('HDPolyObjectBlocker', STAT_DEFAULT);
				//this shouldn't happen, but just in case...
				while (blocker = HDPolyObjectBlocker(iter.Next())) {
					if (
						blocker.polyInfo == polyInfo ||
						blocker.mirrorInfo == polyInfo
					) blocker.Destroy();
				}

				//move the polyobjects and don't let them move again
				HDPolyObjectBlocker.Create(polyInfo);

				return true,1;
			}

			//figure out if it hit above or below: 0 top, 1 middle, 2 bottom
			if(dlt.linepart==1)return false,0;
			else if(dlt.linepart==2)whichflat=2;
			else if(dlt.linepart==0)whichflat=0;
		}else{
			if(whichflat!=1)othersector=dlt.hitsector;
			//check if it's actually sticking out - don't constantly drop it below grade
			vertex gbg;
			double competinglevel;
			if(whichflat==2){
				[competinglevel,gbg]=othersector.findhighestfloorsurrounding();
				double ownheight=othersector.findhighestfloorpoint();
				if(ownheight-competinglevel<=0)return false;
			}else if(whichflat==0){
				[competinglevel,gbg]=othersector.findlowestceilingsurrounding();
				double ownheight=othersector.findlowestceilingpoint();
				if(ownheight-competinglevel>=0)return false;
			}
		}
		if(!othersector)return false,0;

		//see if there are at least 2 2-sided lines
		int num2sided=0;
		for(int i=0;i<othersector.lines.size();i++){
			if(othersector.lines[i].sidedef[1]){
				num2sided++;
			}
		}if(num2sided<2)return false,0;


		//see how big the sector is
		vector2 centerspot=othersector.centerspot;
		int othersectorlinecount=othersector.lines.size();
		vector2 maxradco=(0,0);
		for(int i=0;i<othersectorlinecount;i++){
			double xdif=abs(othersector.lines[i].v1.p.x-centerspot.x);
			if(xdif>maxradco.x)maxradco.x=xdif;
			double ydif=abs(othersector.lines[i].v1.p.y-centerspot.y);
			if(ydif>maxradco.y)maxradco.y=ydif;
		}
		double maxradius=(maxradco.x+maxradco.y)*0.5;

		//abort if this would suddenly completely alter the level in stupid ways
		if(max(maxradco.x,maxradco.y)>1024){
			//some arbitrary feedback
			if(dedicated)DistantQuaker.Quake(caller,4,30,512,30);
			return false,0;
		}


		double damageinflicted=maxdepth*frandom(5,8)/maxradius;
		if(maxradius*2.>maxwidth)damageinflicted/=max(1.,maxradius-(0.5*maxwidth));


		//damage bonus if you can blast right through that spot
		//adjusted for angle to centre because the corner trick is just a bit OP
		double angletomiddle=atan2(centerspot.y-caller.pos.y,centerspot.x-caller.pos.x);
		double depthchecklength=maxdepth*(1.-absangle(caller.angle,angletomiddle)*(1./180.));
		vector2 depthcheck=dlt.hitdir.xy*depthchecklength*frandom(0.8,1.2);
		if(othersector!=level.pointinsector(dlt.hitlocation.xy+depthcheck))damageinflicted*=2.;


		//the first point within the othersector is used a few times
		vector2 justoverthere=dlt.hitlocation.xy+dlt.hitdir.xy;


		//add to damage
		//look for an existing damage counter and create one if none found
		actor buttesec=null;
		sectordamagecounter buttecracked=null;
		int checktid=SECTORDAMAGE_TID+othersector.index();
		actoriterator buttesecs=level.createactoriterator(checktid,"SectorDamageCounter");
		while(buttesec=buttesecs.next()){
			if(buttesec.cursector==othersector){
				buttecracked=sectordamagecounter(buttesec);
				break;
			}
		}
		if(!buttecracked){
			buttecracked=sectordamagecounter(
				spawn("SectorDamageCounter",(justoverthere,dlt.hitlocation.z),ALLOW_REPLACE)
			);
			buttecracked.changetid(checktid);
			buttecracked.counter=0;
		}


		//see if we're going to kill or damage
		bool blowitup=false;
		if(buttecracked.counter+damageinflicted>2.)blowitup=true;
		else if(
			damageinflicted>(buttecracked.accuracy>0?0.02:0.1)  //must deal at least x% damage to count
		){
			buttecracked.counter+=damageinflicted*0.1;
			if(buttecracked.counter>1.)blowitup=true;
		}
		buttecracked.accuracy=3;

		if(hd_debug)caller.A_Log("Sector damage factor:  "..buttecracked.counter);
		double damagesofar=buttecracked.counter;


		if(!blowitup){
			if(!random(0,5)){
				actor puf=spawn("PenePuff",dlt.hitlocation-dlt.hitdir*2,ALLOW_REPLACE);
				puf.vel-=dlt.hitdir;
			}
			return false,damagesofar;
		}



		//and now to blow that shit up...



		if(buttecracked)buttecracked.destroy();

		//determine size and location of destruction
		double doorwidth=maxradius*2.;
		double holeheight=max(//clamp(
			frandom(7,12)*maxwidth/maxradius,
			frandom(4,12)
		);
		double blockpoint=caller.pos.z;

		//move the floor or ceiling as appropriate
		bool floornotdoor=whichflat==2; //may revise this later
		othersector.flags|=sector.SECF_SILENTMOVE;
		if(floornotdoor){
			//delete move thinker
			if(othersector.floordata) othersector.floordata.destroy();

			double lowestsurrounding=othersector.findlowestfloorsurrounding();
			double justoverthereheight=othersector.floorplane.zatpoint(justoverthere);
			blockpoint=min(
				justoverthereheight,
				max(
					dlt.hitlocation.z-holeheight,
					lowestsurrounding-frandom(-4,3)
				)
			);
			holeheight=justoverthereheight-blockpoint;

			//move the plane now
			level.CreateFloor(othersector,Floor.floorLowerByValue,null,65536.,holeheight);
			othersector.floordata.tick();

			//don't let it move again
			level.CreateFloor(othersector,Floor.floorRaiseByValue,null,0.,1);
		}else{
			//delete move thinker
			if(othersector.ceilingdata) othersector.ceilingdata.destroy();

			double lowestsurrounding=othersector.findlowestceilingsurrounding();
			double justoverthereheight=othersector.ceilingplane.zatpoint(justoverthere);
			blockpoint=max(
				justoverthereheight,
				min(
					dlt.hitlocation.z+holeheight,
					lowestsurrounding+frandom(-3,2)
				)
			);
			holeheight=justoverthereheight-blockpoint;

			//move the plane now
			level.CreateCeiling(othersector,Ceiling.ceilRaiseByValue,null,65536.,0.,-holeheight);
			othersector.ceilingdata.tick();

			//don't let it move again
			level.CreateCeiling(othersector,Ceiling.ceilLowerByValue,null,0.,0.,1);
		}

		if(!holeheight)return false,damagesofar;

		//replace some textures
		textureid shwal=texman.checkfortexture("ASHWALL2",texman.type_any);
		if(int(shwal)<1)
			shwal=texman.checkfortexture("ASHWALL",texman.type_any);
		othersector.settexture(floornotdoor?sector.floor:sector.ceiling,shwal,true);
		for(int i=0;i<othersector.lines.size();i++){
			//press the phantom switch with your mind.
			//do not merely exit the level. TRANSCEND it
			let lspecial=othersector.lines[i].special;
			if(
				lspecial!=Exit_Normal
				&&lspecial!=Exit_Secret
				&&lspecial!=Teleport_NewMap
				&&lspecial!=Teleport_EndGame
			)othersector.lines[i].special=0;
			for(int j=0;j<2;j++){
				side sdd=othersector.lines[i].sidedef[j];
				if(sdd){
					int notmid=floornotdoor?side.bottom:side.top;
					if(int(sdd.gettexture(notmid))<1)sdd.settexture(notmid,shwal);
					if(!floornotdoor){
						sdd.settextureyoffset(side.mid,
							sdd.gettextureyoffset(side.mid)+holeheight
						);
						sdd.settextureyoffset(side.top,
							sdd.gettextureyoffset(side.top)+holeheight
						);
					}else{
						sdd.settextureyoffset(side.bottom,
							sdd.gettextureyoffset(side.bottom)+holeheight
						);
					}
				}
			}
		}

		//spawn the DD actor, which blocks the descent of any actual door and spams debris
		let db=doordestroyer(spawn("doordestroyer",(
			(justoverthere+dlt.hitdir.xy),blockpoint
		),ALLOW_REPLACE));
		db.setz(blockpoint);
		if(dlt.hitline){
			db.v1pos=dlt.hitline.v1.p;
			db.v2pos=dlt.hitline.v2.p;
		}else{
			db.v1pos=justoverthere+rotatevector((maxradius,0),angle-90);
			db.v1pos=justoverthere+rotatevector((maxradius,0),angle+90);
		}
		db.target=caller.target;
		if(floornotdoor){
			db.top=db.floorz+holeheight;
			db.bottom=db.floorz;
		}else{
			db.bottom=blockpoint-holeheight;
			db.top=blockpoint;
		}

		//explode
		db.llength=doorwidth;
		if(
			(
				!dedicated
				&&!hdbulletactor(caller)
			)
			&&!hdplayerpawn(caller)
		)hdactor.HDBlast(caller,
			pushradius:doorwidth,pushamount:24,
			fragradius:doorwidth*2,fragtype:"HDB_scrapDB",
			immolateradius:doorwidth,
			immolateamount:random(10,30),
			immolatechance:12
		);
		return true,1.;
	}
}

class HDPolyObjectBlocker : Thinker {
	HDPolyObjectInfo mirrorInfo;
	HDPolyObjectInfo polyInfo;

	const targetX = 32000;
	const targetY = 32000;

	static HDPolyObjectBlocker Create(HDPolyObjectInfo polyInfo) {
		let this = new('HDPolyObjectBlocker');
		//tick after polyaction
		this.ChangeStatNum(STAT_SECTOREFFECT);

		this.polyInfo = polyInfo;
		this.mirrorInfo = polyInfo.GetMirrorPoly();
		this.MovePoly();

		return this;
	}

	void MovePoly() {
		//destroy the current polyaction thinker
		Level.ExecuteSpecial(Polyobj_Stop, null, null, false, polyInfo.tag);
		if (mirrorInfo) Level.ExecuteSpecial(Polyobj_Stop, null, null, false, polyInfo.mirrorTag);

		//move the polyobject
		let distance = ((targetX, targetY) - polyInfo.GetPos()).Length();
		Level.ExecuteSpecial(Polyobj_MoveTo, null, null, false, polyInfo.tag, int(distance * 8), targetX, targetY);
	}

	override void Tick() {
		if (((targetX, targetY) - polyInfo.GetPos()).Length() > .1) MovePoly();
	}
}



// ------------------------------------------------------------
// It's called a "D.B." because it lets you edit the map.
// ------------------------------------------------------------
class DoorBuster:HDPickup{
	int botid;
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Door Buster"
		//$Sprite "BGRNA3A7"

		+inventory.invbar
		hdpickup.bulk ENC_DOORBUSTER;
		hdpickup.refid HDLD_DOORBUS;
		tag "door buster";
		inventory.pickupmessage "Picked up a Door Buster.";
		inventory.icon "BGRNA3A7";
		scale 0.6;
	}
	override int getsbarnum(int flags){return botid;}
	action void A_PlantDB(){
		if(invoker.amount<1){
			invoker.destroy();return;
		}
		flinetracedata dlt;
		linetrace(
			angle,48,pitch,flags:TRF_THRUACTORS,
			offsetz:height-9,
			data:dlt
		);
		if(!dlt.hitline){
			A_Log(string.format("Find a wall to stick the DoorBuster on."),true);
			return;
		}
		vector3 plantspot=dlt.hitlocation-dlt.hitdir*3;
		let ddd=DoorBusterPlanted(spawn("DoorBusterPlanted",plantspot,ALLOW_REPLACE));
		if(!ddd){
			A_Log("Can't deploy here.",true);
			return;
		}
		ddd.botid=invoker.botid;
		ddd.ChangeTid(HDDB_TID);
		ddd.A_StartSound("doorbuster/stick",CHAN_BODY);
		ddd.stuckline=dlt.hitline;
		ddd.translation=translation;
		ddd.master=self;
		ddd.detonating=false;

		let delta=dlt.hitline.delta;
		if(dlt.lineside==line.back)delta=-delta;
		ddd.angle=VectorAngle(-delta.y,delta.x);

		if(!dlt.hitline.backsector){
			ddd.stuckheight=ddd.pos.z;
			ddd.stucktier=0;
		}else{
			sector othersector=hdmath.oppositesector(dlt.hitline,dlt.hitsector);
			ddd.stuckpoint=plantspot.xy;
			double stuckceilingz=othersector.ceilingplane.zatpoint(ddd.stuckpoint);
			double stuckfloorz=othersector.floorplane.zatpoint(ddd.stuckpoint);
			ddd.stuckbacksector=othersector;
			double dpz=ddd.pos.z;
			if(dpz-ddd.height>stuckceilingz){
				ddd.stuckheight=dpz-ddd.height-stuckceilingz;
				ddd.stucktier=1;
			}else if(dpz<stuckfloorz){
				ddd.stuckheight=dpz-stuckfloorz;
				ddd.stucktier=-1;
			}else{
				ddd.stuckheight=ddd.pos.z;
				ddd.stucktier=0;
			}
		}
		string feedback=string.format("DoorBuster planted with tag \cy%i",ddd.botid);
		if(cvar.getcvar("hd_helptext",player).getbool()) feedback.appendformat(string.format("\cj. Use \cddb 999 \cy%i\cj to detonate.",ddd.botid));
		A_Log(feedback,true);
		invoker.amount--;
		if(invoker.amount<1)invoker.destroy();
	}
	states{
	spawn:
		BGRN A -1;
		stop;
	use:
		TNT1 A 0 A_PlantDB();
		fail;
	}
}
class DoorBusterPlanted:HDUPK{
	int botid;
	line stuckline;
	sector stuckbacksector;
	double stuckheight;
	int stucktier;
	vector2 stuckpoint;
	bool detonating;
	default{
		+nogravity
		height 4;radius 3;
		scale 0.6;
	}
	override bool OnGrab(actor grabber){
		actor dbbb=spawn("DoorBuster",pos,ALLOW_REPLACE);
		dbbb.translation=self.translation;
		GrabThinker.Grab(grabber,dbbb);
		destroy();
		return false;
	}
	void A_DBStuck(){
		if(
			!stuckline
			||ceilingz<pos.z+height
			||floorz>pos.z
			||(
				stucktier==1
				&&stuckbacksector.ceilingplane.zatpoint(stuckpoint)+stuckheight+height>ceilingz
			)
			||(
				stucktier==-1
				&&stuckbacksector.floorplane.zatpoint(stuckpoint)+stuckheight<floorz
			)
		){
			if(!stuckline)setstatelabel("death");
			else setstatelabel("unstucknow");
			stuckline=null;
			return;
		}
		setz(
			stucktier==1?stuckbacksector.ceilingplane.zatpoint(stuckpoint)+stuckheight:
			stucktier==-1?stuckbacksector.floorplane.zatpoint(stuckpoint)+stuckheight:
			stuckheight
		);
	}
	states{
	spawn:
		BGRN A 1 A_DBStuck();
		loop;
	unstucknow:
		---- A 2 A_StartSound("misc/fragknock",CHAN_BODY,CHANF_OVERLAP);
		---- A 1{
			actor dbs=spawn("DoorBuster",pos,ALLOW_REPLACE);
			dbs.angle=angle;dbs.translation=translation;
			dbs.A_ChangeVelocity(1,0,0,CVF_RELATIVE);
			A_SpawnChunks("BigWallChunk",15);
			A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP);
		}
		stop;
	death:
		---- A 2 A_StartSound("misc/fragknock",CHAN_BODY,CHANF_OVERLAP);
		---- A 1{
			bnointeraction=true;
			int boost=min(accuracy*accuracy,256);
			bool busted=doordestroyer.destroydoor(self,140+boost,32+boost,dedicated:true);

			A_SprayDecal(busted?"Scorch":"BrontoScorch",16);

			actor dbs=spawn("DoorBusterFlying",pos,ALLOW_REPLACE);
			dbs.target=target;dbs.angle=angle;dbs.translation=translation;
			if(busted){
				dbs.A_ChangeVelocity(-8,0,frandom(2,3),CVF_RELATIVE);
			}else{
				dbs.A_ChangeVelocity(-20,frandom(-4,4),frandom(-4,4),CVF_RELATIVE);
			}
			A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP);
			A_StartSound("world/explode",CHAN_VOICE,CHANF_OVERLAP);

			target=master;
			A_AlertMonsters();

			A_SpawnChunks("HDExplosion",busted?1:6,0,1);
			if(!busted){
				A_ChangeVelocity(-7,0,1,CVF_RELATIVE);
				A_SpawnChunks("HugeWallChunk",30,1,40);
				DistantQuaker.Quake(self,4,35,512,10);
				A_HDBlast(
					pushradius:256,pushamount:128,fullpushradius:96,
					fragradius:256,fragtype:"HDB_scrapDB"
				);
			}else{
				DistantQuaker.Quake(self,2,35,256,10);
				A_HDBlast(
					pushradius:128,pushamount:64,fullpushradius:16,
					fragradius:128,fragtype:"HDB_scrapDB"
				);
			}
		}
		stop;
	}
}
class DoorBusterFlying:SlowProjectile{
	default{
		mass 400;scale 0.6;
		height 2;radius 2;
	}
	states{
	spawn:
		BGRN A 1 A_SpawnItemEx("HDGunSmokeStill");
		wait;
	death:
		TNT1 A 0 A_SpawnItemEx("DoorBusterSpent",0,0,2,
			frandom(4,8),frandom(-8,8),frandom(-2,8),
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		stop;
	}
}
class DoorBusterSpent:HDDebris{
	default{
		radius 1;height 1;
		+rollsprite +rollcenter
		scale 0.6;
		stamina 100;
	}
	void A_Spin(){
		roll+=20;
	}
	override void Tick(){
		if(stamina>0){
			if(!(stamina%5))A_SpawnItemEx("HDGunSmokeStill",0,0,3,
				frandom(-0.3,0.3),frandom(-0.3,0.3),frandom(2,4)
			);
			stamina--;
		}
		super.Tick();
	}
	states{
	spawn:
		BGRN B 2 A_Spin();
		loop;
	death:
		BGRN B -1;
		stop;
	}
}
extend class HDHandlers{
	void SetDB(hdplayerpawn ppp,int cmd=111,int cmd2=-1){
		//set DB tag number with -#
		//e.g., "db -123" will set tag to 123
		if(cmd<0){
			let dbu=DoorBuster(ppp.findinventory("DoorBuster"));
			if(dbu){
				dbu.botid=-cmd;
				ppp.A_Log(string.format("DoorBuster tag set to  \cy%i",-cmd),true);
			}
			return;
		}
		let dbbb=DoorBuster(ppp.findinventory("DoorBuster"));
		int botid=dbbb?dbbb.botid:1;
		array<doorbusterplanted> detonating;detonating.clear();
		if(cmd!=999&&cmd!=123){
			ppp.A_Log(string.format("DoorBuster Command format:\n\cu db <option> <tag number> \n\cjOptions:\n 999 = DETONATE\n 123 = QUERY\n -n = set tag number\n\cj  tag number on next deployment: \cy%i",botid),true);
		}
		actoriterator it=level.createactoriterator(HDDB_TID,"DoorBusterPlanted");
		actor dbs;
		while(dbs=it.Next()){
			let dbss=DoorBusterPlanted(dbs);
			if(
				dbss.master==ppp&&(
					cmd2<0
					||cmd2==dbss.botid
				)
			){
				if(cmd==999&&!dbss.detonating){
					dbss.bincombat=true;
					dbss.setstatelabel("death");
					ppp.A_Log(
						string.format("DoorBuster detonated at [%i,%i].",
							dbss.pos.x,dbss.pos.y
						),true
					);
					int boost=0;
					for(int i=0;i<detonating.size();i++){
						if(
							detonating[i].master==ppp
							&&detonating[i].stuckbacksector==dbss.stuckbacksector
						)boost++;
					}
					dbss.accuracy+=boost;
					detonating.push(dbss);
				}else if(cmd==123){
					ppp.A_Log(
						string.format("DoorBuster with tag \cy%i at [%i,%i].",
							dbss.botid,dbss.pos.x,dbss.pos.y
						),true
					);
				}
			}
		}
	}
}
enum HDDBConst{
	HDDB_TID=8442,
}
