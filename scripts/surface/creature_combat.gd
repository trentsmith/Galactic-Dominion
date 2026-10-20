class_name CreatureCombat
extends RefCounted
## Original affinities, shared by owned companions and wild opponents.
const ROSTER={
 "bloodstag":{"affinity":"Grove","ability":"Verdant Guard","effect":"shield","power":9,"defense":9,"speed":6},
 "duskbat":{"affinity":"Dusk","ability":"Night Chirp","effect":"disrupt","power":11,"defense":5,"speed":12},
 "nightfang":{"affinity":"Ember","ability":"Flare Pounce","effect":"strike","power":15,"defense":6,"speed":10},
 "sporehopper":{"affinity":"Tide","ability":"Pearl Mend","effect":"heal","power":7,"defense":8,"speed":7},
 "prismgrazer":{"affinity":"Grove","ability":"Prism Ward","effect":"shield","power":8,"defense":12,"speed":5},
 "thornmanta":{"affinity":"Tide","ability":"Reef Lance","effect":"strike","power":14,"defense":6,"speed":11},
 "riftwisp":{"affinity":"Aether","ability":"Rift Slip","effect":"disrupt","power":12,"defense":5,"speed":12},
 "manyeye":{"affinity":"Aether","ability":"Watcher's Focus","effect":"focus","power":10,"defense":10,"speed":5},
 "veilcrawler":{"affinity":"Stone","ability":"Shell Crash","effect":"strike","power":12,"defense":14,"speed":4}}
const STRONG={"Grove":"Tide","Tide":"Ember","Ember":"Grove","Dusk":"Aether","Aether":"Stone","Stone":"Dusk"}
static func affinity(species: String) -> String:return str(ROSTER[species].affinity) if ROSTER.has(species) else "Grove"
static func multiplier(attacking: String,defending: String) -> float:
 if STRONG.get(attacking,"")==defending:return 1.75
 if STRONG.get(defending,"")==attacking:return .6
 return 1.0
static func attributes(resident: Dictionary) -> Dictionary:
 var kind: Dictionary=ROSTER[str(resident.species)]
 var level:=clampi(int(resident.get("level",1)),1,50)
 var stage:=int(resident.get("form_stage",0))
 var love:=float(resident.get("bond",0))
 return {"level":level,"affinity":kind.affinity,"ability":kind.ability,"hp":40.0+level*4+stage*12+love*.15,"attack":float(kind.power)+level*1.3+stage*2,"defense":float(kind.defense)+level*.7,"speed":6.0+float(kind.speed)*.3,"effect":kind.effect}
static func damage(attack: float,defense: float,attacking: String,defending: String) -> float:
 return maxf(1,attack*multiplier(attacking,defending)*20/(20+defense))
static func wild_level(animal: SurfaceFauna) -> int:return clampi(1+floori(Vector2(animal.home.x,animal.home.z).length()/350),1,20)
static func award(resident: Dictionary,amount: int) -> void:
 resident.level=clampi(int(resident.get("level",1)),1,50)
 resident.experience=int(resident.get("experience",0))+maxi(0,amount)
 while resident.level<50 and resident.experience>=needed(resident.level):
  resident.experience-=needed(resident.level);resident.level+=1
 if resident.level==50:resident.experience=0
 resident.battles_won=int(resident.get("battles_won",0))+1
static func needed(level: int) -> int:return 30+level*15
