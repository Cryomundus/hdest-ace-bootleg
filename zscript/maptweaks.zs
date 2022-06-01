// ------------------------------------------------------------
// Not a territory but a living document
// ------------------------------------------------------------
const HDCONST_LIFTWAITMULT=5;
class DelayedLineActivator:Thinker{
	int timer;
	int activationtype;
	actor activator;
	line activated;
	static void Init(
		line lll,
		int type,
		actor aaa=null,
		int ttt=1
	){
		DelayedLineActivator dla=null;
		ThinkerIterator finder=ThinkerIterator.Create("DelayedLineActivator");
		while(dla=DelayedLineActivator(finder.Next())){
			if(dla.activated==lll)return;
		}
		dla=new("DelayedLineActivator");
		dla.activator=aaa;
		dla.activated=lll;
		if(ttt<=0)dla.timer=1;
		else dla.timer=ttt;
	}
	override void Tick(){
		if(!timer){
			int ls=activated.special;
			int a0=activated.args[0];
			int a1=activated.args[1];
			int a2=activated.args[2];
			int a3=activated.args[3];
			if(activator)activator.A_CallSpecial(ls,a0,a1,a2,a3);
			destroy();
			return;
		}
		timer--;
	}
}
extend class HDHandlers{

	bool LinePartOfTaggedSector(
		line lll,
		bool trueifany=false
	){
		int largo=lll.args[0];
		if(!largo)return true; //assume it's just using the sector behind it
		int sci=-1;
		let scc=level.CreateSectorTagIterator(largo);
		bool anyfound=false;
		while((sci=scc.Next())>=0){
			sector sss=level.sectors[sci];
			bool isinthissector=false;
			for(int i=0;i<sss.lines.size();i++){
				if(sss.lines[i]==lll){
					isinthissector=true;
					anyfound=true;
					break;
				}
			}
			if(
				!isinthissector
				&&!trueifany
			)return false;
		}
		return anyfound;
	}

	override void WorldLinePreActivated(WorldEvent e){
		let lll=e.ActivatedLine;
		switch(lll.special){
		case Plat_DownWaitUpStayLip:
		case Plat_DownWaitUpStay:
		case Generic_Lift:
			if(
				e.ActivationType==SPAC_Cross
				&&e.Thing
				&&LinePartOfTaggedSector(lll,true)
			){
				e.ShouldActivate=false;
				DelayedLineActivator.Init(lll,e.ActivationType,e.Thing,25);
			}
			break;
		}
	}

	void MapTweaks(){

		//generic map hacks
		textureid dirtyglass=texman.checkfortexture("WALL47_2",texman.type_any);
		int itmax=level.lines.size();
		for(int i=0;i<itmax;i++){
			line lll=level.lines[i];

			if(lll.special){
				switch(lll.special){

				//increase door delays
				case Door_WaitRaise: //delay is third arg
				case Door_WaitClose:
				case Door_Raise:
				case Door_LockedRaise:
				case Door_WaitClose:
				case Door_Animated:
				//case Door_CloseWaitOpen:
				//case Door_WaitRaise:
					if(
						hd_safelifts
						&&!LinePartOfTaggedSector(lll)
					)lll.args[2]*=HDCONST_LIFTWAITMULT;
					break;
				case Generic_Door: //delay is fourth arg
					if(
						hd_safelifts
						&&!LinePartOfTaggedSector(lll)
					)lll.args[3]*=HDCONST_LIFTWAITMULT;
					break;


				//cap platform speeds
				case Plat_DownWaitUpStayLip: //delay is third arg
				case Plat_DownWaitUpStay:
				case Plat_UpNearestWaitDownStay:
				case Plat_UpWaitDownStay:
				case Plat_PerpetualRaise:
				case Plat_PerpetualRaiseLip:
				case Generic_Lift:
					if(
						hd_safelifts
						&&!LinePartOfTaggedSector(lll)
					)lll.args[2]*=HDCONST_LIFTWAITMULT;
				case Plat_DownByValue:
				case Plat_PerpetualRaiseLip:
				case Plat_PerpetualRaise:
				case Plat_RaiseAndStayTx0:
				case Plat_UpByValue:
				case Plat_UpByValueStayTx:
				case Generic_Floor:
				case Floor_LowerByValue:
				case Floor_LowerToLowest:
				case Floor_LowerToHighest:
				case Floor_LowerToHighestEE:
				case Floor_LowerToNearest:
				case Floor_RaiseByValue:
				case Floor_RaiseToHighest:
				case Floor_RaiseToNearest:
				case Floor_RaiseToLowest:
					if(
						hd_safelifts
					)lll.args[1]=clamp(lll.args[1],-24,24);
					break;

				//prevent lights from going below 1
				case Light_ChangeToValue:
				case Light_Fade:
				case Light_LowerByValue:
					lll.args[1]=max(lll.args[1],1);break;
				case Light_Flicker:
				case Light_Glow:
				case Light_Strobe:
					lll.args[2]=max(lll.args[2],1);break;
				case Light_StrobeDoom:
					lll.args[2]=min(lll.args[2],1);break;
				case Light_RaiseByValue:
					if(lll.args[1]>=0)break;
				case Light_LowerByValue:
					sectortagiterator sss=level.createsectortagiterator(lll.args[0]);
					int ssss=sss.next();
					int lowestlight=255;
					while(ssss>-1){
						lowestlight=min(lowestlight,level.sectors[ssss].lightlevel);
						ssss=sss.next();
					}
					lll.args[1]=min(lll.args[1],lowestlight-1);

				default: break;
				}
			}
			//remove arbitrary invisible barriers
			if(
				!!lll.sidedef[1]
				&&!lll.sidedef[0].gettexture(side.mid)
				&&!lll.sidedef[1].gettexture(side.mid)
			){
				//err in favour of player movement
				if(
					lll.flags&(
						line.ML_BLOCKEVERYTHING
						|line.ML_BLOCKING
					)
				){
					lll.flags|=line.ML_BLOCKMONSTERS;
				}
				lll.flags&=~line.ML_BLOCKEVERYTHING;
				lll.flags&=~line.ML_BLOCKING;
				lll.flags&=~line.ML_BLOCK_PLAYERS;

				//if block-all and no midtexture, force add a mostly transparent midtexture
				if(
					hd_dirtywindows
					&&lll.flags&(
						line.ML_BLOCKPROJECTILE
						|lll.flags&line.ML_BLOCKHITSCAN
					)
				){
					lll.flags|=line.ML_WRAP_MIDTEX;
					lll.sidedef[0].settexture(side.mid,dirtyglass);
					lll.sidedef[1].settexture(side.mid,dirtyglass);
					lll.alpha=0.3;
				}
			}
		}


		//lol nirvana sux
		if(
			Wads.CheckNumForName("doom2hellonearth",0)!=-1
			&&level.mapname~=="MAP21"
			&&!HDMath.CheckLumpReplaced("MAP21")
		){
			actor.spawn("HDExit",(4538,3134,0));
			console.printf("An exit teleport has spawned in the starting room.");
		}


		if(Wads.CheckNumForName("freedoom",0)!=-1){
			if(
				level.mapname~=="MAP01"
				&&!HDMath.CheckLumpReplaced("MAP01")
			){
				// https://github.com/freedoom/freedoom/issues/643
				level.sectors[92].lightlevel=128;
				sector signfringe=level.sectors[77];
				signfringe.lightlevel=128;
				signfringe.SetGlowHeight(sector.ceiling,32);
				signfringe.SetGlowColor(sector.ceiling,"df ff ee");
			}else if(
				level.mapname~=="MAP26"
				&&!HDMath.CheckLumpReplaced("MAP26")
			){
				//Until that discord is no longer enabling raids on the other one...
				let aaa=Wads.FindLump("MAP26");
				aaa=Wads.FindLump("MAP26",aaa+1);
				if(
					aaa<=-1
				){
					console.printf("Awaiting proof of deletion of the server. You know which one.");
					level.total_monsters=-int.MAX;
					level.total_secrets=-int.MAX;
					level.total_items=-int.MAX;
					vector3 npos=(64,-8,160);
					let fff=actor.spawn("HDBossBrain",npos);
					fff.damagemobj(null,null,actor.TELEFRAG_DAMAGE,"instafade",DMG_FORCED);
					npos.y-=48;
					for(int i=0;i<5;i++){
						vector3 rnd=(frandom(-80,80),frandom(-40,70),frandom(0,56));
						actor bbb=actor.spawn("KillerBarrel",npos+rnd);
						bbb.A_Die();
						if(i)bbb.setstatelabel("reallyexplode");
					}
					npos=(-56,-600,0);
					for(int i=0;i<4;i++){
						vector2 rnd=(frandom(-20,20),frandom(-20,20));
						actor bbb=actor.spawn("KillerBarrel",(npos.xy+rnd,npos.z));
						bbb.A_Die();
						if(i)bbb.setstatelabel("reallyexplode");
					}
					npos=(160,-540,0);
					for(int i=0;i<2;i++){
						vector2 rnd=(frandom(-10,10),frandom(-10,10));
						actor bbb=actor.spawn("KillerBarrel",(npos.xy+rnd,npos.z));
						bbb.A_Die();
						if(i)bbb.setstatelabel("reallyexplode");
					}
				}
			}
		}
	}
}


//exit pad that can be placed anywhere
class HDExit:SwitchableDecoration{
	default{
		radius 32;
		height 50;
		+flatsprite
		+usespecial
		activation thingspec_switch;
	}
	states{
	spawn:
		TNT1 A 0 nodelay{
			angle=-90;
			setz(floorz);
		}
		goto inactive;
	active:
		GATE A -1;
		stop;
	inactive:
		GATE B 10{
			bool standingon=false;
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					!playeringame[i]
					||players[i].bot
				)continue;
				let ppp=players[i].mo;
				if(ppp){
					vector3 dist=pos-ppp.pos;
					double dist2=max(abs(dist.x),abs(dist.y));

					if(dist2<32&&!dist.z)standingon=true;
					else if(
						//abort if any player is too far away
						standingon
						&&dist2>256
					){
						console.printf("You must gather your party before venturing forth.");
						return;
					}

				}
			}
			if(standingon)A_BrainDie();
		}wait;
	}
}






