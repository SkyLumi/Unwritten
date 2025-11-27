# Enemy AI (mirrors player)

- Scene: `src/Player/Enemy.tscn` instantiates the same rig/animations as the player, but uses `AIInput.gd` to drive inputs.
- AI input: chases the first node in group `player`, uses `NavigationAgent3D` for path planning when a navmesh is present, falls back to straight-line movement otherwise, and triggers a light attack when within `attack_distance` (default 2m).
- Navigation: add a `NavigationRegion3D`/navmesh to your level so the agent can pathfind around obstacles. Without it, the enemy will still move toward the player but won’t avoid walls.
- Targeting: player root is now in group `player`; enemy root is in group `enemy`. Override `AIInput`’s `target` export in the Inspector if you want the AI to chase a different node.
- Tuning knobs (per enemy instance via Inspector):
  - `attack_distance`, `sprint_distance`, `stop_distance`
  - `target_group` (fallback target search)
  - `navigation_agent` (assigned to the built-in `NavigationAgent` node)
