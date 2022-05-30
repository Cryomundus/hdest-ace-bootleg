# Hideous Destructor [AceCorp Bootleg]
If you're reading this, you already know what the fuck this mod is and how to load it.

For the most part this build is the same as the master branch at any given time.

### Things that I have not ported and will not port, ever, in no particular order
---
- 7.76 recasts;
- New archviles;
- New bronto;
- New wound system;
- Breakable windows;
- Woke shit. Keep your politics and personal views out of games and mods.

### Things that are different
---
- Various optimizations. More to come as more bottlenecks are spotted.
- Various modding support:
	- Pressing* can now be called from weapon context such as Tick overrides on the weapon itself rather than being locked to states;
	- Radsuits can be used by NPCs;
	- A_Immolate can check sight;
	- HDAmBoxList::RemoveClass (static) and HDBackpack::RemoveClass for quick removal of items.
- Various bugfixes:
	- Fixed extremely rare desync that happens if one player has CRLF line endings while the other has only LF;
	- Fixed damage factors not being taken into account for the purpose of bodydamage, rendering the entire concept of damage factors pointless;
	- A_HDBlast's pushing actually works now;
	- Bloodbags don't immediately come off if another player puts one on you while you're incapped;
	- BossBrain does not cause a VM abort with followers sometimes when loading save games;
	- Checkin names are not multiplied in co-op;
	- Firing weapons while zerked does not zoom in/out so much;
	- Scopes aren't tiny on WADs that supply their own CONFONT (1) lump.
- Various tweaks:
	- Archviles only need 4 times to be pained in order to die instead of 6.
	- You can pick stuff up while incapped;
	- Living actor climbing is less insufferable;
	- 90 seconds of air supply underwater instead of the standard 20.
	- NVGs Modern Green is now Modern Cyan and Modern Green is actually fucking green.
	- Invisibility does not hide NVGs' effect, only the overlay;
	- NVGs don't fuck with your FOV.
	- Standard Commander Keen sprites;
	- Archviles take less time on average to reappear and they die faster;
	- Reduced jetpack volume;
	- Increased .355 spawn rate;
	- Fists don't punch if you switch to them while holding fire;
	- You don't need to bash reload to repair *ERPs;
	- Inventory icons are forcefully scaled to fit.
- Miscellaneous:
	- Corruption Cards support. Somewhat. Removes cards that do not mix well with CC.

### Clarifications
---
(1) HDest uses the existence of the CONFONT lump to check for the now-deprecated LZDoom, but it just so happens that anything that provides a CONFONT will make HD think you're running LZDoom. The solution? Remove that code because nobody fucking uses LZDoom anymore.