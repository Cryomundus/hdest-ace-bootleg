# Hideous Destructor [AceCorp Bootleg]
If you're reading this, you already know what the fuck this mod is and how to load it.

For the most part this build is the same as the master branch at any given time.

### Things that I have not ported and will not port, ever, in no particular order
---
- 7.76 recasts;
- New archviles;
- New bronto;
- Breakable windows;
- Woke shit. Keep your politics and personal views out of games and mods.

### Things that are different
---
Highlights:
- You can pick stuff up while incapped;
- Fixed extremely rare desync that happens if one player has CRLR line endings while the other has only CR.


- Various optimizations. More to come as more bottlenecks are spotted.
- Various modding support:
	- Pressing* can now be called from weapon context such as Tick overrides on the weapon itself rather than being locked to states.
- Various bugfixes and tweaks:
	- Fixed damage factors not being taken into account for the purpose of bodydamage, rendering the entire concept of damage factors pointless.
	- A_HDBlast's pushing actually works now;
	- Bloodbags don't immediately come off if another player puts one on you while you're incapped;
	- BossBrain does not cause a VM abort with followers sometimes when loading save games;
	- Radsuits can be used by NPCs now;
	- Checkin names are not multiplied in co-op;
- Various tweaks:
	- Living actor climbing is less insufferable;
	- 90 seconds of air supply underwater instead of the standard 20.
	- NVGs Modern Green is now Modern Cyan and Modern Green is actually fucking green.
	- Invisibility does not hide NVGs' effect, only the overlay;
	- Standard Commander Keen sprites;
	- Archviles take less time on average to reappear;
	- Reduced jetpack volume.