# Planet Sweepers — Phase 1

Rojo project, configuration, server-owned player profiles, and generated HUD. No external assets or packages.

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

Press Play. Expected HUD: $0, Bag 0/25, Dusty Moonlet, and 'Studio: data sementara'. No planet is generated until Phase 2.

A standalone build is available at build/PlanetSweepers.rbxlx. It contains scripts only, not a baseplate. Build again with:

```powershell
New-Item -ItemType Directory -Path build -Force
rojo build -o build/PlanetSweepers.rbxlx
```

Configure maximum server size to 16 in Creator Dashboard when publishing; Game.TargetPlayers is a design target, not an engine setting.

## Profile design

All balance values are under src/shared/config. Economy centralizes cost growth; Tools computes configured prices. Bags reads default capacity from Data. Configurations for later phases are definitions only.

The server owns the profile table. Replicated player attributes are a display projection only. No client-to-server remotes are needed in this phase. Editing local attributes cannot change saved data. Future services must obtain DataService.Get(player), mutate without yielding during a transaction, and call PlayerStateService.Publish(player).

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

## Validation performed

Rojo 7.7.1 successfully built the project. All 16 Luau source files compiled using Luau 0.745. Compilation checks syntax, not Roblox API typing or runtime behavior. Studio playtests, multi-client tests, lease conflict tests, persistence failures, and device checks remain human QA.

## Limitations

No cleaning, generated world, shops, pets, robots, rewards, monetization behavior, or gameplay remotes yet. Early upgrade affordability is a config target that needs real Phase 2/3 playtesting. Pet schema validation is structural until Phase 4 adds pet semantics. Shared config is readable by clients and must never contain secrets. Data protection is not a backup/version recovery tool. No third-party dependency audit is necessary because there are no package dependencies.

All source files contain complete implementations for this phase. Stop here until the user requests continue.
