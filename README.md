# Planet Sweepers — Phase 9

## Phase 9: lunar world look

Run `rojo serve`, connect Studio, Stop the previous session, wait for sync, then Play. Allow terrain generation to finish before checking the world. Moonlet now has deterministic chunked Terrain hills, rim craters, a pale lavender surface, black enclosure, procedural stars, Earth-like sphere, glowing sun, light post-processing, and yellow guide lines. Interaction space remains flat; the old ground Part remains an invisible collision safety floor. Other planet art remains Phase 16 work.

New art uses named colors from `Palette.lua` and builders in shared/art. Existing Phase 1–8 model/UI colors will migrate with their scheduled art phases; this phase does not claim a repo-wide palette conversion. Assets.lua contains empty override slots. MeshId uses a SpecialMesh; TextureId is applied to the mesh or a decal fallback. ModelId names a manually imported Model under ReplicatedStorage.CustomAssets, not an automatic Toolbox download. Imported model scripts are stripped. Models retain their authored scale and pivot. SoundId creates a configured Sound slot; playback is owned by later audio controllers. Empty entries require no assets. Terrain is procedural rather than a swappable model.

Terrain writes are confined to the Moonlet radius, from Y=60 upward, and do not call Terrain:Clear. Use a dedicated test place: existing user terrain within that footprint is overwritten during Play. Stop discards runtime-generated changes. Art generation is idempotent within a server. A fixed seed controls stars/craters/noise. Each four terrain columns yields to the scheduler. Decorative Parts use Decor collision group and disable touch/query/collision. Lighting is shared across this place for now; existing custom Lighting effects may stack and should be reviewed manually in the test place.

Verify in Studio:
1. Moonlet has lavender ground, a black sky, visible hills/craters, blue/green planet, and warm sun.
2. Walk all directions; check dirt remains accessible above Terrain and no guide lines are buried. Roblox voxel smoothing may need tuning after visual QA.
3. Test spawn, reset, cleaning, selling, shop, and portals. Check planet 2/3 gameplay remains functional.
4. Stop/Play twice: no duplicated art or permanent edit-time Terrain changes.
5. Check phone emulator for brightness, shadows, frame rate, and sky visibility. This build has not undergone visual/runtime QA.

Streaming: keep Workspace.StreamingEnabled off for initial sky verification. For mobile production, enable it in Studio, then test far sky objects and streamed dirt; the current large sky enclosure is not marked persistent and may disappear under streaming. A client-local/persistent sky and streaming-aware interaction pass are required before enabling it for release. Do not claim streaming readiness from a successful build alone.

Limitations: procedural spheres approximate continents, not textured Earth. Dirt/pebbles/clean patches, astronaut, tools, stations, pets, UI skin, and other planet art remain their scheduled phases. Mesh/model overrides need actual imported assets and size/budget QA. No external assets load with default configuration.

## Phase 8: monetization hooks (stubs only)

`MonetizationService` exposes GetMoneyMultiplier(player), GetBagCapacity(player, baseCapacity), and RequestPurchase(player, pass). DoubleMoney and BiggerBag are the only accepted purchase keys. Requests return NOT_IMPLEMENTED; unknown keys return INVALID_PASS. No purchase remote, prompt, ownership network call, or real gamepass ID exists in this phase. Config IDs remain 0 and Enabled remains false. Even enabling config cannot activate the intentionally false ownership stub.

The sale calculation now includes the money hook, after co-op and pet bonuses. Daily rewards are not multiplied. Manual and robot collection use effective bag capacity through the same hook; the HUD shows that capacity. Saved bagCapacity remains the permanent upgrade-derived base, preventing repeated multiplier application on rejoin. Buying bag upgrades continues updating only the base.

TODO LIVE markers describe future server-only MarketplaceService ownership checks with pcall/retries, entitlement-cache cleanup, official purchase prompts, post-purchase revalidation, and HUD republishing. Creating gamepasses and supplying actual IDs requires Creator Dashboard work. Merely entering IDs is insufficient: ownership verification is deliberately unimplemented.

Test: run `rojo serve`, Stop the previous playtest, wait for sync, and Play. With no pets/co-op, 25 Moonlet units must still sell for $25. Starting capacity remains 25, first bag upgrade makes it 40, and robots obey the same capacity. Daily reward remains $100. No purchase prompts or MarketplaceService asset/ID errors should appear.

Optional SERVER Command Bar stub checks:

```lua
local player = game:GetService("Players"):GetPlayers()[1]
local service = require(game.ServerScriptService.PlanetSweepersServer.services.MonetizationService)
assert(service.GetMoneyMultiplier(player) == 1)
assert(service.GetBagCapacity(player, 25) == 25)
local ok, code = service.RequestPurchase(player, "DoubleMoney")
assert(not ok and code == "NOT_IMPLEMENTED")
local valid, errorCode = service.RequestPurchase(player, "Unknown")
assert(not valid and errorCode == "INVALID_PASS")
```

This finishes the eight planned implementation phases, not release certification. Persistence failure cases, full multiplayer/mobile QA, performance profiling, economy timing, real audio, referenced visual assets, and live monetization integration remain outstanding. Source files contain full implementations; TODO markers apply only to explicitly requested monetization stubs. Earlier phase sections below are historical.

## Phase 7: feedback and rewards

Keep `rojo serve` connected, Stop, wait for sync, then Play. Cleaning creates a brief client-only expanding glow. Selling shows floating +$ text using the shared formatter. Pet discovery also has a floating reveal. Effects are capped at 24 concurrent instances and expire after 0.8 seconds. Sound placeholders for Clean, Sell, Reward, and Pet have empty IDs and are deliberately silent. Configure owned audio later in shared/config/Feedback; no external assets are loaded by default.

The Roblox player list now shows server-owned Money and Cleaned leaderstats, updated by profile publication. This is a current-server leaderboard, not a global ranking. The daily button below PETS awards $100 once per rolling 24 hours, available immediately to a fresh profile. The server owns time, amount, and eligibility; a rate limit blocks request spam. Claim timestamp and money change together without yielding, followed by a best-effort immediate save. The normal persistence/lease limitations still apply: a failed save can roll back both reward and timestamp together. In temporary Studio mode, Stop/Play resets the daily claim along with the entire profile.

Manual checks:
1. Clean manually and with robots. Confirm short glow effects and no accumulating Parts under LocalSweeperEffects.
2. Sell a bag. Confirm floating +$ matches the payout (compact formatting may hide fractional cents).
3. Open the Roblox player list. Money and Cleaned should track changes for multiple players.
4. Claim daily once. Money increases by $100 and the button becomes a 24-hour countdown.
5. Repeated claims must not award extra money. Test persistent leave/rejoin: countdown must remain.
6. For a separate test profile, set lastDailyReward to os.time() minus Game.DailyReward.CooldownSeconds in the SERVER Command Bar, publish state, and verify eligibility returns.
7. Test phone layout, pet reveal, reset, and GUI cleanup. Empty sound IDs must not create asset-loading errors.

Validation is build/syntax only until human Studio QA. This phase does not replace placeholder models with the supplied visual references. No global leaderboard, streak system, or real audio is included. Earlier phase notes below are historical.

## Phase 6: robots and co-op

Keep `rojo serve` connected, Stop, wait for sync, then Play. Scroll down in the blue Moonlet shop to buy Sweep Bot ($250) or Orbit Bot ($1200). Maximum three robots total. Each robot searches near its owner's character on a server timer and fills the owner's existing bag. Sweep Bot collects up to 2 units every 2 seconds within 16 studs; Orbit Bot collects up to 5 every 1.2 seconds within 24 studs. A 0.25-second scheduler quantizes these intervals. Robots stop when the bag is full, no dirt is in range, or the character is dead. They follow across portals and return after respawn/rejoin. No offline cleaning, selling, dismissing, or vehicle driving is included.

Robot requests include expected owned count to prevent duplicated purchases. The server checks type, count, distance, planet, available slots, balance, and cooldown. Robot gameplay uses the same collection transaction, depletion handling, and pet rolls as manual cleaning. Range is measured from the owner; placeholder robot blocks are cosmetic indicators.

Co-op adds 5% per additional living player on the same planet within 60 studs of the owner when dirt is collected, capped at 50%. Nearby players need not be actively cleaning. The extra value is banked in bagContents.coopValue and survives moving away or changing planets. Sell applies pet multipliers to base plus co-op value. Existing bag contents do not retroactively gain a bonus.

Manual checks:
1. Buy a Sweep Bot and stand near dirt without pressing E. Bag contents must increase on its timer.
2. Fill the bag. Robot must stop consuming dirt. Sell and verify it resumes.
3. Buy three total robots. A fourth must be disabled/rejected. Repeated purchase requests must not charge twice for the same expected count.
4. Reset, teleport, and test persistent rejoin. Robot counts remain; visible robots must not duplicate. Leave the server and confirm owned blocks disappear.
5. Start two clients, unequip pets, and empty the test player's bag. Collect 20 Moonlet units with the other living player within 60 studs. Expected sale: $21.
6. Repeat alone or with the other player farther than 60 studs: expected sale $20. Move away before selling the co-op bag: its banked bonus remains.
7. With 12 players nearby, bonus still caps at 50%. Mixed solo/co-op collections must preserve their separate accrued values.

Limitations: robot blocks move at the batched server tick, not smooth client interpolation. No live co-op percentage label yet. Performance at 16 players, runtime, multiplayer, and persistence need Studio QA. Earlier phase sections are historical.

## Phase 5: planets and portals

Keep `rojo serve` running, Stop the old playtest, allow sync, then Play again. The generated world now includes Dusty Moonlet, Crystal Desert, and Neon Swamp, spaced 600 studs apart. Each has its own spawn, recycler, dirt density/value, respawn delay, and pet pool. The shared dirt folder contains 240 pooled nodes. The grid was widened to 11 columns so the configured 100-node swamp fits.

Two glowing portals near each spawn lead to the other planets. Hold the portal prompt to purchase and travel. Crystal Desert costs $1000; Neon Swamp costs $5000 and requires Crystal Desert ownership first. Already-owned destinations are free. Prices remain visible in shared prompts with an owned/free explanation. Server independently checks living character, distance, source planet, prerequisites, cooldown, ownership, and balance. Unlock and deduction do not yield. Reset and rejoin use the saved current planet. Tool/bag shopping remains on Dusty Moonlet; return via its free portal.

Manual checks:
1. At insufficient funds, use an unlock portal: no money loss or teleport.
2. Earn $1000, unlock Crystal Desert, and confirm money decreases exactly once. HUD must show Crystal Desert.
3. Collect 10 desert units: their base sale value is $30 before pet bonuses. Moonlet units retain their original value when carried through a portal.
4. Return to Moonlet and revisit Desert: travel must be free.
5. Unlock Neon Swamp for $5000 after Desert. Ten swamp units have $80 base value.
6. Reset on each planet and confirm the same planet spawn. Test persistent rejoin using the TEST DataStore instructions below.
7. Verify planet-specific pet species, dirt respawn, and selling at all three recyclers.
8. Test multiplayer: one player's unlock must not unlock the planet for another player.

For accelerated Studio QA, use the SERVER Command Bar to set the test profile's money to 6000 and publish state, following the existing profile mutation example below. No client currency/debug remote was added.

Limitations: generated flat zones and placeholder portals; no unlock shop tab yet. Rejected portal attempts are silent. Referenced visuals remain future work. Live gameplay, mobile, multiplayer, and DataStore round trips still need human testing. Earlier phase sections below are historical.

## Phase 4: hidden pets

Seven screenshots in `REFERENSI ASET` are reserved as visual references for later work. Phase 4 uses generated sphere placeholders.

Stop Play, keep `rojo serve` connected, wait for sync, and Play again. The PETS button opens inventory, equip controls, discovery rates, variants, and the cross-planet species index. Only Dusty Moonlet is playable in this phase.

Each depleted node rolls once for the player performing its final action. Discovery chance is 1.5%. Conditional rarities are Common 60%, Rare 25%, Epic 10%, Legendary 4%, and Mythic 1%. Variants are independent and mutually exclusive: Normal 97.5%, Gold 2%, Rainbow 0.5%. Species are uniform within their planet/rarity pool. UI calculates both conditional and per-node odds from config. Inventory is capped at 200; full inventories receive no drops. Duplicates are allowed. Pets are not automatically equipped.

Equip up to three pets anywhere; no station/distance requirement applies to inventory management. Server checks request cooldown, action, pet ID ownership, duplicates, and slot capacity. All rolls and income calculations are server-owned. Sell multiplier is `1 + sum(rarity.incomeBonus * variant.bonusMultiplier)` across equipped pets at sale time. Bonuses are additive. Fractional money is retained, although the compact HUD floors values below 1000.

Followers are cosmetic client-generated Parts. Each client displays nearby players' equipped pets, culls at 120 studs, and lerps without server per-frame work. Discovery uses a timed reveal banner. Inventory, equipped IDs, and discovered species persist through the existing DataService.

Manual test:
1. Clear nodes until a pet drops. A banner should appear and the inventory/index should update.
2. For faster testing ONLY in a separate Studio test place, temporarily set Pets.DiscoveryChance to 1. Stop/Play after changing it. Restore 0.015 before publishing; the UI follows this value automatically.
3. Equip three owned pets. A fourth must be blocked. Unequip one and equip another.
4. Sell a bag with and without pets. For a Normal Common pet, 25 base value becomes 26.25.
5. Reset your character and inspect followers. They must return without duplicates.
6. Test with two clients. Each sees nearby equipped pets; only the owner sees their full inventory.
7. Test persistent rejoin with UseStudioDataStore enabled in the TEST experience as documented below. Verify pet IDs, equipped pets, and index remain intact.
8. Verify phone scrolling and close/open controls, rarity percentages, variant percentages, and undiscovered question marks.

Limitations: no pet base housing, custom referenced models, deletion/trading, or detailed particle reveal. Inventory UI rebuilds on inventory changes, not every frame. Runtime, DataStore integration, multiplayer visuals, and mobile behavior require Studio QA. Earlier phase sections are historical.

## Phase 3: tools and shop

Stop Play, keep `rojo serve` connected, allow sync, and start Play again. The server gives the equipped generated tool on spawn. Cleaning now requires that tool in the character's hand; select it in the backpack if unequipped.

The blue station beside spawn opens the shop. Tool purchases are sequential; owned tools can be equipped free. Prices are rounded up from the exponential config formula on both server and client. Hand Broom costs $23. The first bag upgrade costs $20 and changes capacity from 25 to 40. Future bag prices use the current bag level. Bag requests include the expected next level, preventing duplicate requests from purchasing another level. Server checks living character, distance, current planet, ownership, cooldown, and balance before modifying data without yielding.

Verification:
1. Sell a full starter bag for $25. Open the blue shop and buy Hand Broom. Expect $2 remaining and two units collected per accepted action.
2. Unaffordable buttons must appear disabled. Higher tools remain locked until the previous tier is owned.
3. Equip an already-owned tool repeatedly; money must not change.
4. Earn another $20 and buy the first bag upgrade. Expect capacity 40, with existing contents preserved.
5. Open the shop, walk away, then try buying. Expect rejection with a distance message.
6. Reset the character. The equipped tool must return once, without duplicated tools.
7. Test a persistent profile using the instructions below. Owned tools, selected tool, bag level, and capacity must survive rejoin.
8. Check phone and tablet sizes. The shop scrolls and its buttons are at least 64 pixels high.

Phase 3 limitations: tool models are colored two-part placeholders differentiated by tier size. Cleaning still uses repeated prompts, not hold-click. Shop range and interaction need Studio playtesting. The first-purchase 20–30 second target remains unverified with walking and manual prompts. Pet, robot, and planet shops arrive in their later phases.

Phase 3 validation: Rojo build passed; all 23 Luau source files passed syntax compilation. Runtime and persistence QA remain unverified. Earlier phase notes below are historical.

Rojo project, configuration, server-owned player profiles, generated HUD, and the first playable clean-and-sell loop. No external assets or packages.

## Run

Requires Roblox Studio, the official Rojo Studio plugin, and Rojo CLI 7.x.

```powershell
cd F:\roblox
rojo serve
```

This environment also has a temporary Rojo 7.7.1 executable:

```powershell
& 'C:\Users\ASUS\AppData\Local\Temp\opencode\rojo-7.7.1\rojo.exe' serve
```

Open a separate Baseplate test place in Studio. Connect the Rojo plugin to localhost:34872. Inspect proposed changes before accepting. Source folders sync as ServerScriptService/PlanetSweepersServer, StarterPlayer/StarterPlayerScripts/PlanetSweepersClient, and ReplicatedStorage/Shared. Rojo maps init scripts to their containing instance; services/controllers remain children of those scripts. Existing Workspace content is not managed or erased.

Stop any current playtest, allow Rojo to sync, then press Play again. Expected HUD: $0, Bag 0/25, Dusty Moonlet, and 'Studio: data sementara'. A generated platform appears at height 100; the player moves to its spawn. The original Baseplate is left untouched.

A standalone build is available at build/PlanetSweepers.rbxlx. Its scripts generate the playable platform when Play starts; no edit-time baseplate is required. Build again with:

```powershell
New-Item -ItemType Directory -Path build -Force
rojo build -o build/PlanetSweepers.rbxlx
```

Configure maximum server size to 16 in Creator Dashboard when publishing; Game.TargetPlayers is a design target, not an engine setting.

## Profile design

All balance values are under src/shared/config. Economy centralizes cost growth; Tools computes configured prices. Bags reads default capacity from Data. Configurations for later phases are definitions only.

The server owns the profile table. Replicated player attributes are a display projection only. No custom client-to-server remotes are needed in this phase. ProximityPrompt triggers are untrusted requests; the server independently checks distance, living character, cooldown, ownership, planet, and bag capacity. Editing local attributes cannot change saved data. Future services must obtain DataService.Get(player), mutate without yielding during a transaction, and call PlayerStateService.Publish(player).

bagContents stores amount, baseValue, and coopValue (the extra accumulated co-op value). This preserves planet values across travel and supports co-op calculation when cleaning. Pets use unique instance id plus species, rarity, and variant. Additional fields support bag levels, current planet, species discovery history, and daily reward timestamps.

DataStore keys use Player_<UserId>. Records wrap data in an envelope containing a unique session token and expiry. UpdateAsync claims or renews that lease. Autosave runs every 60 seconds; the lease lasts 180 seconds. Access stops 30 seconds before lease expiry if renewal fails. Saves are serialized per player; each snapshot is taken after obtaining the mutex. Version 0 receives missing defaults; current malformed and unsupported/newer versions fail closed. Never decrease dataVersion to bypass validation.

PlayerRemoving and BindToClose attempt save and lease release. Shutdown waiting is bounded at 25 seconds. Failed saves cannot guarantee progress preservation; a crash can lose progress since the last successful save. Failed releases leave the stored lease to expire instead of clearing another session's lock. A rejoin may be refused until a lease expires. API requests already in flight cannot be cancelled by Luau.

## Persistence test (human)

1. Use a separate published TEST experience. Do not enable Studio testing against live player records.
2. In src/shared/config/Data.luau set UseStudioDataStore = true. Studio uses PlanetSweepers_TEST_v1; published servers use PlanetSweepers_v1 in their own experience.
3. Enable Game Settings > Security > Enable Studio Access to API Services for the TEST experience.
4. Play and confirm 'Data siap'. In the SERVER Command Bar run:

```lua
local player = game:GetService("Players"):GetPlayers()[1]
local root = game:GetService("ServerScriptService").PlanetSweepersServer
local dataService = require(root.services.DataService)
local stateService = require(root.services.PlayerStateService)
local profile = dataService.Get(player)
assert(profile, "Profile not ready")
profile.money = 1234
profile.bagContents = {amount = 10, baseValue = 10, coopValue = 0}
stateService.Publish(player)
assert(dataService.Save(player), "Save failed")
```

5. Confirm $1.2K, Bag 10/25, and a 40% progress bar. Leave, rejoin, and confirm the same state.
6. Change money again, wait at least 65 seconds, then rejoin to test autosave. Leave without an explicit Save to test PlayerRemoving. Normal Stop tests BindToClose best-effort behavior.
7. Disable API access and start another test. Persistent loading must fail with a kick, never silently become a writable blank profile.
8. Session-lock conflict requires the same account/profile key in two sessions, not two different simulated users. Use the test store only. The second session must refuse an active lease.
9. Restore UseStudioDataStore = false for everyday local development.

Memory mode is deliberate: data survives a player reconnect only within the same running server, not Stop/Play. A Studio warning is expected.

## Other QA (human)

- Start Server with two clients. Both receive separate state folders and independent profiles.
- Check desktop, tablet, and phone in Studio Device Emulator. HUD must remain within screen bounds.
- Reset the character. HUD must not duplicate or disappear.
- Change a money attribute in the CLIENT Command Bar. Server profile must remain unchanged; Publish restores the authoritative display.
- Test formatter cases: 0 -> 0, 1500 -> 1.5K, 2300000 -> 2.3M, 999950 -> 1M, NaN/infinity -> 0.
- Check Output for unexpected errors; Studio temporary-mode warning is intentional.

## Phase 2 gameplay test (human)

1. Stop the old playtest first. Rojo changes to StarterPlayerScripts do not repair already-cloned PlayerScripts. Start Play again after sync.
2. Confirm no infinite yield for controllers. The client bootstrap now reads script.controllers, matching Rojo's init mapping.
3. Walk to a dust block. Hold E (or the on-screen prompt). Each accepted action collects 1 unit, with an authoritative 0.8-second cooldown.
4. A node contains 5 units. After five accepted actions it disappears. It returns approximately 8–8.5 seconds later using the same Part.
5. Fill the bag to 25. Further cleaning must not consume dirt or overflow capacity.
6. Walk to the green recycler near spawn. Hold Sell bag. An initially full starter bag awards $25 and becomes empty.
7. Activate Sell bag again. It must not pay twice. Clean again and check the HUD updates.
8. Use two clients on the same node: collected totals must not exceed its available 5 units per respawn. Each player's bag remains separate.
9. Reset the character. It returns to the generated spawn; bag contents remain intact.
10. Walk away from a node/station. Prompts disappear outside their radius. Server checks range independently of client prompt visibility.

WorldService creates only Workspace.PlanetSweepersWorld and refuses to overwrite a same-named existing object. Remove a conflicting object only after confirming ownership. The temporary data warning is expected. An unrelated rbxassetid asset-type error is not generated by these asset-free scripts; inspect other scripts/plugins before deleting anything.

## Validation performed

Rojo 7.7.1 successfully built the Phase 2 project. All 19 Luau source files compiled using Luau 0.745. Compilation checks syntax, not Roblox API typing or runtime behavior. Studio playtests, multi-client tests, lease conflict tests, persistence failures, and device checks remain human QA.

## Limitations

No shops, visual handheld tool, hold-click cleaning, pets, robots, rewards, or monetization behavior yet. Phase 2 uses repeated ProximityPrompt activations with server cooldown; holding one prompt is not continuous cleaning. Early upgrade affordability is a config target that needs real Phase 2/3 playtesting. Pet schema validation is structural until Phase 4 adds pet semantics. Shared config is readable by clients and must never contain secrets. Data protection is not a backup/version recovery tool. No third-party dependency audit is necessary because there are no package dependencies.

All source files contain complete implementations for this phase. Stop here until the user requests continue.
