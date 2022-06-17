//-------------------------------------------------
// Equipped gear and damage handling
//-------------------------------------------------

//put your socks on before your shoes.
//any wearable gadget should be added to this function.
//see backpack for the minimum setup required.
enum CheckStripResult
{
	CSResult_Invalid,
	CSResult_OnCooldown,
	CSResult_Nothing,
	CSResult_LayerBlocked
}

enum CheckStripFlags
{
	CSF_Remove = 1
}

extend class HDPlayerPawn
{
	int striptime;
	static int CheckStrip(Actor caller, Inventory checkitem, int flags = CSF_Remove)
	{
		if (!checkitem && !(flags & CSF_Remove))
		{
			return CSResult_Invalid;
		}

		let hdp = HDPlayerPawn(caller);
		if (hdp && hdp.striptime > 0)
		{
			return CSResult_OnCooldown;
		}

		let pkp = HDPickup(checkitem);
		let wpn = HDWeapon(checkitem);

		Inventory preventory = null;

		//the thing in your hands in front of you is always the top layer
		if (caller.player && HDWeapon(caller.player.ReadyWeapon) && HDWeapon(caller.player.ReadyWeapon).IsBeingWorn() && caller.player.ReadyWeapon != checkitem)
		{
			preventory = caller.player.ReadyWeapon;
		}
		else
		{
			for (let next = caller.inv; next != null; next = next.inv)
			{
				if (next == checkitem)
				{
					continue;
				}

				let wornPkp = HDPickup(next);
				let wornWpn = HDWeapon(next);

				if (!wornPkp && !wornWpn)
				{
					continue;
				}

				int wornLayer = wornPkp ? wornPkp.wornlayer : wornWpn.wornlayer;
				if (!checkitem)
				{
					if (wornLayer != 0 || wornWpn && wornWpn.IsBeingWorn())
					{
						preventory = next;
					}
				}
				else if (pkp || wpn)
				{
					int layer = pkp ? pkp.wornlayer : wpn.wornlayer;
					if (layer != 0 && wornLayer != 0 && wornLayer >= layer && (wornPkp && wornPkp.IsBeingWorn() || wornWpn && wornWpn.IsBeingWorn()))
					{
						preventory = next;
					}
				}
			}
		}

		if (preventory)
		{
			if (flags & CSF_Remove)
			{
				caller.DropInventory(preventory);
				caller.A_Log("Removing "..preventory.GetTag().." first.", true);
				if (hdp)
				{
					hdp.striptime = 25;
				}
			}
			return CSResult_LayerBlocked;
		}
		return CSResult_Nothing;
	}
}

enum StripArmourLevels
{
	STRIP_ARMOUR = 1000, 
	STRIP_RADSUIT = 2000, 
	STRIP_BACKPACK = 3000, 
}

//Inventory items that affect bullets and damage before they are finally inflicted on any HDMobBase or HDPlayerPawn
//New class to avoid searching through all your ammo, consumables, etc. each time
class HDDamageHandler:HDPickup
{
	//determines order in which damage handlers are called
	//higher is earlier
	double priority;
	property priority: priority;

	Default
	{
		-INVENTORY.INVBAR
		-HDPICKUP.FITSINBACKPACK
		+HDPICKUP.NOTINPOCKETS
		+HDPICKUP.NEVERSHOWINPICKUPMANAGER
	}

	//called from HDPlayerPawn and HDMobBase's DamageMobj
	//should modify amount and kind of damage
	virtual int, name, int, int, int, int, int HandleDamage(int damage, name mod, int flags, actor inflictor, actor source, int towound = 0, int toburn = 0, int tostun = 0, int tobreak = 0)
	{
		return damage, mod, flags, towound, toburn, tostun, tobreak;
	}
	virtual int, name, int, int, int, int, int, int HandleDamagePost(int damage, name mod, int flags, actor inflictor, actor source, int towound = 0, int toburn = 0, int tostun = 0, int tobreak = 0, int toaggravate = 0)
	{
		return damage, mod, flags, towound, toburn, tostun, tobreak, toaggravate;
	}

	//called from HDBulletActor's OnHitActor
	//should modify the bullet itself - then let it inflict damage
	virtual double, double OnBulletImpact(HDBulletActor bullet, double pen, double penshell, double hitangle, double deemedwidth, vector3 hitpos, vector3 vu, bool hitactoristall)
	{
		return pen, penshell;
	}

	//get a list of damage handlers from an actor's inventory
	//higher priority numbers are listed (and thus processed) before lower numbers
	static void GetHandlers(actor owner, out array<HDDamageHandler> handlers)
	{
		handlers.Clear();
		if (!owner)
		{
			return;
		}

		for (let item = owner.inv; item != NULL; item = item.inv)
		{
			let handler = HDDamageHandler(item);
			if (!handler)
			{
				continue;
			}

			bool didInsert = false;
			for (int i = 0; i < handlers.Size(); i++)
			{
				if (handlers[i].priority < handler.priority)
				{
					handlers.Insert(i, handler);
					didInsert = true;
					break;
				}
			}
			if (!didInsert)
			{
				handlers.Push(handler);
			}
		}
	}
}
