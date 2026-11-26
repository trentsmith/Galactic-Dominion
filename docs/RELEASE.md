Galactic Dominion v0.46.0 — Recruit Your Fleet

Recruit permanent spaceships, customize every vessel, and fight another commander's fleet in **up to 50v50 online battles**.

- **Recruitment board:** five class contracts bought with online salvage. Each ship has a persistent identity, its own fittings and a Nexus faction appearance. Start with three issued ships and 200 salvage; grow toward fifty deployed ships and 200 owned ships total.
- **Battle Fleet:** inspect actual fitted hull, shields, speed, handling, laser/missile damage, cooldowns and abilities for every vessel. Choose engines, weapons, shields, utility, crew and liveries; assign or reserve ships between matches.
- **Fleet Duel:** exactly two commanders, one on each team, bring their selected 3–50-ship lineups. AI pilots wingmates. Unequal fleets work too. Use F1–F3 for lead ships, [ / ] for all surviving allies and 1–5 for fleet orders. The eight-minute timer and shrinking zone remain active.
- **Permanent ownership:** destroyed or defeated ships return for the next battle with their fittings. Victory blueprints can be commissioned into owned vessels or traded unused. Contracted/commissioned vessel records remain account-bound.
- **Authoritative progression:** the account service validates prices, ownership, lineup capacity and match locks. Retried recruitment cannot charge twice. Whole-fleet kills/damage count for the commander; disconnecting forfeits a duel. The running host retries temporary result-save failures before allowing another match.
- **Larger online protocol:** compact eight-ship snapshots, pooled projectile visuals, spatial AI queries and simplified wingmate hulls support the expanded fleets. Taking control restores detailed ship art.

**How to play:** run the matching self-hosted server package; open **Online → Recruitment**, then **Battle Fleet**. Both commanders connect to the same host, choose opposite teams and ready up; the leader launches **FLEET DUEL**. [Full guide](https://github.com/trentsmith/Galactic-Dominion/blob/phase-46-recruitment/docs/FLEET_RECRUITMENT.md).

Download **Galactic-Dominion-Windows.zip**, extract the entire folder, and run **GalacticDominion.exe**. Linux clients, Windows/Linux server packages and procedural 3D model exports are also included. Players do not need Godot. [PC hosting](https://github.com/trentsmith/Galactic-Dominion/blob/phase-46-recruitment/server/README.md).

Update hosts and all clients to **v0.46.0**. Online profile version 2 migrates existing accounts without losing their three ships, fittings or inventory; back up `server-data` before upgrading. Local save schema remains 11, separate from online progression. Existing six-pilot Free Roam/Co-op/Royale, wildlife/companions, solo 10v10 and **200v50 / 200v200 / 50v200** Armada presets remain available.

Validation includes server ownership/transaction regressions, Godot fleet/packet checks, actual two-client 50v50 and 7v50 fixtures with forfeits/reward retries, normal live 50v50 AI combat, retained six-client/co-op paths and broader gameplay regressions. Release CI builds Windows/Linux and exercises the exported Linux client/server. Native Linux captures check recruitment and fleet menus. Windows GUI, Internet hosting, controllers and sustained human balance/performance playtests remain pending.
