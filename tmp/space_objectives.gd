extends SceneTree
const G=preload("res://scripts/map_geometry.gd")
const N=preload("res://scripts/map_navigation.gd")
func _initialize() -> void: run.call_deferred()
func gap(p: Vector2, points: Array) -> float:
 var d=10000.0
 for q in points: d=minf(d,p.distance_to(q))
 return d
func run() -> void:
 var results=[]
 for m in 3:
  var plan=G.floor_plan(m)
  var pool=[]
  for x in range(35,int(plan.layout.design_size.x),28):
   for y in range(35,int(plan.layout.design_size.y),28):
    var p=plan.world_point(Vector2(x,y))
    if not G.is_position_blocked(m,p,22): pool.append(p)
  var tasks=G.task_points(m)
  for pass_id in 3:
   for i in tasks.size():
    var section=plan.layout.sections[plan.layout.task_sections[i]]
    var others=tasks.duplicate();others.remove_at(i)
    var best=tasks[i];var score=-INF
    for p in pool:
     var in_section=false
     for zone in section.zones:
      if zone.grow(-20).has_point(p/plan.scale): in_section=true
     if not in_section: continue
     var value=gap(p,others)-0.04*p.distance_to(tasks[i])
     if value>score and N.path(m,G.spawn_point(m),p).size()>=2:
      score=value;best=p
    tasks[i]=best
  var clues=[]
  for i in 6:
   var best=Vector2.ZERO;var score=-INF
   for p in pool:
    var task_gap=gap(p,tasks)
    if gap(p,clues)<160 or task_gap<125 or p.distance_to(G.gong_point(m))<110 or gap(p,G.npc_points(m))<65: continue
    var value=minf(task_gap,280.0)+minf(gap(p,clues),500.0)*1.5
    if value>score and N.path(m,G.spawn_point(m),p).size()>=2:
     score=value;best=p
   if best==Vector2.ZERO: push_error("No spaced clue location");quit(1);return
   clues.append(best)
   pool.erase(best)
  var item={"tasks":[],"clues":[]}
  for p in tasks:item.tasks.append([snappedf(p.x/plan.scale.x,1),snappedf(p.y/plan.scale.y,1)])
  for p in clues:item.clues.append([snappedf(p.x/plan.scale.x,1),snappedf(p.y/plan.scale.y,1)])
  results.append(item)
  print("Map ",m," task/clue gap: ",clues.map(func(p):return gap(p,tasks)).min())
 FileAccess.open("res://tmp/spaced-objectives.json",FileAccess.WRITE).store_string(JSON.stringify(results))
 quit()
