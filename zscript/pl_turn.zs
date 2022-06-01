// ------------------------------------------------------------
// Stuff related to player turning
// ------------------------------------------------------------
extend class HDPlayerPawn{
	vector2 muzzleclimb1;
	vector2 muzzleclimb2;
	vector2 muzzleclimb3;
	vector2 muzzleclimb4;
	vector2 hudbobrecoil1;
	vector2 hudbobrecoil2;
	vector2 hudbobrecoil3;
	vector2 hudbobrecoil4;
	vector2 muzzledrift;
	bool muzzlehit;
	bool totallyblocked;
	bool movehijacked;

	enum muzzleblock{
		MB_TOP=1,
		MB_BOTTOM=2,
		MB_LEFT=4,
		MB_RIGHT=8,
	}

	double lastpitch;
	double lastangle;
	void TurnCheck(bool notpredicting,weapon readyweapon){

		//abort if rolling or teleporting
		if(
			teleported
			||fallroll
			||realpitch>90
			||realpitch<-90
		){
			if(teleported)feetangle=angle;
			return;
		}


		//find things that scale input
		double turnscale=1.;

		//reduced turning while supported.
		if(
			isFocussing
			&&!countinv("IsMoving")
		){
			double aimscale=hd_aimsensitivity.GetFloat();
			if(aimscale>1.)aimscale=0.1;
			if(!gunbraced)aimscale+=(1.-aimscale)*0.3;
			else aimscale=min(aimscale,hd_bracesensitivity.GetFloat());
			turnscale*=clamp(aimscale,0.05,HDCONST_MAXFOCUSSCALE);
		}
		//reduced turning while crouched.
		else if(player.crouchfactor<0.7){
			int absch=max(abs(player.cmd.yaw),abs(player.cmd.pitch));
			if(absch>(8*65536/360)){
				turnscale*=0.6;
			}
		}
		//reduced turning while stunned.
		//all randomizing and inertia effects are in TurnCheck.
		if(stunned)turnscale*=0.3;


		//process input
		double anglechange=clamp((360./65536.)*player.cmd.yaw,-40,40);
		double pitchchange=-(360./65536.)*player.cmd.pitch;
		if(!notpredicting){
			//don't do anything that could seriously change between tics
			//ultimately we might be fored to just "return" on these
			angle+=anglechange;
			pitch+=pitchchange;
			return;
		}

		//does anyone even use this?
		if(player.turnticks){
			player.turnticks--;
			anglechange+=(180./TURN180_TICKS);
		}


		//set lookscale and fov
		if(readyweapon)readyweapon.lookscale=turnscale;
		player.fov=player.desiredfov*recoilfov;




		//process muzzle climb
		pitchchange+=muzzleclimb1.y;
		anglechange+=muzzleclimb1.x;

		muzzleclimb1=muzzleclimb2;
		muzzleclimb2=muzzleclimb3;
		muzzleclimb3=muzzleclimb4;
		muzzleclimb4=(0,0);




		//get weapon size
		double driftamt=0;
		double barrellength=0;
		double barrelwidth=0;
		double barreldepth=0;
		bool notnull=!NullWeapon(readyweapon);
		let wp=HDWeapon(readyweapon);
		if(wp){
			driftamt=max(1,wp.gunmass());
			barrellength=wp.barrellength;
			barrelwidth=wp.barrelwidth;
			barreldepth=wp.barreldepth;
		}


		//inertia adjustments for other things
		if(stunned){
			driftamt*=frandom(3,5);
		}
		if(
			notnull
			&&HDWeapon.IsBusy(self)
		){
			barrellength=radius+1.4;
			barrelwidth*=2;
			driftamt=min(driftamt*1.5,20);
		}




		//muzzle inertia
		//how much to scale movement
		double decelproportion=min(0.042*driftamt,0.99)*0.7;
		double driftproportion=0.05*driftamt;


		//apply to weapon
		vector2 apch=(anglechange,-pitchchange)*0.1*driftamt;
		if(isFocussing||(wp&&wp.breverseguninertia))apch=-apch;
		hudbobrecoil1+=apch*0.1;
		hudbobrecoil2+=apch*0.2;
		hudbobrecoil3+=apch*0.4;
		hudbobrecoil4+=apch*0.6;

		//make changes based on velocity
		vector3 muzzlevel=lastvel-vel;

		//apply crouch
		muzzlevel.z-=(lastheight-height)*0.3;

		//determine velocity-based drift
		muzzlevel.xy=rotatevector(muzzlevel.xy,-angle);

		muzzledrift+=(muzzlevel.y,muzzlevel.z)*driftproportion;


		//screw things up even more
		if(stunned){
			vector2 muzzleclimbstun=(anglechange,pitchchange)*frandom(0,0.3);
			anglechange+=muzzleclimbstun.x;
			pitchchange+=muzzleclimbstun.y;
			muzzleclimb1+=muzzleclimbstun;
			muzzleclimb2+=muzzleclimbstun;
			muzzleclimb3+=muzzleclimbstun;
		}


		//apply the drift
		hudbobrecoil1+=muzzledrift;
		muzzledrift*=decelproportion;
		hudbobrecoil2+=muzzledrift;


		LowHealthJitters();


		//weapon collision
		if(!(player.cheats&CF_NOCLIP2 || player.cheats&CF_NOCLIP)){
			double highheight=height-HDCONST_CROWNTOEYES*heightmult;
			double midheight=highheight-max(1,barreldepth)*0.5;
			double lowheight=highheight-max(1,barreldepth);
			double testangle=angle;
			double testpitch=pitch;
			vector3 posbak=pos;

			setxyz(posbak+vel);

			flinetracedata bigcoll;
			//check for super-collision preventing only aligned sights		
			if(
				!barehanded
				&&linetrace(
					testangle,max(barrellength,HDCONST_MINEYERANGE),
					testpitch,
					flags:TRF_NOSKY,
					offsetz:highheight,
					data:bigcoll
				)
				&&(
					!bigcoll.hitactor
					||(
						bigcoll.hitactor.bsolid
						&&!bigcoll.hitactor.bnoclip
					)
				)
			){
				nocrosshair=12;
				hudbobrecoil1.y+=10;
				hudbobrecoil2.y+=10;
				hudbobrecoil3.y+=10;
				hudbobrecoil4.y+=10;
				highheight=max(height*0.5,height-HDCONST_CROWNTOSHOULDER*heightmult);
			}else if(nocrosshair>0){
				highheight=max(height*0.5,height-HDCONST_CROWNTOSHOULDER*heightmult);
			}
			barrellength-=(HDCONST_SHOULDERTORADIUS*player.crouchfactor);


			//and now uh do stuff
			vector3 barrelbase=pos+(0,0,midheight);
			int muzzleblocked=0;

			double distleft=barrellength;;
			double distright=barrellength;;
			double disttop=barrellength;
			double distbottom=barrellength;

			flinetracedata ltl;
			flinetracedata ltr;
			flinetracedata ltt;
			flinetracedata ltb;



			//top
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:highheight+cos(pitch)*barreldepth,
				offsetforward:sin(pitch)*barreldepth,
				offsetside:0,
				data:ltt
			);
			if(
				ltt.hittype!=Trace_CrossingPortal
				&&!(ltt.hitactor&&(
					ltt.hitactor.bnonshootable
					||!ltt.hitactor.bsolid
				))
			){
				disttop=ltt.distance;
				if(ltt.distance<barrellength)muzzleblocked|=MB_TOP;
			}

			//bottom
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:lowheight-cos(pitch)*barreldepth,
				offsetforward:-sin(pitch)*barreldepth,
				offsetside:0,
				data:ltb
			);
			if(
				ltb.hittype!=Trace_CrossingPortal
				&&!(ltb.hitactor&&(
					ltb.hitactor.bnonshootable
					||!ltb.hitactor.bsolid
				))
			){
				distbottom=ltb.distance;
				if(ltb.distance<barrellength)muzzleblocked|=MB_BOTTOM;
			}


			//left
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:midheight,
				offsetside:-barrelwidth,
				data:ltl
			);
			if(
				ltl.hittype!=Trace_CrossingPortal
				&&!(ltl.hitactor&&(
					ltl.hitactor.bnonshootable
					||!ltl.hitactor.bsolid
				))
			){
				distleft=ltl.distance;
				if(ltl.distance<barrellength)muzzleblocked|=MB_LEFT;
			}

			//right
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:midheight,
				offsetside:barrelwidth,
				data:ltr
			);
			if(
				ltr.hittype!=Trace_CrossingPortal
				&&!(ltr.hitactor&&(
					ltr.hitactor.bnonshootable
					||!ltr.hitactor.bsolid
				))
			){
				distright=ltr.distance;
				if(ltr.distance<barrellength)muzzleblocked|=MB_RIGHT;
			}


			//totally caught
			totallyblocked=muzzleblocked==MB_TOP|MB_BOTTOM|MB_LEFT|MB_RIGHT;



			//set angles
			int crouchdir=0;
			if(
				player.crouchfactor<1
				&&player.crouchfactor>0.5
			){
				crouchdir=player.crouching;
				if(!crouchdir)crouchdir=(player.cmd.buttons&BT_CROUCH)?-1:1;
			}
			bool mvng=(crouchdir || (vel dot vel) > 0.25);
			bool hitsnd=(max(abs(anglechange),abs(pitchchange))>1);


			if(
				muzzleblocked
				&&notnull
			){

				if(totallyblocked){
					vector2 cv=angletovector(pitch,
						clamp(barrellength-disttop,0,barrellength)*0.005);
					A_ChangeVelocity(-cv.x,0,0,CVF_RELATIVE);
				}

				if(distleft!=distright){
					double aac=abs(anglechange);
					anglechange+=clamp(
						-anglechange*0.1,
						(muzzleblocked&MB_RIGHT)?-0.1:-aac,
						(muzzleblocked&MB_LEFT)?0.1:aac
					);
					if(mvng){
						double agc=(distleft>distright)?1:(distright>distleft)?-1:0;
						if(agc){
							anglechange=agc;
							muzzleclimb1.x+=agc*0.3;
							muzzleclimb2.x+=agc*0.2;
							muzzleclimb3.x+=agc*0.1;
							muzzleclimb4.x+=agc*0.04;
						}
					}
				}

				if(
					disttop!=distbottom
					||(muzzleblocked&MB_BOTTOM)
					||(muzzleblocked&MB_TOP)
				){
					double aac=abs(pitchchange);
					if(aac<4){
						pitchchange=clamp(pitchchange,
							(muzzleblocked&MB_TOP)?-0.1:-aac,
							(muzzleblocked&MB_BOTTOM)?0.1:aac
						);
					}
					else pitchchange+=clamp(
						-pitchchange*0.1,
						(muzzleblocked&MB_TOP)?-0.1:-aac,
						(muzzleblocked&MB_BOTTOM)?0.1:aac
					);
					if(mvng){
						double agc=(
							(crouchdir>0&&pitch>0)
							||distbottom>disttop
						)?1:(
							(crouchdir<0&&pitch<0)
							||disttop>distbottom
						)?-1:0;
						if(agc){
							pitchchange=agc*3;
							muzzleclimb1.y+=agc*0.8;
							muzzleclimb2.y+=agc*0.4;
							muzzleclimb3.y+=agc*0.2;
							muzzleclimb4.y+=agc*0.1;
						}
					}
				}

				if(
					(anglechange>0&&(muzzleblocked&MB_LEFT))
					||(anglechange<0&&(muzzleblocked&MB_RIGHT))
					||(pitchchange>0&&(muzzleblocked&MB_BOTTOM))
					||(pitchchange<0&&(muzzleblocked&MB_TOP))
				){
					isfocussing=true;
					gunbraced=true;
				}
			}


			setxyz(posbak);


			//bump
			if(muzzleblocked>=4){  
				muzzlehit=false;
			}else if(!muzzlehit){
				if(hitsnd)A_StartSound("weapons/guntouch",8,CHANF_OVERLAP,0.6);
				muzzlehit=true;
				gunbraced=true;
			}
		}




		//feet angle
		double fac=deltaangle(feetangle,angle);
		if(abs(fac)>(player.crouchfactor<0.7?30:50)){
			vel+=rotatevector((0,fac>0?0.1:-0.1),angle);
			A_GiveInventory("IsMoving",2);
			feetangle=angle+anglechange;
			PlayRunning();

			//if on appropriate terrain, easier to quench a fire
			if(player.crouchfactor<0.7){
				A_SetInventory("HDFireDouse",countinv("HDFireDouse")+CheckLiquidTexture()?6:3);
			}
		}

		//move pivot point a little behind the player's view
		anglechange=normalize180(anglechange);
		if(
			!teleported
			&&!incapacitated
			&&player.onground
		){
			bool ongun=gunbraced&&!barehanded&&isFocussing;
			if(abs(anglechange)>(ongun?0.05:0.7)){
				int dir=((anglechange>0)||ongun)?90:-90;
				double aad=angle+anglechange+dir;
				trymove(self.pos.xy+(cos(aad),sin(aad))*(ongun?-0.3*anglechange:0.6),false);
			}
			double ptchch=clamp(abs(pitchchange),0,10); //THE CLAMP IS A BANDAID
			if(ptchch>1 && abs(pitch)<30){  
				trymove(pos.xy-(cos(angle)*ptchch,sin(angle)*ptchch)*0.1,false);
				PlayRunning();
			}
		}



		//reset blocked check for a fresh start
		totallyblocked=false;

		//this and the predicting equivalent above should, ideally, be the ONLY
		//places where HD should be changing the player pitch and angle.
		if(multiplayer){
			angle+=anglechange;
			pitch+=pitchchange;
		}else{
			A_SetPitch(pitch+pitchchange,SPF_INTERPOLATE);
			A_SetAngle(angle+anglechange,SPF_INTERPOLATE);
		}
	}


	void LowHealthJitters(){
		if(
			beatmax<10||
			fatigue>20||
			bloodpressure>20||  
			health<33
		){
			double jitter=clamp(0.01*fatigue,0.3,6.);

			if(gunbraced)jitter=0.05;
			else if(health<20)jitter=1;

			hudbobrecoil1+=(frandom(-jitter,jitter),frandom(-jitter,jitter));
			muzzleclimb1+=(frandom(-jitter,jitter),frandom(-jitter,jitter));
		}
	}


	//seeing if you're standing on a liquid texture
	static const string lq[]={
		"MFLR8_4","MFLR8_2",
		"SFLR6_1","SFLR6_4",
		"SFLR7_1","SFLR7_4",
		"FWATER1","FWATER2","FWATER3","FWATER4",
		"BLOOD1","BLOOD2","BLOOD3",
		"SLIME1","SLIME2","SLIME3","SLIME4",
		"SLIME5","SLIME6","SLIME7","SLIME8"
	};
	bool CheckLiquidTexture(){
		int lqlength=lq.size();
		let fp=floorpic;
		for(int i=0;i<lqlength;i++){
			TextureID tx=TexMan.CheckForTexture(lq[i],TexMan.Type_Flat);
			if (tx&&fp==tx){
				return true;
			}
		}
		return false;
	}

	//Muzzle climb!
	void A_MuzzleClimb(vector2 mc1,vector2 mc2,vector2 mc3,vector2 mc4,bool wepdot=false){
		double mult=1.;
		if(gunbraced)mult=0.2;
		else if(countinv("IsMoving"))mult=1.6;
		if(stunned)mult*=1.6;
		if(mult){
			mc1*=mult;
			mc2*=mult;
			mc3*=mult;
			mc4*=mult;
		}
		muzzleclimb1+=mc1;
		muzzleclimb2+=mc2;
		muzzleclimb3+=mc3;
		muzzleclimb4+=mc4;
		if(wepdot){
			hudbobrecoil1+=(mc1.x,mc1.y*2)*mult;
			hudbobrecoil2+=(mc2.x,mc2.y*2)*mult;
			hudbobrecoil3+=(mc3.x,mc3.y*2)*mult;
			hudbobrecoil4+=(mc4.x,mc4.y*2)*mult;
		}
	}
}


