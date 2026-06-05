# JH_MoreHellishHumans

Jupiter Hell mod to expand hellish humans line in **trials**. It adds pistol/smg/shotgun-wielding troops that are capable of remaining (situationally) dangerous even in long games. Also adds them to Io Black Site in base game mode, since that branch already features hellish humans in unmodded game. Adds a rail turret as well (but this one only to trials).

The new additions will feature in Endless, Gauntlet, and Completionist trials (the latter is available through a mod by Sihoiba, rather than being distributed with a game), adding variety to those game modes where it is needed most. They may appear in some other trials if trial code does not discriminate against spawning formers and has high-enough depth levels (but Purity and Haste do prevent humans in Beyond branch from spawning). The earliest new enemies can appear on UV is Endless L11 (on Inferno! -- Endless L8), although the average (per my tests) debut on UV is Endless L13 and third *branch* (out of 4) of Callisto of Completionist trial. 

## Installing

Create a mods folder in your Jupiter Hell game directory if doesn't exist then add the folder there; for Mac users, navigate to your Jupiter Hell app, right click, select "show package contents", navigate to Contents > MacOS, and put the downloaded mod folder into mods folder found there.

Compatible with Jupiter Hell 1.8 and hopefully will stay compatible with all later versions. Didn't test on JH 1.9 yet (waiting for a GOG release; will be gathering feedback on JH's official Discord server in meanwhile). Might work on 1.7, too (not tested either). 

## Enemy details

New enemies have custom behavior, identified as follows:

- **hellish marksman**. A **pistol/revolver**-wielding sharpshooter that **can crit** (if you are wearing visors instead of helmets). Moves around a bit faster than regular formers. If you disengage from battle, he will camp in his position *if* it provides good cover in his opinion, instead of pursuing you. Occassionally might Aim (and he has Aim Assist on his armor), and once aimed, his Aim doesn't decay unless he moves (as if having Cover Master L2). Hunker support is on to-do list.
- **hellish sgt.major** (sergeant major). A **shotgunner with Heatvision** and **+2 to max range**, +10% to action speed. **Will shoot you in melee range** if his magazine is not empty. **May shoot you even through smoke/gas or stealth** if he is close enough, and is currently aware of you (you were recently sighted by him normally, and didn't escape his Heatvision leash afterwards - i.e. he doesn't shoot using heatvision in idle mode, as presumably the human profile you have is similar enough to one of his compatriots).
- **hellish skirmisher**. An unarmored **submachinegun**-wielding troop with **+20% action speed** and **dodge on move**. **Will shoot you in melee range** if his magazine is not empty. Does not seek out cover, tries to get close to you instead. Because hell has no use for human guards with riot shield.
- **rail turret**. Charge/reload mechanics are same as rocket turret. **Pierce damage, accurate and ignores cover**, though **shot can be dodged** (if you have high enough dodge when moving, and then it does not damage you at all). Does not aggro enemies by its shots unless converted to your side (by hacking). Unlike hellish humans which can appear in Io Black Site, this one is trial-exclusive. Current graphics both for turret and rail are placeholder (+ known issue: beam part of rail gets displayed, while the coil doesn't; only in rare circumstances it displays as intended).

Unlike in base game, hellish humans that come with this mod can spawn wielding plasma weapons.

Technically, added enemies become eligible to spawn in Callisto, Europa and Io themed levels *when* those levels occur beyond their base game mode's maximum possible depth for those moons. They also naturally spawn in Beyond on all depth levels (except rail turret that is gated by minimum depth even on Beyond), but Purity and Haste trials explicitly prevent humans and bots from spawning in Beyond, which is why (and the *only* reason why) they won't be featured there. They never spawn in Dante or Dante-themed levels in any game modes, at all -- this is deliberate design decision.

Hellish **marksmen** and **skirmishers** get to wear a random **pistol amp** (that won't drop and thus won't be available to you). Hellish marksmen additionally wear a random perk to boost crit chance, damage or max/optimal range on their armor. The armor can be shot off them and they will then lose its bonus, but the amp bonuses stays until they are dead. The game won't show you the exact bonuses they get, but rest assured these enemies will get better crit/range as you go beyond base game depth. From Endless L100 onwards, every marksman/skirmisher will have AV3 pistol amp, and every marksman will already have two (rather than one) perk on his armor beside the obligatory Aim Assist.

Marksmen and skirmishers amp power will be rendered irrelevant every time Inferno difficulty or Gauntlet overrides their weapon, but since weapons can only be replaced by naturally strong ones, there is no need to amplify them. And marksmen's hidden armor bonuses will still benefit the new weapon acquired from exalted trait.

Hellish sergeant major doesn't wear amps, but his armor gives him protection against *first 100%* of critical chance (just like your helmets, and do note the game has multi-crit). At deep levels, his armor may become augmented too (for double or infinite durability, increased protection or Powered), although this is mainly for flavor and nowhere near impact that exalted traits would have made. However, his Heatvision and max range boost are innate and not tied to armor.

## Rationale

I rather like base game balance and don't want to alter base game mode much, but trials could use some diversity. 

Some facts about unmodded game:

- hellish humans are primarly listed for Beyond moon and otherwise only spawn by request (Military Barracks, Tyre Outpost -- these list specific hellish enemies, new enemies will *not* appear there). 
- Purity and Haste trials explicitly exclude humans from spawning in Beyond levels, so I leave them alone.
- Io Black Site branch levels do use list otherwise reserved for Beyond moon, though, hence my additions will appear even in base game there.
- hellish guard is not spawned at all, as his own riot shield graphics were not finished (will use shield from other human line as a substitute)
- from the stock roster, only hellish grenadiers, hellish soldiers, hellish commandoes and hellish heavies are dangerous enough. 

Thus, in unmodded game, pistols/smgs/shotguns are underrepresented on hellish ranks, whether through enemies wielding them cutting off earlier (grunts/guards, pistol/smgs, under premise that they are weak), or just being rare in my experience (hellish sergeant / shotgun) and being low threat even then. This mod is designed to correct this issue.

## Credits

Beside ChaosForge and Epyon obviously (the devs of Jupiter Hell), I would like to personally thank:

- Deemzul for help with getting custom turret to be disabled/hacked by terminals/Remote Hack L2
- Sihoiba for including lua code for Brezenham line-of-sight check that is used in his Better Fireangel and QoL fixes, which was used there to make beam weapons properly apply Molten etc. In my mod, same technology powers hellish sergeant majors's Heatvision and his ability to shoot you through stealth and smoke.
- Also Sihoiba, for MoreExaltedPerks mod, and Cotonou for giving review of how those exalted traits perform (sergeant major's crit defence on armor and skirmisher's evasion are based on these)
- Jupiter Hell's community on Discord, as it is hard to get seriously interested in modding without people making mods and playing them, and actively discussing the game, modded or unmodded
