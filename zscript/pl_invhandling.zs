// ------------------------------------------------------------
// The cause of - and solution to -
// ------------------------------------------------------------

extend class HDPlayerPawn
{
	//Do downtime management between maps
	void ConsolidateAmmo()
	{
		//temporarily increase maxpocketspace to avoid overflow during consolidation process
		double mppsbak = maxpocketspace;
		maxpocketspace *= 1000;

		//call all the Consolidates on actors
		for (Inventory ppp = inv; ppp != null; ppp = ppp.inv)
		{
			let hdp = hdpickup(ppp);
			if (hdp)
			{
				hdp.consolidate();
			}
			let hdw = hdweapon(ppp);
			if (hdw)
			{
				hdw.consolidate();
			}
		}
		maxpocketspace = mppsbak;
	}

	Array<HDPickup> OverlayGivers;
	void GetOverlayGivers(out out array<HDPickup> OverlayGivers)
	{
		OverlayGivers.Clear();
		for(let item = inv; item != NULL; item = item.inv)
		{
			let hp = HDPickup(item);
			if (!hp || !hp.overlaypriority)
			{
				continue;
			}
			bool inserted = false;
			for(int i = 0; i < OverlayGivers.Size(); i++)
			{
				int checkthis = hp.overlaypriority;
				int checkthat = OverlayGivers[i].overlaypriority;
				if (checkthis >= checkthat)
				{
					OverlayGivers.Insert(i, hp);
					inserted = true;
					break;
				}
			}
			if (!inserted)
			{
				OverlayGivers.push(hp);
			}
		}
	}
}



//Specially handled ammo dropping
extend class HDHandlers
{
	//goes through all ammo, checks their lists, dumps if not found
	void PurgeUselessAmmo(HDPlayerPawn ppp)
	{
		if (!ppp)
		{
			return;
		}
		Array<inventory> items;
		items.clear();

		for (Inventory item = ppp.inv; item != null; item = item.inv)
		{
			let thisitem = HDPickup(item);
			if (thisitem && !thisitem.isused())
			{
				items.push(item);
			}
		}
		int iz = items.size();
		if (!iz)
		{
			return;
		}
		double aang = ppp.angle;
		double ch = 20;
		bool multi = iz > 1;

		if(multi)
		{
			ppp.angle -= iz * ch * 0.5;
		}
		for (int i = 0; i < items.Size(); i++)
		{
			ppp.A_DropInventory(items[i].GetClassName(), items[i].Amount);
			if (multi)
			{
				ppp.angle += ch;
			}
		}

		if (multi)
		{
			ppp.angle=aang;
		}
	}

	//drops one or more units of your selected weapon's ammo
	void DropOne(HDPlayerPawn ppp, PlayerInfo player, int amt)
	{
		if (!ppp || ppp.health < 1)
		{
			return;
		}
		let cw = HDWeapon(player.ReadyWeapon);
		if (cw)
		{
			cw.DropOneAmmo(amt);
		}
		else
		{
			PurgeUselessAmmo(ppp);
		}
	}

	//strips armour
	void ChangeArmour(HDPlayerPawn ppp)
	{
		let inva = HDPickup(ppp.findinventory("HDArmour"));
		let invb = HDPickup(ppp.findinventory("HDArmourWorn"));
		if (invb)
		{
			if (ppp.CheckStrip(ppp, invb) == CSResult_Nothing)
			{
				ppp.A_Log("Removing "..invb.GetTag()..".",true);
				ppp.DropInventory(invb);
				return;
			}
		}
		else if (inva)
		{
			ppp.UseInventory(inva);
		}
		else
		{
			ppp.CheckStrip(ppp, null);
		}
	}
}

