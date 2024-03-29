# Hideous Destructor [AceCorp Bootleg]
If you're reading this, you already know what the fuck this mod is and how to load it.

# A final note from me
I've moved on from HD. No, this isn't like the last fifty times that Ace Quits Modding. I've already moved on to working on a different and far more interesting project where I am not limited by the severe retardation of someone else. That's possibly the main reason this repository and my addons are even public again. Everything I have ever touched in the HDest namespace is hereby officially discontinued and the latest versions are up for grabs.

At the time of this writing (2022/07/04) the bootleg is somewhat outdated. The addons will only work with this. Some other mods won't work with it at all because I took some creative liberties when I needed functionality on the addon side of things. Meanwhile, most of my addons will not work with the master branch of HD. So you have a choice here: play with my up-to-date mods on an outdated and possibly superior fork of HD but without many of the addons you might normally play with, or play on master without my stuff and completely ignore that this thing exists. Or wait for someone completely unhinged to fix them. Good luck with that. You'll need it.

With this, I consider my HDest saga concluded. You will not hear from me ever again because frankly I want nothing to do with you. I know the feeling is mutual.

### Things that I have not ported and will not port, ever, in no particular order
---
- 7.76 recasts;
- New archviles;
- New bronto;
- New wound system;
- Breakable windows;
- New blur. It's trash, get over it;
- Woke shit. Keep your politics and personal views out of games and mods.

### Things that are different (might be missing a few things)
---
- Various optimizations. More to come as more bottlenecks are spotted:
	- Barrels have been optimized and explosions will no longer grind the game to a halt;
	- SectorDamageCounter has been refactored to use a thinker instead of an actor;
	- HDSmoke has its own STATNUM which vastly improved ThinkerIterator performance;
- Various modding extensions:
	- Pressing* can now be called from weapon context such as Tick overrides on the weapon itself rather than being locked to states;
	- Radsuits can be used by NPCs;
	- A_Immolate can check sight;
	- HDAmBoxList::RemoveClass (static) and HDBackpack::RemoveClass for quick removal of items;
	- Shields now use SOLID flag to make them impenetrable until depleted.
	- Shield regen amount per cycle can be set using the Speed property.
- Various bugfixes:
	- Fixed extremely rare desync that happens if one player has CRLF line endings while the other has only LF;
	- Fixed desync if hd_helptext is different for one player;
	- Fixed damage factors not being taken into account for the purpose of bodydamage, rendering the entire concept of damage factors pointless;
	- A_HDBlast's pushing actually works now;
	- Bloodbags don't immediately come off if another player puts one on you while you're incapped;
	- BossBrain does not cause a VM abort with followers sometimes when loading save games;
	- Checkin names are not multiplied in co-op;
	- Scopes aren't tiny on WADs that supply their own CONFONT (1) lump;
	- Fixed an obscure bug where the pistol firing animation would hang when holding down the fire button;
	- Dormant monsters will no longer wake up and attack you while staying dormant and thus invincible;
	- IEDs won't blow up on dormant monsters;
- Various tweaks:
	- Rebalanced spiritual armor. Reduces damage under 144 by a factor of 2^layers but does not prevent dying. Blocked damage stacks (stack goes down over time) and upon reaching a specific threshold you lose a layer. Any damage above 144 instantly strips a layer. Each time you lose a layer, you become ethereal for several seconds. Enemies stop targeting you, you become impervious to damage and also gain flight to allow you to reposition yourself to safety. Make it count;
	- You can pick stuff up while incapped;
	- Living actor climbing is slightly less insufferable;
	- 90 seconds of air supply underwater instead of the standard 20.
	- NVGs Modern Green is now Modern Cyan and Modern Green is actually fucking green;
	- Invisibility does not hide NVGs' effect, only the overlay;
	- NVGs don't fuck with your FOV.
	- Archviles take less time on average to reappear and they die faster (5 pains instead of 7);
	- Reduced jetpack volume;
	- Increased .355 spawn rate;
	- Fists don't punch if you switch to them while holding fire;
	- You don't need to bash reload to repair *ERPs;
	- Inventory icons are forcefully scaled to fit;
	- Zerk cooloff is a bit shorter and health regeneration amount is increased;
	- No zerk messages;
- Miscellaneous:
	- Corruption Cards support. Somewhat. Removes cards that do not mix well with CC;

### Clarifications
---
(1) HDest uses the existence of the CONFONT lump to check for the now-deprecated LZDoom, but it just so happens that anything that provides a CONFONT will make HD think you're running LZDoom. The solution? Remove that code because nobody fucking uses LZDoom anymore.