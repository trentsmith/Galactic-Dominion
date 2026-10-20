class_name DifficultyPlaytest
extends RefCounted
## Opt-in ratings stay on disk. No network requests or identifying player data.
const RATINGS := ["unrated","too_easy","about_right","too_hard"]
static func summary(battle: BattleMatch,rating: String = "unrated") -> Dictionary:
 var teams := [{"damage":0.0,"shots":0,"hits":0,"survivors":0},{"damage":0.0,"shots":0,"hits":0,"survivors":0}]
 for ship in battle.ships:
  if ship.team<0 or ship.team>1:continue
  teams[ship.team].damage += ship.damage_dealt
  teams[ship.team].shots += ship.shots
  teams[ship.team].hits += ship.hits
  if ship.alive:teams[ship.team].survivors += 1
 return {"version":ProjectSettings.get_setting("application/config/version"),"mode":"10v10" if battle.team_size==10 else "3v3","difficulty":SoloDifficulty.valid(battle.difficulty),"duration":snappedf(battle.elapsed,.01),"winner":battle.winner,"reason":battle.end_reason,"teams":teams,"rating":rating if rating in RATINGS else "unrated"}
static func save(battle: BattleMatch,rating: String = "unrated") -> Error:
 var directory := ProjectSettings.globalize_path("user://playtests")
 var error := DirAccess.make_dir_recursive_absolute(directory)
 if error != OK:return error
 if battle.playtest_path.is_empty():battle.playtest_path = directory.path_join("battle-%d-%s.json" % [int(Time.get_unix_time_from_system()),battle.battle_id])
 var file := FileAccess.open(battle.playtest_path+".tmp",FileAccess.WRITE)
 if file == null:return FileAccess.get_open_error()
 file.store_string(JSON.stringify(summary(battle,rating),"  "));file.flush()
 error = file.get_error();file.close()
 if error != OK:return error
 return DirAccess.rename_absolute(battle.playtest_path+".tmp",battle.playtest_path)
