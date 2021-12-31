//-------------------------------------------------
// Not against flesh and blood.
//-------------------------------------------------
class SpiritualArmour:HDDamageHandler replaces ShieldCore{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Spiritual Armour"
		//$Sprite "BON2A0"

		+inventory.alwayspickup
		+inventory.undroppable
		+hdpickup.nevershowinpickupmanager
		-inventory.invbar
		+inventory.isarmor
		HDDamageHandler.priority -10000;
		inventory.pickupmessage "Picked up an armour bonus.";
		inventory.amount 1;
		inventory.maxamount 3;
		inventory.pickupsound "misc/p_pkup";
		scale 0.8;
	}
	states{
	use:TNT1 A 0;fail;
	spawn:
		BON2 A 6 A_SetTics(random(7,144));
		BON2 BC 6 A_SetTics(random(1,2));
		BON2 D 6 light("ARMORBONUS") A_SetTics(random(0,4));
		BON2 CB 6 A_SetTics(random(1,3));
		loop;
	pickup:
		TNT1 A 0{
			A_GiveInventory("PowerFrightener");
			let hdp=HDPlayerPawn(self);
			if(hdp){
				hdp.woundcount=0;
				hdp.oldwoundcount+=hdp.unstablewoundcount;
				hdp.unstablewoundcount=0;
				hdp.aggravateddamage=max(0,hdp.aggravateddamage-1);
				hdp.usegametip("\cx"..SpiritualArmour.FromPsalter());
			}
		}
		stop;
	}

	const pscol="\cr";
	static string FromPsalter(){
		string psss=Wads.ReadLump(Wads.CheckNumForName("psalms",0));
		array<string> pss;pss.clear();
		psss.split(pss,"Psalm ");
		pss.delete(0); //don't get anything before "Psalm 1:1"
		string ps=pss[random(0,pss.size()-1)];
		ps=ps.mid(ps.indexof(" ")+1);
		ps=pscol..ps;
		ps.replace("/","\n"..pscol);
		ps.replace("|"," ");
		ps.replace("  "," ");
		ps.replace("\n"..pscol.." ","\n"..pscol);
		return ps;
	}


	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int,name,int,int,int,int,int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		int towound,
		int toburn,
		int tostun,
		int tobreak
	){
		if(
			mod=="bleedout"
		){
			damage=-1;
			mod="internal";
			let hdp=hdplayerpawn(owner);
			if(hdp)hdp.woundcount=0;
			return damage,mod,flags,towound,toburn,tostun,tobreak;
		}
		return damage,mod,flags,towound,toburn,tostun,tobreak;
	}
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
		let victim=owner;
		if(!victim)return damage,mod,flags,towound,toburn,tostun,tobreak,toaggravate;

		if(
			damage==TELEFRAG_DAMAGE
			&&source==victim
		){
			goawayanddie();
			return damage,mod,flags,towound,toburn,tostun,tobreak,toaggravate;
		}

		tostun=min(tostun>>2,7);
		towound=0;
		toburn=0;
		tobreak=0;
		toaggravate=0;

		int removethreshold=random(7,144);

		let hdp=HDPlayerPawn(victim);
		if(
			hdp
			&&hdp.inpain>0
		){
			hdp.inpain=max(hdp.inpain,3);
			hdp.stunned=min(hdp.stunned,350);
		}else if(
			mod!="bleedout"
			&&mod!="internal"
			&&damage>removethreshold
			&&--amount<=0
		)destroy();

		damage=clamp(damage,0,victim.health-7);

		if(!random(0,7))hdbleedingwound.inflict(
			source,random(1,3),1,false,victim
		);

		return damage,mod,flags,towound,toburn,tostun,tobreak,toaggravate;
	}
}


