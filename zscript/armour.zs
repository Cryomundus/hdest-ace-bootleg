//-------------------------------------------------
// Armour
//-------------------------------------------------
const HDCONST_BATTLEARMOUR = 70;
const HDCONST_GARRISONARMOUR = 144;

class HDArmour : HDMagAmmo
{
	override bool IsUsed()
	{
		return true;
	}

	override int GetSBarNum(int flags)
	{
		int ms = Mags.Size()-1;
		if (ms < 0)
		{
			return -1000000;
		}
		return Mags[ms] % 1000;
	}

	override string PickupMessage()
	{
		if (Mags[Mags.Size() - 1] >= 1000)
		{
			return "Picked up the battle armour!";
		}
		return Super.PickupMessage();
	}

	//because it can intentionally go over the MaxPerUnit Amount
	override void AddAMag(int addamt)
	{
		if (addamt < 0)
		{
			addamt = HDCONST_GARRISONARMOUR;
		}
		Mags.Push(addamt);
		Amount = Mags.Size();
	}

	//keep types the same when maxing
	override void MaxCheat()
	{
		SyncAmount();
		for (int i = 0; i < Amount; i++)
		{
			Mags[i] = Mags[i] >= 1000 ? (HDCONST_BATTLEARMOUR + 1000) : HDCONST_GARRISONARMOUR;
		}
	}

	action void A_WearArmour()
	{
		bool helptext = invoker.owner.player && CVar.GetCVar('hd_helptext', invoker.owner.player).GetBool();
		invoker.SyncAmount();
		int dbl = invoker.Mags[invoker.Mags.Size() - 1];

		//if holding use, cycle to next armour
		if (invoker.owner.player && player.cmd.buttons & BT_USE)
		{
			invoker.Mags.Insert(0, dbl);
			invoker.Mags.Pop();
			invoker.SyncAmount();
			return;
		}

		bool intervening = HDPlayerPawn.CheckStrip(invoker.owner, invoker, 0) != CSResult_Nothing;

		if (intervening)
		{
			//check if it's ONLY the armour layer that's in the way
			invoker.wornlayer += 1;
			bool notarmour = HDPlayerPawn.CheckStrip(invoker.owner, invoker, 0) != CSResult_Nothing;
			invoker.wornlayer -= 1;

			if (notarmour || invoker.Cooldown > 0)
			{
				HDPlayerPawn.CheckStrip(invoker.owner, null);
			}
			else
			{
				invoker.Cooldown = 10;
			}
			return;
		}

		//and finally put on the actual armour
		HDArmour.ArmourChangeEffect(self, 100);
		A_GiveInventory('HDArmourWorn');
		let worn = HDArmourWorn(FindInventory('HDArmourWorn'));
		if (dbl >= 1000)
		{
			dbl -= 1000;
			worn.Mega = true;
		}
		worn.Durability = dbl;
		invoker.Amount--;
		invoker.Mags.Pop();

		if (helptext)
		{
			string blah = string.Format("You put on the %s armour.", worn.Mega ? "battle" : "garrison");
			double qual = double(worn.Durability) / (worn.Mega ? HDCONST_BATTLEARMOUR : HDCONST_GARRISONARMOUR);
			if (qual < 0.1) { A_Log(blah.."Just don't get hit.", true); }
			else if (qual < 0.3) { A_Log(blah.."You cover your shameful nakedness with your filthy rags.", true); }
			else if (qual < 0.6) { A_Log(blah.."It's better than nothing.", true); }
			else if (qual < 0.75) { A_Log(blah.."This armour has definitely seen better days.", true); }
			else if (qual < 0.95) { A_Log(blah.."This armour does not pass certification.", true); }
		}

		invoker.SyncAmount();
	}

	override void doeffect()
	{
		if (Cooldown > 0)
		{
			Cooldown--;
		}
		if (!Amount)
		{
			Destroy();
		}
	}

	override void SyncAmount()
	{
		if (Amount<1)
		{
			Destroy();
			return;
		}
		Super.SyncAmount();

		for (int i = 0; i < Amount; i++)
		{
			Mags[i] = Mags[i] >= 1000 ? max(Mags[i], 1001) : min(Mags[i], HDCONST_GARRISONARMOUR);
		}
		CheckMega();
	}

	override Inventory CreateTossable(int amt)
	{
		let sct = Super.CreateTossable(amt);
		if (self)
		{
			CheckMega();
		}
		return sct;
	}

	bool CheckMega()
	{
		Mega = Mags.Size() && Mags[Mags.Size() - 1] > 1000;
		icon = TexMan.CheckForTexture(Mega ? "ARMCB0" : "ARMSB0", TexMan.Type_MiscPatch);
		return Mega;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		Cooldown = 0;
	}

	override void Consolidate() {}
	override double GetBulk()
	{
		SyncAmount();
		double blk = 0;
		for (int i = 0; i < Amount; i++)
		{
			blk += Mags[i] >= 1000 ? ENC_BATTLEARMOUR : ENC_GARRISONARMOUR;
		}
		return blk;
	}

	override bool BeforePockets(Actor other)
	{
		//put on the armour right away
		if (other.player && other.player.cmd.buttons & BT_USE && !other.FindInventory('HDArmourWorn'))
		{
			wornlayer = STRIP_ARMOUR;
			bool intervening = HDPlayerPawn.CheckStrip(other, self, 0) != CSResult_Nothing;
			wornlayer = 0;

			if (intervening)
			{
				return false;
			}

			HDArmour.ArmourChangeEffect(other, 110);
			let worn = HDArmourWorn(other.GiveInventoryType('HDArmourWorn'));
			int durability = Mags[Mags.Size() - 1];
			if (durability >= 1000)
			{
				durability -= 1000;
				worn.Mega = true;
			}
			worn.Durability = durability;
			Destroy();
			return true;
		}
		return false;
	}

	override void ActualPickup(Actor other, bool silent)
	{
		Cooldown = 0;
		if (!other)
		{
			return;
		}

		int durability = Mags[Mags.Size() - 1];
		HDArmour arm = HDArmour(other.FindInventory("HDArmour"));

		//one Megaarmour = 2 regular armour
		if (arm)
		{
			double totalbulk = (Durability >= 1000) ? 2. : 1.0;
			for (int i = 0; i < arm.Mags.Size(); i++)
			{
				totalbulk += (arm.Mags[i] >= 1000) ? 2.0 : 1.0;
			}
			if (totalbulk * HDMath.GetEncumbranceMult() > 3.0)
			{
				return;
			}
		}
		if (!TryPickup(other))
		{
			return;
		}
		arm = HDArmour(other.FindInventory("HDArmour"));
		arm.SyncAmount();
		arm.Mags.Insert(0, Durability);
		arm.Mags.Pop();
		arm.CheckMega();
		other.A_StartSound(pickupsound, CHAN_AUTO);
		HDPickup.LogPickupMessage(other, pickupmessage());
	}

	static void ArmourChangeEffect(Actor owner, int delay = 25)
	{
		owner.A_StartSound("weapons/pocket", CHAN_BODY);
		owner.vel.z += 1.0;
		let onr = HDPlayerPawn(owner);
		if (onr)
		{
			onr.stunned += 90;
			onr.striptime = delay;
			onr.AddBlackout(256, 96, 128);
		}
		else
		{
			owner.A_SetBlend("00 00 00", 1, 6, "00 00 00");
		}
	}

	bool Mega;
	int Cooldown;

	Default
	{
		+INVENTORY.INVBAR
		+HDPICKUP.CHEATNOGIVE
		+HDPICKUP.NOTINPOCKETS
		+INVENTORY.ISARMOR
		HDPickup.WornLayer STRIP_ARMOUR;
		Inventory.Amount 1;
		HDMagAmmo.MaxPerUnit (HDCONST_BATTLEARMOUR+1000);
		HDMagAmmo.MagBulk ENC_GARRISONARMOUR;
		Tag "Armour";
		Inventory.Icon "ARMSB0";
		Inventory.PickupMessage "Picked up the garrison armour.";
	}

	States
	{
		Spawn:
			ARMS A 0 NoDelay
			{
				invoker.CheckMega();
			}
			ARMS A -1 A_JumpIf(invoker.Mega, 1);
			ARMC A -1;
			Stop;
		Use:
			TNT1 A 0 A_WearArmour();
			Fail;
	}
}

class HDArmourWorn : HDDamageHandler
{
	int Durability;
	bool Mega;
	property IsMega : Mega;

	Default
	{
		+INVENTORY.ISARMOR
		HDArmourWorn.IsMega false;
		Inventory.MaxAmount 1;
		Tag "Garrison Armour";
		HDDamageHandler.Priority 0;
		HDPickup.WornLayer STRIP_ARMOUR;
	}
	override void BeginPlay()
	{
		Durability = Mega ? HDCONST_BATTLEARMOUR : HDCONST_GARRISONARMOUR;
		Super.BeginPlay();
		if (Mega)SetTag("Battle Armour");
	}
	override void postbeginplay()
	{
		Super.Postbeginplay();
		if (Mega)settag("Battle Armour");
	}
	override double RestrictSpeed(double speedcap)
	{
		return min(speedcap, Mega ? 2.0 : 3.0);
	}
	override double GetBulk()
	{
		return Mega ? (ENC_BATTLEARMOUR * 0.16) : (ENC_GARRISONARMOUR * 0.1);
	}

	override bool IsBeingWorn()
	{
		return true;
	}

	override void DrawHudStuff(HDStatusBar sb, HDPlayerPawn hpl, int hdflags, int gzflags)
	{
		vector2 coords = (hdflags & HDSB_AUTOMAP) ? (4, 86) : (hdflags & HDSB_MUGSHOT) ? ((sb.hudlevel == 1 ? -85 : -65), -4) : (0, -sb.mIndexFont.mFont.GetHeight() * 2);
		string armoursprite = Mega ? "ARMCA0" : "ARMSA0";
		string armourback = Mega?"ARMER1" : "ARMER0";
		sb.DrawBar(armoursprite, armourback, Durability, Mega ? HDCONST_BATTLEARMOUR : HDCONST_GARRISONARMOUR, coords, -1, sb.SHADER_VERT, gzflags);
		sb.DrawString(sb.pnewsmallfont, sb.FormatNumber(Durability), coords + (10, -7), gzflags | sb.DI_ITEM_CENTER | sb.DI_TEXT_ALIGN_RIGHT, Font.CR_DARKGRAY, scale: (0.5, 0.5));
	}

	override Inventory CreateTossable(int amt)
	{
		if (!HDPlayerPawn.CheckStrip(owner, self))
		{
			return null;
		}

		//armour sometimes crumbles into dust
		if (Durability < random(1, 3))
		{
			for (int i = 0; i < 10; i++)
			{
				Actor aaa = spawn("WallChunk", owner.pos + (0, 0, owner.height - 24), ALLOW_REPLACE);
				vector3 offspos=(frandom(-12, 12), frandom(-12, 12), frandom(-16, 4));
				aaa.setorigin(aaa.pos + offspos, false);
				aaa.vel = owner.vel + offspos * frandom(0.3, 0.6);
				aaa.scale *= frandom(0.8, 2.0);
			}
			Destroy();
			return null;
		}

		//finally actually take off the armour
		let tossed = HDArmour(owner.spawn("HDArmour", (owner.pos.xy, owner.pos.z + owner.height - 20), ALLOW_REPLACE));
		tossed.Mags.Clear();
		tossed.Mags.Push(Mega ? Durability + 1000 : Durability);
		tossed.Amount = 1;
		tossed.CheckMega();
		HDArmour.ArmourChangeEffect(owner, 90);
		Destroy();
		return tossed;
	}

	States
	{
		Spawn:
			TNT1 A 0;
			Stop;
	}


	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int, name, int, int, int, int, int HandleDamage(int damage, name mod, int flags, Actor inflictor, Actor source, int towound, int toburn, int tostun, int tobreak)
	{
		let victim = owner;

		//approximation of "thickness" of armour
		int alv = Mega ? 3 : 1;

		if ((flags & DMG_NO_ARMOR) || mod == 'staples' || mod == 'maxhpdrain' || mod == 'internal' || mod == 'jointlock' || mod == 'falling' || mod == 'slime' || mod == 'bleedout' || mod == 'drowning' || mod == 'poison' || mod == 'electrical' || Durability < random(1, 8) || !victim)
		{
			return damage, mod, flags, towound, toburn, tostun, tobreak;
		}


		//which is just a vest not a bubble...
		if (inflictor && inflictor.Default.bMISSILE)
		{
			double impactheight = inflictor.pos.z + inflictor.height * 0.5;
			double shoulderheight = victim.pos.z + victim.height - 16;
			double waistheight = victim.pos.z + victim.height * 0.4;
			double impactangle = AbsAngle(victim.angle, victim.angleto(inflictor));
			if (impactangle > 90)
			{
				impactangle = 180 - impactangle;
			}
			bool shouldhitflesh = (impactheight > shoulderheight || impactheight < waistheight || impactangle > 80) ? !random(0, 5) : !random(0, 31);
			if (shouldhitflesh)
			{
				alv = 0;
			}
			else if (impactangle > 80)
			{
				alv = random(1, alv);
			}
		}

		//missed the armour entirely
		if (alv < 1)
		{
			return damage, mod, flags, towound, toburn, tostun, tobreak;
		}

		//some numbers
		int tobash = 0;
		int armourdamage = 0;

		int resist = 0;
		if (Durability < HDCONST_BATTLEARMOUR)
		{
			int breakage = HDCONST_BATTLEARMOUR - Durability;
			resist -= random(0, breakage);
		}

		int originaldamage = damage;


		switch (mod)
		{
			case 'hot':
			case 'cold':
			{
				if (random(0, alv))
				{
					damage = max(random(0, 1 - random(0, alv)), damage - 30);
					if (!random(0, 200 - damage))
					{
						armourdamage += (damage >> 3);
					}
				}
				break;
			}
			case 'piercing':
			{
				resist += 30 * (alv + 1);
				if (resist > 0)
				{
					damage -= resist;
					tobash = min(originaldamage, resist) >> 3;
				}
				armourdamage = random(0, originaldamage >> 2);
				break;
			}
			case 'slashing':
			{
				resist += 100 + 25 * alv;
				if (resist > 0)
				{
					damage -= resist;
					tobash = min(originaldamage, resist) >> 2;
				}
				armourdamage = random(0, originaldamage >> 2);
				break;
			}
			case 'teeth':
			case 'claws':
			case 'natural':
			{
				resist += random((alv << 4), 100 + 50 * alv);
				if (resist > 0)
				{
					damage -= resist;
					tobash = min(originaldamage, resist) >> 3;
				}
				armourdamage = random(0, originaldamage >> 3);
				break;
			}
			case 'balefire':
			{
				if (random(0, alv))
				{
					towound -= max(1, damage >> 2);
					armourdamage = random(0, damage >> 2);
				}
				break;
			}
			case 'bashing':
			case 'melee':
			{
				armourdamage = clamp((originaldamage>>3), 0, random(0, alv));

				//player punch to head
				bool headshot = inflictor && ((inflictor.player && inflictor.pitch < -3.2) || (HDHumanoid(inflictor) && damage > 50));
				if (!headshot)
				{
					damage = int(damage * (1.0 - (alv * 0.1)));
				}
				break;
			}
			default:
			{
				//any other damage not taken care of above
				resist += 50 * alv;
				if (resist > 0)
				{
					damage -= resist;
					tobash = min(originaldamage, resist) >> random(0, 2);
				}
				armourdamage = random(0, originaldamage >> random(1, 3));
				break;
			}
		}

		if (hd_debug)
		{
			Console.Printf(owner.GetTag().."  took "..originaldamage.." "..mod.." from "..(source ? source.GetTag() : "the world")..((inflictor && inflictor != source) ? ("'s "..inflictor.GetTag()) : "").."  converted "..tobash.."  final "..damage.."   lost "..armourdamage);
		}

		//set up attack position for puff and knockback
		vector3 puffpos = victim.pos;
		if (inflictor && inflictor != source)
		{
			puffpos = inflictor.pos;
		}
		else if (source&&source.pos.xy!=victim.pos.xy)
		{
			puffpos = (victim.pos.xy + victim.radius * (source.pos.xy - victim.pos.xy).unit(), victim.pos.z + min(victim.height, source.height * 0.6));
		}
		else
		{
			puffpos = (victim.pos.xy, victim.pos.z + victim.height * 0.6);
		}

		//add some knockback even when target unhurt
		if (damage < 1 && tobash < 1 && victim.health > 0 && victim.height > victim.radius * 1.6 && victim.pos != puffpos)
		{
			victim.vel += (victim.pos - puffpos).unit() * 0.01 * originaldamage;
			let hdp = HDPlayerPawn(victim);
			if (hdp && !hdp.incapacitated)
			{
				hdp.hudbobrecoil2 += (frandom(-5.0, 5.0), frandom(2.5, 4.0)) * 0.01 * originaldamage;
				hdp.PlayRunning();
			}
			else if (random(0, 255) < victim.painchance)
			{
				HDMobBase.ForcePain(victim);
			}
		}

		//armour breaks up visibly
		if (armourdamage>3)
		{
			Actor ppp = Spawn('FragPuff', puffpos);
			ppp.vel += victim.vel;
		}
		if (armourdamage > random(0, 2))
		{
			vector3 prnd = (frandom(-1, 1), frandom(-1, 1), frandom(-1, 1));
			Actor ppp = Spawn('WallChunk', puffpos + prnd);
			ppp.vel += victim.vel + (puffpos - owner.pos).unit() * 3 + prnd;
		}

		//apply stuff
		if (tobash > 0)
		{
			victim.DamageMobj(inflictor, source, min(tobash, victim.health - 1), 'bashing', DMG_NO_ARMOR | DMG_THRUSTLESS);
		}

		if (armourdamage > 0)
		{
			Durability -= armourdamage;
		}

		if (Durability < 1)
		{
			Destroy();
		}

		return damage, mod, flags, towound, toburn, tostun, tobreak;
	}

	//called from HDBulletActor's OnHitActor
	override double, double OnBulletImpact(HDBulletActor bullet, double pen, double penshell, double hitangle, double deemedwidth, vector3 hitpos, vector3 vu, bool hitActoristall)
	{
		let hitActor = owner;
		if (!owner)
		{
			return 0, 0;
		}
		let hdp = HDPlayerPawn(hitActor);
		let hdmb = HDMobBase(hitActor);

		//if standing right over an incap'd victim, bypass armour
		if (bullet.pitch > 80 && ((hdp && hdp.incapacitated)|| (hdmb && hdmb.frame >= hdmb.downedframe && hdmb.InStateSequence(hdmb.CurState, hdmb.ResolveState('falldown')))) && bullet.target && abs(bullet.target.pos.z - bullet.pos.z) < bullet.target.height)
		{
			return pen, penshell;
		}

		double hitheight = hitActoristall ? ((hitpos.z - hitActor.pos.z) / hitActor.height) : 0.5;

		double addpenshell = Mega ? 30 : (10 + max(0, ((Durability - 120) >> 3)));

		//poorer armour on legs and head
		//sometimes slip through a gap
		int crackseed = int(level.time + angle) & (1 | 2 | 4 | 8 | 16 | 32);
		if (hitheight > 0.8)
		{
			if ((hdmb&&!hdmb.bhashelmet))
			{
				addpenshell=-1;
			}
			else
			{
				//face?
				if (crackseed>clamp(Durability, 1, 3) && AbsAngle(bullet.angle, hitActor.angle) > (180.0 -5.0) && bullet.pitch > -20 && bullet.pitch < 7)
				{
					addpenshell *= frandom(0.1, 0.9);
				}
				else
				{
					//head: thinner material required
					addpenshell = min(addpenshell, frandom(10, 20));
				}
			}
		}
		else if (hitheight < 0.4)
		{
			//legs: gaps and thinner (but not that much thinner) material
			if (crackseed > clamp(Durability, 1, 8))
			{
				addpenshell *= frandom(frandom(0, 0.9), 1.);
			}
		}
		else if (crackseed>max(Durability, 8))
		{
			//torso: just kinda uneven
			addpenshell *= frandom(0.8, 1.1);
		}

		int armourdamage = 0;

		if (addpenshell>0)
		{
			//degrade and puff
			double bad = min(pen, addpenshell) * bullet.stamina * 0.0005;
			armourdamage = random(-1, int(bad));

			if (!armourdamage && bad && frandom(0, Mega ? 10 : 3) < bad)
			{
				armourdamage = 1;
			}

			if (armourdamage>0)
			{
				Actor p = Spawn(armourdamage > 2 ? 'FragPuff' : 'WallChunk', bullet.pos, ALLOW_REPLACE);
				if (p)
				{
					p.vel = hitActor.vel - vu * 2 +(frandom(-1, 1), frandom(-1, 1), frandom(-1, 3));
				}
			}
			else if (pen > addpenshell)
			{
				armourdamage = 1;
			}
		}
		else if (addpenshell > -0.5)
		{
			//bullet leaves a hole in the webbing
			armourdamage += max(random(0, 1), (bullet.stamina >> 7));
		}
		else if (hd_debug)
		{
			console.printf("missed the armour!");
		}

		if (hd_debug)
		{
			console.Printf(hitActor.GetClassName().."  armour resistance:  "..addpenshell);
		}
		penshell += addpenshell;


		//add some knockback even when target unhurt
		if (pen > 2 && penshell > pen && hitActor.health > 0 && hitActoristall)
		{
			hitActor.vel += vu * 0.001 * hitheight * mass;
			if (hdp && !hdp.incapacitated)
			{
				hdp.hudbobrecoil2 += (frandom(-5.0, 5.0), frandom(2.5, 4.0)) * 0.01 * hitheight * Mass;
				hdp.PlayRunning();
			}
			else if (random(0, 255) < hitActor.PainChance)
			{
				HDMobBase.ForcePain(hitActor);
			}
		}

		if (armourdamage > 0)
		{
			Durability -= armourdamage;
		}

		if (Durability <1)
		{
			Destroy();
		}

		return pen, penshell;
	}
}

class BattleArmour:HDPickupGiver replaces BlueArmor{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "Battle Armour"
		//$Sprite "ARMCA0"
		+missilemore
		+HDPickup.fitsinbackpack
		+Inventory.isarmor
		Inventory.icon "ARMCA0";
		HDPickupgiver.pickuptogive "HDArmour";
		HDPickup.bulk ENC_BATTLEARMOUR;
		HDPickup.refid HDLD_ARMB;
		tag "battle armour (spare)";
		Inventory.pickupmessage "Picked up the battle armour.";
	}
	override void configureActualPickup(){
		let aaa = HDArmour(actualitem);
		aaa.Mags.clear();
		aaa.Mags.push(bmissilemore?(1000+HDCONST_BATTLEARMOUR):HDCONST_GARRISONARMOUR);
		aaa.SyncAmount();
	}
}
class GarrisonArmour:BattleArmour replaces GreenArmor{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "Garrison Armour"
		//$Sprite "ARMSA0"
		-missilemore
		Inventory.icon "ARMSA0";
		HDPickup.bulk ENC_GARRISONARMOUR;
		HDPickup.refid HDLD_ARMG;
		tag "garrison armour (spare)";
		Inventory.pickupmessage "Picked up the garrison armour.";
	}
}


class BattleArmourWorn:HDPickup{
	default{
		+missilemore
		-HDPickup.fitsinbackpack
		+Inventory.isarmor
		HDPickup.refid HDLD_ARWB;
		tag "battle armour";
		Inventory.MaxAmount 1;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if (owner){
			owner.A_GiveInventory("HDArmourWorn");
			let ga = HDArmourWorn(owner.FindInventory("HDArmourWorn"));
			ga.Durability=(bmissilemore?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR);
			ga.Mega = bmissilemore;
		}
		Destroy();
	}
}
class GarrisonArmourWorn:BattleArmourWorn{
	default{
		-missilemore
		-HDPickup.fitsinbackpack
		Inventory.icon "ARMCB0";
		HDPickup.refid HDLD_ARWG;
		tag "garrison armour";
	}
}
