//---------------------------------
// Sorry, English only.
//---------------------------------
/*
extend class HDPlayerPawn{
	override String GetObituary(
		Actor victim,
		Actor inflictor,
		Name mod,
		bool playerattack
	){
		string gob=super.GetObituary(victim,inflictor,mod,playerattack);
		return HDPronouns.ReviseObituary(gob,victim,inflictor);
	}
}
*/


struct HDPronouns play{

	static string ReviseObituary(
		string inp,
		actor victim,
		actor killer
	){
		string vpns=HDPronouns.GetPronounSet(victim);
		string kpns=HDPronouns.GetPronounSet(victim);

		//these will only occur in HD's custom obits.
		//at last a proper "X checks ___ glasses".
		inp.replace("%g_",HDPronouns.GetPronoun(kpns,PRON_SUBJECT));
		inp.replace("%h_",HDPronouns.GetPronoun(kpns,PRON_OBJECT));
		inp.replace("%p_",HDPronouns.GetPronoun(kpns,PRON_POSS));
		inp.replace("%s_",HDPronouns.GetPronoun(kpns,PRON_POSSIND));
		inp.replace("%r_",HDPronouns.GetPronoun(kpns,PRON_IS));

		inp.replace("%g",HDPronouns.GetPronoun(vpns,PRON_SUBJECT));
		inp.replace("%h",HDPronouns.GetPronoun(vpns,PRON_OBJECT));
		inp.replace("%p",HDPronouns.GetPronoun(vpns,PRON_POSS));
		inp.replace("%s",HDPronouns.GetPronoun(vpns,PRON_POSSIND));
		inp.replace("%r",HDPronouns.GetPronoun(vpns,PRON_IS));

		return inp;
	}


	static string GetPronounSet(actor referent){
		let hpl=HDPlayerPawn(referent);

		//if the referent is not an HD playerpawn
		if(!hpl||!hpl.hd_pronouns){
			if(
				(
					HDMobBase(referent)
					&&!HDHumanoid(referent)
				)
				||HDUPK(referent)
				||weapon(referent)
				||inventory(referent)
			)return PRON_IT;
			return PRON_THEYTHEM;
		}

		string inp=hpl.hd_pronouns.getstring();
		inp=inp.MakeLower();

		if(
			inp==""
			||inp=="0"
			||inp=="gender"
			||inp=="default"
			||inp=="none"
		){
			switch(hpl.player.getgender()){
				case 0:return PRON_HEHIM;
				case 1:return PRON_SHEHER;
				case 2:return PRON_THEYTHEM;
				case 3:return PRON_IT;
			}
		}

		return inp;
	}
	static string GetPronoun(
		string pset,
		int pcase
	){
		pset=pset.MakeLower();

		//abbreviations for the paleopronouns
		if(
			pset=="they"
			||pset=="they/them"
		)pset=PRON_THEYTHEM;
		else if(
			pset=="it"
			||pset=="it/it"
			||pset=="it/its"
		)pset=PRON_IT;
		else if(
			pset=="she"
			||pset=="she/her"
		)pset=PRON_SHEHER;
		else if(
			pset=="he"
			||pset=="he/him"
		)pset=PRON_HEHIM;

		array<string> pronouns;pronouns.clear();
		pset.split(pronouns,"/");


		//and if you fill it in wrong...
		int filledin=pronouns.size()-1;
		if(filledin<=PRON_FINAL){
			//i punched they in the face
			if(filledin<=PRON_OBJECT)pronouns.push(pronouns[PRON_SUBJECT]);

			//i took them's gun
			if(filledin<=PRON_POSS)pronouns.push(pronouns[PRON_OBJECT].."'s");

			//that gun was their
			if(filledin<=PRON_POSSIND)pronouns.push(pronouns[PRON_POSS]);

			//they punched themself
			if(filledin<=PRON_REFL)pronouns.push(pronouns[PRON_OBJECT].."self");

			//they's over there (getting punched and their gun stolen)
			if(filledin<=PRON_IS)pronouns.push(pronouns[PRON_SUBJECT].."'s");
		}

		return pronouns[clamp(pcase,0,PRON_FINAL)];
	}
}
enum PronounCases{
	PRON_SUBJECT=0, //they
	PRON_OBJECT=1,  //them
	PRON_POSS=2,    //their
	PRON_POSSIND=3, //theirs
	PRON_REFL=4,    //themself
	PRON_IS=5,      //they're

	PRON_FINAL=PRON_REFL,
}
const PRON_THEYTHEM="they/them/their/theirs/themself/they're";
const PRON_IT="it/it/its/its/itself/it's";
const PRON_SHEHER="she/her/her/hers/herself/she's";
const PRON_HEHIM="he/him/his/his/himself/he's";
