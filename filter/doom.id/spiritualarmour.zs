//-------------------------------------------------
// Not against flesh and blood.
//-------------------------------------------------
class SpiritualArmour : HDDamageHandler replaces ShieldCore
{
	static string FromPsalter()
	{
		string psss = Wads.ReadLump(Wads.CheckNumForName("psalms", 0));
		array<string> pss; pss.clear();
		psss.split(pss, "Psalm ");
		pss.delete(0); //don't get anything before "Psalm 1:1"
		string ps = pss[random(0, pss.size() - 1)];
		ps = ps.mid(ps.indexof(" ") + 1);
		ps = pscol..ps;
		ps.replace("/", "\n"..pscol);
		ps.replace("|", " ");
		ps.replace("  ", " ");
		ps.replace("\n"..pscol.." ", "\n"..pscol);
		return ps;
	}

	override void DoEffect()
	{
		if (AccumulatedDamage > 0 && GetAge() % 35 == 0)
		{
			AccumulatedDamage--;
		}
		Super.DoEffect();
	}

	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int, Name, int, int, int, int, int HandleDamage(int damage, name mod, int flags, actor inflictor, actor source, int towound, int toburn, int tostun, int tobreak)
	{
		if (mod == "bleedout")
		{
			damage = -1;
			mod = "internal";
			let hdp = hdplayerpawn(owner);
			if (hdp)
			{
				hdp.woundcount = 0;
			}
		}
		return damage, mod, flags, towound, toburn, tostun, tobreak;
	}

	override int, Name, int, int, int, int, int, int HandleDamagePost(int damage, name mod, int flags, actor inflictor, actor source, int towound, int toburn, int tostun, int tobreak, int toaggravate)
	{
		let victim = owner;
		if (!victim)
		{
			return damage, mod, flags, towound, toburn, tostun, tobreak, toaggravate;
		}

		if (damage == TELEFRAG_DAMAGE && source == victim)
		{
			GoAwayAndDie();
			return damage, mod, flags, towound, toburn, tostun, tobreak, toaggravate;
		}

		if (!random(0, 7))
		{
			HDBleedingWound.Inflict(source, random(1, 3), 1, false, victim);
		}

		//Console.Printf("%i, %i, %i, %i, %i, %i", damage, towound, toburn, tostun, tobreak, toaggravate);

		let hdp = HDPlayerPawn(victim);
		if (damage < 144)
		{
			int newDamage = max(damage >> Amount, 1);
			if (mod == 'hot' && random(0, Amount))
			{
				newDamage = 0;
			}

			// [Ace] So the way this works is that more layers means you get a ridiculous amount of damage reduction, but you are also much more prone to losing a layer.
			// The amount of damage blocked gets added up, so the more damage you absorb, the faster it builds up.
			AccumulatedDamage += damage - newDamage;

			damage = newDamage;
			tostun = min(tostun >> Amount, 7);

			if (hdp && hdp.inpain > 0)
			{
				hdp.inpain = max(hdp.inpain, 3);
				hdp.stunned = min(hdp.stunned, 350);
			}

			if (AccumulatedDamage > 777)
			{
				AccumulatedDamage = 0;
				owner.GiveBody(100);
				owner.A_GiveInventory('SpiritualArmourPower');
				Amount--;
			}
		}
		else
		{
			damage = 0;
			tostun = 0;
			owner.GiveBody(100);
			owner.A_GiveInventory('SpiritualArmourPower');
			Amount--;
		}

		return damage, mod, flags, 0, 0, tostun, 0, 0;
	}

	const pscol = "\cr";
	int AccumulatedDamage;

	Default
	{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Spiritual Armour"
		//$Sprite "BON2A0"

		+INVENTORY.ALWAYSPICKUP
		+INVENTORY.UNDROPPABLE
		+HDPICKUP.NEVERSHOWINPICKUPMANAGER
		-INVENTORY.INVBAR
		+INVENTORY.ISARMOR
		HDDamageHandler.priority -10000;
		Inventory.PickupMessage "Picked up an armour bonus.";
		Inventory.Amount 1;
		Inventory.MaxAmount 3;
		Inventory.PickupSound "misc/p_pkup";
		Scale 0.8;
	}

	States
	{
		Use:
			TNT1 A 0;
			Fail;
		Spawn: 
			BON2 A 6 A_SetTics(random(7, 144));
			BON2 BC 6 A_SetTics(random(1, 2));
			BON2 D 6 Light("ARMORBONUS") A_SetTics(random(0, 4));
			BON2 CB 6 A_SetTics(random(1, 3));
			loop;
		Pickup: 
			TNT1 A 0
			{
				A_GiveInventory("PowerFrightener");
				A_TakeInventory("HDBlurSphere");
				let hdp = HDPlayerPawn(self);
				if (hdp)
				{
					hdp.woundcount = 0;
					hdp.oldwoundcount += hdp.unstablewoundcount;
					hdp.unstablewoundcount = 0;
					hdp.aggravateddamage = max(0, hdp.aggravateddamage - 1);
					hdp.UseGameTip("\cx"..SpiritualArmour.FromPsalter());
				}
			}
			stop;
	}
}

class SpiritualArmourPower : Powerup
{
	override void InitEffect()
	{
		Super.InitEffect();

		ToggleFlags(true);

		if (owner.pos.z <= owner.floorz)
		{
			owner.vel.z = 4;
		}
	}

	override void EndEffect()
	{
		Super.EndEffect();
		if (!owner || !owner.player)
		{
			return;
		}

		ToggleFlags(false);
	}

	private void ToggleFlags(bool val)
	{
		owner.bFLY = val;
		owner.bNOGRAVITY = val;
		owner.bSHADOW = val;
		owner.bSHOOTABLE = !val;
	}

	override Color GetBlend()
	{
		return Color(int(BlendColor.a * (EffectTics / double(default.EffectTics))), BlendColor.r, BlendColor.g, BlendColor.b);
	}

	Default
	{
		Powerup.Duration -4;
		Powerup.Color "59e85b", 0.3;
		+INVENTORY.NOSCREENBLINK
		+INVENTORY.ALWAYSPICKUP
	}
}