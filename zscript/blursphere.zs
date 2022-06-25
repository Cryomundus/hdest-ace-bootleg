//-------------------------------------------------
// Blur Sphere
//-------------------------------------------------
class BlurTaint:InventoryFlag{default{+inventory.undroppable}}
class HDBlurSphere:HDDamageHandler{
	//true +invisible can never be used.
	//it will cause the monsters to be caught in a consant 1-tic see loop.
	//no one seems to consider this to be a bug.
	//shadow will at least cause attacks to happen less often.
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Blur Sphere"
		//$Sprite "PINSA0"

		-hdpickup.fitsinbackpack
		+inventory.alwayspickup
		+inventory.invbar
		-hdpickup.notinpockets
		HDDamageHandler.priority -666;
		HDPickup.overlaypriority -666;
		inventory.maxamount 9;
		inventory.interhubamount 1;
		inventory.pickupmessage "$BS_PKUP";
		inventory.pickupsound "blursphere/pickup";
		inventory.icon "PINSA0";
		scale 0.3;
	}
	int intensity;int xp;int powerlevel;bool worn;
	int randticker[4];double randtickerfloat,randtickerfloat2;
	override void ownerdied(){
		buntossable=false;
		owner.DropInventory(self);
	}
	states{
	spawn:
		PINS ABCDCB random(1,6);
		loop;
	use:
		TNT1 A 0{
			if(
				bspawnsoundsource
				||(
					invoker.intensity>0
					&&invoker.intensity<99
				)
			)return;

			A_AddBlackout(256,72,8,16);

			if(!invoker.worn){
				invoker.worn=true;
				HDF.Give(self,"BlurTaint",1);
				A_StartSound("blursphere/use",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
				invoker.CheckLevelUp(); 

				int spac=countinv("SpiritualArmour");
				if(spac){
					hdplayerpawn(self).cheatgivestatusailments("fire",spac*3);
					A_TakeInventory("SpiritualArmour");
				}
			}else{
				invoker.worn=false;
				A_StartSound("blursphere/unuse",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
			}
		}fail;
	}
	enum blurstats{
		BLUR_LEVELUP=3500,
		BLUR_LEVELCAP=13,
	}

	void CheckLevelUp(){
		powerlevel=min(13,powerlevel+xp/BLUR_LEVELUP);
		xp%=BLUR_LEVELUP;
		stamina=clamp(powerlevel+random(-2,2),0,10);
		if(powerlevel>7)buntossable=true; 
	}

	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int,name,int,int,int,int,int,int HandleDamagePost(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		int towound,
		int toburn,
		int tostun,
		int tobreak,
		int toaggravate
	){
		if(worn){
			if(mod=="balefire"){
				damage=max(1,damage-(powerlevel<<1));
				toburn=max(random(0,1),toburn-(powerlevel>>1));
			}else if(mod=="hot"||mod=="cold")intensity-=100;
		}
		return damage,mod,flags,towound,toburn,tostun,tobreak,toaggravate;
	}

	override void tick(){
		super.tick();
		double frnd=frandom[blur](0.93,1.04);
		scale=(0.3,0.3)*frnd;
		alpha=0.9*frnd;
		randticker[0]=random(0,3);
		randticker[1]=random(8,25);
		randticker[2]=random(0,40+powerlevel);
		randticker[3]=random(0,BLUR_LEVELUP);
		randtickerfloat=frandom(0.,1.);
		randtickerfloat2=frandom(0.,1.);
	}
	override void DoEffect(){
		if(
			!owner
			||owner.health<1
		){
			return;
		}

		if(owner.level.time==666)CheckLevelUp();

		//they eat their own
		if(amount>1){  
			amount=1;
			xp+=100;
		}

		if(!worn){
			intensity=max(0,intensity-1);
			if(powerlevel<BLUR_LEVELCAP&&!randticker[0])xp++;
		}else{
			if(
				owner.bspawnsoundsource
				||(
					owner.player
					&&owner.player.cmd.buttons&BT_ATTACK  //only fist has alt be an actual attack
					&&owner.player.readyweapon
					&&!owner.player.readyweapon.bambush
					&&!owner.player.readyweapon.bwimpy_weapon
				)
			)intensity=-200;
			else{
				if(intensity<99)intensity=max(intensity+1,-135);
				xp++;
			}
		}
		bool invi=true;

		if(intensity<randticker[1]){
			owner.a_setrenderstyle(1.,STYLE_Normal);
			invi=false;
		}else{
			//flicker into total invisiblity
			int buttons=owner.player?owner.player.cmd.buttons:0;
			if(
				owner.bshadow
				&&intensity>45
				&&(
					!(buttons&BT_ATTACK)
					&&!(buttons&BT_ALTATTACK)
					&&!(buttons&BT_RELOAD)
					&&!(buttons&BT_UNLOAD)
					&&(level.time&(2|4|((
						(owner.vel dot owner.vel < 2.)
					)?(8|16|32|64):0)))
				)
			){
				owner.a_setrenderstyle(0.9,STYLE_None);
				owner.bspecialfiredamage=true;
			}else{
				owner.a_setrenderstyle(0.9,STYLE_Fuzzy);
				owner.bspecialfiredamage=false;
			}
		}

		//apply result
		owner.bshadow=invi;

		if(!owner.countinv("blurtaint"))return;



		//medusa gaze
		if(invi&&!!randticker[0]){
			flinetracedata medusagaze;
			owner.linetrace(
				owner.angle,4096,owner.pitch,
				offsetz:owner.height-6,
				data:medusagaze
			);
			actor aaa=medusagaze.hitactor;
			if(
				aaa
				&&(
					aaa.bismonster
					||aaa.player
				)&&(
					!hdmobbase(aaa)
					||!hdmobbase(aaa).bnoblurgaze
				)
			){
				aaa.A_ClearTarget();
				HDF.Give(aaa,"Heat",random(1,powerlevel+3));
				if(!random(0,3))xp++;
			}
		}

		let hdp=hdplayerpawn(owner);
		if(hdp){
			if(hdp.CountInv('HDBlues')>random(1,HDBLU_BALL)){
				hdp.aggravateddamage++;
				hdp.A_TakeInventory('HDBlues', 4);
				hdp.cheatgivestatusailments("fire",1);
				if(!worn&&!randticker[2]){
					hdp.A_TakeInventory("BlurTaint");
				}
			}
			if(hdp.countinv("SpiritualArmour")){
				hdp.cheatgivestatusailments("fire",countinv("SpiritualArmour")*10);
				hdp.A_TakeInventory("SpiritualArmour");
			}
			if(hdp.woundcount>random(0,powerlevel)){
				hdp.woundcount--;
				hdp.unstablewoundcount++;
			}
		}

		if(xp<1)return;

		//power.
		if(!(xp%666)){
			bool nub=!powerlevel&&xp<1066;
			if(nub||!random(0,15))owner.A_Log("You feel power growing in you.",true);
			blockthingsiterator it=blockthingsiterator.create(owner,512);
			array<actor>monsters;monsters.clear();
			while(it.next()){
				actor itt=it.thing;
				let hdit=hdmobbase(itt);
				if(
					itt==owner
					||HDBossBrain(itt)
					||!itt.bismonster
					||itt.health<1
					||(hdit&&hdit.bnoblurgaze)
				)continue;
				monsters.insert(random(0,monsters.size()),itt);

				if(
					!hdit
					&&itt.target==owner
				)itt.A_ClearTarget();

				if(
					nub
					||!random(0,66-powerlevel)
				){
					actor fff=itt.spawn("HDFire",itt.pos,ALLOW_REPLACE);
					fff.target=itt;
					fff.stamina=nub?166:13*powerlevel;
					fff.master=self;
				}else if(random(0,6-powerlevel)<1){
					HDBleedingWound.Inflict(itt,13*powerlevel,source:self);
				}
			}
			if(monsters.size()){
				int maxindex=monsters.size()-1;
				for(int i=0;i<monsters.size();i++){
					actor mmm1=monsters[i];
					actor mmm2=monsters[random(0,maxindex)];
					mmm1.damagemobj(
						self,mmm2,1,"Balefire"
					);
					mmm1.target=mmm2;
					if(!mmm2.target)mmm2.target=mmm1;
				}
			}
		}

		//just a totally normal day
		if(
			powerlevel>=3
			&&randticker[2]>40
			&&(
				worn
				||buntossable
			)
		)owner.A_StartSound("blursphere/scream",
			666,CHANF_OVERLAP|CHANF_LOCAL,
			volume:max(0.0001,randtickerfloat*0.0002)*intensity*(powerlevel-(worn?3:6)),
			pitch:max(0.1,randtickerfloat2*1.6)
		);

		//precious.
		if(randticker[3]<powerlevel){
			if(!(xp%3)){
				owner.A_StartSound("blursphere/hallu"..int(clamp(randtickerfloat*7,0,6)),
					CHAN_VOICE,CHANF_OVERLAP|CHANF_LOCAL,randtickerfloat*0.3+0.3
				);
			}
			if(!(xp%5)){
				array<string>msgs;msgs.clear();
				string msg=Wads.ReadLump(Wads.CheckNumForName("blurspheretexts",0));
				msg.replace("\r", "");
				msg.split(msgs,"\n");
				msg=msgs[int(clamp(randtickerfloat*msgs.size(),0,msgs.size()-1))];
				if(msg=="Out of sync with: ")msg=msg..randticker[0]+1;
				owner.A_Log(msg,true);
			}
			if(!(xp%7)){
				hdplayerpawn(owner).aggravateddamage++;
				if(!randticker[0])owner.A_Log("$BS_PRECIOUS",true);
			}
		}
		if(powerlevel>=BLUR_LEVELCAP&&xp>666)xp=0;
	}
	override void DetachFromOwner(){
		owner.bshadow=false;
		owner.bspecialfiredamage=false;
		owner.a_setrenderstyle(1.,STYLE_Normal);
		if(worn){
			worn=false;
			owner.damagemobj(self,owner,random(1,powerlevel),"balefire");
		}
		intensity=0;
		owner.A_StartSound("blursphere/drop",CHAN_BODY,volume:frandom(0.3,0.5),attenuation:8.);
		super.detachfromowner();
	}


	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		if(
			!sb.blurred
			&&self.powerlevel<=3
		)return;

		double sclx=2/1.2;
		double scly=2.;
		name ctex="HDXCAM_BLUR";

		sb.SetSize(0,300,200);
		sb.BeginHUD(forcescaled:true);
		texman.setcameratotexture(hpl,ctex,sb.cplayer.fov*(1.3+0.03*(sin(owner.level.time))));
		double lv=stamina;
		double camalpha;
		if(sb.blurred)camalpha=intensity*0.0006*clamp(lv,0.5,18);
		else if(buntossable)camalpha=0.02*clamp(lv,0.2,42);
		else camalpha=0.003*clamp(lv,0,18);
		int ilv=int(lv+10*sin(owner.level.time&(1|2|4)));
		int dif=sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER|sb.DI_ITEM_HCENTER;
		sb.drawimage(
			ctex,(-ilv>>2,0),
			dif,
			alpha:camalpha,
			scale:(sclx,scly)
		);
		sb.drawimage(
			ctex,(ilv>>2,0),
			dif,
			alpha:camalpha*0.6,
			scale:(sclx,scly)
		);
	}
}





//a mortal man doomed to die
class WraithLight:PointLight{
	default{
		+dynamiclight.subtractive
	}
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=66;
		args[1]=17;
		args[2]=13;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-5,2);
			if(args[3]<1)destroy();
		}else{
			setorigin(target.pos,true);
			if(target.bmissile)args[3]=random(32,40);
			else args[3]=random(48,64);
		}
	}
}
//In geometry, a spherical shell is a generalization of an annulus to three dimensions.
class ShellShade:ZombieStormtrooper{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shellshade"
		//$Sprite "POSSA1"

		+shadow -solid +noblood
		+hdmobbase.noincap
		hdmobbase.shields 666;
		renderstyle "Fuzzy";
		health 900;
		stencilcolor "04 00 06";
		tag "shell-shade";

		seesound "shellshade/sight";
		activesound "shellshade/active";
		painsound "shellshade/pain";
		deathsound "shellshade/death";
	}
	override void postbeginplay(){
		user_weapon=1;
		super.postbeginplay();
		A_SpawnItemEx("WraithLight",flags:SXF_SETTARGET);
	}
	override void tick(){
		super.tick();
		bshootable=randompick(0,1,1,1);
		scale=bshootable?(1.,1.):(0.98,0.98);
		binvisible=bshootable?false:true;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			mod=="holy"
			||(
				mod!="bleedout"
				&&source
				&&source.countinv("SpiritualArmour")
				&&!source.countinv("HDBlurSphere")
			)
		){
			bnoblood=false;
			forcepain(self);
			A_Scream();
			A_TakeInventory("HDMagicShield",countinv("HDMagicShield")>>1);
		}
		int dmg=super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
		if(bnoblood)stunned=0;
		return dmg;
	}
	override void deathdrop(){
		A_NoBlocking();
		A_DropItem("ZM66Regular");
		bnointeraction=true;
		for(int i=0;i<10;i++){A_SpawnItemEx("HDSmoke",
			frandom(-12,12),frandom(-12,12),frandom(4,36),
			flags:SXF_NOCHECKPOSITION
		);}
		DistantQuaker.Quake(self,
			6,100,16384,10,256,512,128
		);
		vel=(0,0,0);
	}
	states{
	death:
	xdeath:
		POSS G 5;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAA
			random(1,3) A_StartSound(deathsound,CHAN_VOICE,CHANF_OVERLAP,volume:frandom(0.3,1.),attenuation:0.1,pitch:frandom(0.9,1.1));
	death.bleedout:
		TNT1 A 35;
		TNT1 A 0 A_DropItem("HDBlurSphere");
	xxxdeath:
		stop;
	}
}

