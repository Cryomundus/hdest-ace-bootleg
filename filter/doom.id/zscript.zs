//Stuff specific to Freedoom
version "4.6"


#include "flyingskull.zs"
#include "idpickups.zs"
#include "spiritualarmour.zs"


//otherwise the casting call would show the demonicron sprite
class FreeWormCC:Demon{
	default{
		scale 0.6;
		translation "16:47=48:79";
	}
	states{
	see:
		SARG ABCD 4;
		loop;
	melee:
		SARG E 6;
		SARG F 8;
		SARG G 12;
		goto see;
	death:
		SARG I 5 A_Scream();
		SARG JKLM 5;
		SARG N 40;
		stop;
	}
}
class FreeZombieCC:ShotgunGuy{
	default{
		translation "FreedoomGreycoat";
	}
	states{
	see:
		SPOS ABCD 4;
		loop;
	missile:
		POSS E 10;
		POSS F 1;
		POSS E 2;
		POSS F 1;
		POSS E 2;
		POSS F 1;
		POSS E 10;
		goto see;
	death:
		SPOS H 5 A_Scream();
		SPOS IJK 5;
		SPOS L 40;
		stop;
	}
}


