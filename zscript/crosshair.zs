// ------------------------------------------------------------
// Sight picture crosshairs
// ------------------------------------------------------------
extend class HDStatusBar{
	virtual void DrawGrenadeLadder(int airburst,vector2 bob){
		drawimage(
			"XH27",(0,1.8)+bob,DI_SCREEN_CENTER|DI_ITEM_HCENTER|DI_ITEM_TOP,
			scale:(1.,1.)
		);
		if(airburst)drawnum(airburst/100,
			12+bob.x,22+bob.y,DI_SCREEN_CENTER,Font.CR_BLACK
		);
	}
	virtual void DrawHDXHair(hdplayerpawn hpl){
		int nscp=hd_noscope.getint();
		if(
			!(cplayer.cmd.buttons&(BT_USE|BT_ZOOM))
			&&(
				nscp>1
				||hd_hudusedelay.getint()<-1
			)
		)return;

		let wp=hdweapon(cplayer.readyweapon);
		bool sightbob=hd_sightbob.getbool();
		vector2 bob=hpl.hudbob;
		double fov=cplayer.fov;

		//have no crosshair at all
		if(
			!wp
			||hpl.barehanded
			||hpl.nocrosshair>0
			||(!sightbob&&hpl.countinv("IsMoving"))
			||abs(bob.x)>50
			||fov<13
		)return;


		//don't know why this keeps snapping to arbitrary values
		//turning off forcescaled does NOT help
		double scl=fov/(90.*clamp(hd_crosshairscale.getfloat(),0.1,3.0));

		SetSize(0,int(320.*scl),int(200.*scl));
		BeginHUD(forcescaled:true);

		actor hpc=hpl.scopecamera;
		int cpbt=cplayer.cmd.buttons;

		bool scopeview=!!hpc&&(
			!nscp
			||cpbt&BT_ZOOM
			||hudlevel==2
		);

		wp.DrawSightPicture(self,wp,hpl,sightbob,bob,fov,scopeview,hpc);
	}

	//choose the reticle picture with a fallback.
	//NB: Theoretically this SHOULD NOT desync if someone has more pictures loaded,
	//but if anyone complains later take a look again.
	string ChooseReflexReticle(int which){
		string ret=HDCONST_RETICLEPREFIX..which;
		if(ret.length()>8)ret=ret.left(8);
		if(TexMan.GetName(TexMan.CheckForTexture(ret))!="")return ret;

		//check for deprecated "riflsit" - untested!
		if(which<10){
			ret="riflsit"..which;
			if(TexMan.GetName(TexMan.CheckForTexture(ret))!="")return ret;
		}

		return HDCONST_RETICLEPREFIX..0;
	}
}
