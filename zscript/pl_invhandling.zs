// ------------------------------------------------------------
// The cause of - and solution to -
// ------------------------------------------------------------

extend class HDPlayerPawn{
	//Do downtime management between maps
	void ConsolidateAmmo(){
		//temporarily increase maxpocketspace to avoid overflow during consolidation process
		double mppsbak = maxpocketspace;
		maxpocketspace *= 1000;

		//call all the Consolidates on actors
		for(inventory ppp = inv;ppp != null;ppp = ppp.inv){
			let hdp = hdpickup(ppp);
			if (hdp)hdp.consolidate();
			let hdw = hdweapon(ppp);
			if (hdw)hdw.consolidate();
		}
		maxpocketspace = mppsbak;
	}


	array < HDPickup> OverlayGivers;
	void GetOverlayGivers(out out array < HDPickup> OverlayGivers){
		OverlayGivers.clear();
		for(let item = inv;item != NULL;item = item.inv){
			let hp = HDPickup(item);
			if (
				!hp
				||!hp.overlaypriority
			)continue;
			bool inserted = false;
			for(int i = 0;i < OverlayGivers.size();i++){
				int checkthis = hp.overlaypriority;
				int checkthat = OverlayGivers[i].overlaypriority;
				if (checkthis >= checkthat){
					OverlayGivers.insert(i, hp);
					inserted = true;
					break;
				}
			}
			if (!inserted)OverlayGivers.push(hp);
		}
	}
}



//Specially handled ammo dropping
extend class HDHandlers{
	//goes through all ammo, checks their lists, dumps if not found
	void PurgeUselessAmmo(HDPlayerPawn ppp){
		if (!ppp)return;
		array < inventory> items;items.clear();
		for(inventory item = ppp.inv;item != null;item=!item?null:item.inv){
			let thisitem = hdpickup(item);
			if (thisitem&&!thisitem.isused())items.push(item);
		}
		int iz = items.size();
		if (!iz)return;
		double aang = ppp.angle;
		double ch = 20;
		bool multi = iz > 1;
		if (multi)ppp.angle -= iz * ch * 0.5;
		for(int i = 0;i < items.size();i++){
			ppp.a_dropinventory(items[i].getclassname(), items[i].Amount);
			if (multi)ppp.angle += ch;
		}
		if (multi)ppp.angle = aang;
	}
	//drops one or more units of your selected weapon's ammo
	void DropOne(HDPlayerPawn ppp, playerinfo player, int amt){
		if (!ppp||ppp.health < 1)return;
		let cw = hdweapon(player.readyweapon);
		if (cw)cw.DropOneAmmo(amt);
		else PurgeUselessAmmo(ppp);
	}
	//strips armour
	void ChangeArmour(HDPlayerPawn ppp){
		let inva = HDPickup(ppp.FindInventory("HDArmour"));
		let invb = HDPickup(ppp.FindInventory("HDArmourWorn"));
		if (invb){
			if (ppp.CheckStrip(ppp, invb)){
				ppp.A_Log("Removing "..invb.gettag()..".", true);
				ppp.dropinventory(invb);
			}
			return;
		}else if (inva)ppp.UseInventory(inva);
		else ppp.CheckStrip(ppp, ppp);
	}
}

