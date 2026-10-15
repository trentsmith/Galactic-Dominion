class_name SanctuaryForms
extends RefCounted
const NAMES={
 "bloodstag":["Petalcrest Stag","Auroracrown Warden"],
 "duskbat":["Velvetwing","Dawnveil Guide"],
 "nightfang":["Hearthfang","Embermane Sentinel"],
 "sporehopper":["Lullalume","Pearlveil Lantern"],
 "prismgrazer":["Coralglide","Tidegarden Keeper"],
 "thornmanta":["Gleamfin","Mooncurrent Guardian"],
 "riftwisp":["Whisperglow","Dreamweave Beacon"],
 "manyeye":["Starlit Seer","Bloomgaze Oracle"],
 "veilcrawler":["Softveil","Starbloom Weaver"]}
const REQUIREMENTS=[{"friendship":35.0,"love":25.0,"growth":20.0,"care_time":90.0},{"friendship":80.0,"love":70.0,"growth":65.0,"care_time":360.0}]
static func form_name(species: String,stage: int) -> String:
 if stage>0 and NAMES.has(species):return NAMES[species][clampi(stage-1,0,1)]
 for planet in PlanetCatalog.WORLDS:
  for definition in planet.fauna:
   if definition.id==species:return definition.display_name
 return "Unknown creature"
static func ready(resident: Dictionary) -> bool:
 var stage:=int(resident.get("form_stage",0))
 if stage<0 or stage>=2 or not NAMES.has(str(resident.get("species",""))):return false
 var goal: Dictionary=REQUIREMENTS[stage]
 return float(resident.get("bond",0))>=goal.friendship and float(resident.get("love",0))>=goal.love and float(resident.get("growth",0))>=goal.growth and float(resident.get("care_time",0))>=goal.care_time and int(resident.get("habitat",0))>0 and float(resident.get("nutrition",0))>=40 and float(resident.get("happiness",0))>=65
static func production_multiplier(stage: int) -> float:
 return 1.35 if stage>=2 else 1.15 if stage==1 else 1.0
static func progress_text(resident: Dictionary) -> String:
 var stage:=int(resident.get("form_stage",0))
 if stage>=2:return "Radiant form / permanent / +35% production"
 var goal: Dictionary=REQUIREMENTS[stage]
 return "Next: %s\nFriendship %d/%d · Love %d/%d\nGrowth %d/%d · Happy care %ds/%ds\nNeeds housing, food 40+ and joy 65+" % [form_name(resident.species,stage+1),resident.bond,goal.friendship,resident.get("love",0),goal.love,resident.growth,goal.growth,resident.get("care_time",0),goal.care_time]
