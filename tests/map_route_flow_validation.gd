extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Geometry=preload("res://scripts/map_geometry.gd")
const UI=preload("res://scripts/game_ui.gd")
var app: Control
var checks:=0
var failures:Array[String]=[]
func _initialize()->void: run.call_deferred()
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok: failures.append(message);push_error(message)
func settle()->void:
 await process_frame;await process_frame;await process_frame
func tap(control:Control)->void:
 var e:=InputEventScreenTouch.new();e.index=0;e.position=control.get_global_rect().get_center();e.pressed=true
 root.push_input(e,true);await process_frame
 e=InputEventScreenTouch.new();e.index=0;e.position=control.get_global_rect().get_center();e.pressed=false
 root.push_input(e,true);await settle()
func capture(file:String)->void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://.godot/page-previews/route_flow_"+file+".png")
func run()->void:
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await settle()
 app.online_server_url="";app.set_process(false);app.selected_character="Mahsuri";app.player_is_impostor=false
 for map_index in 3:
  app.selected_map=map_index;app.player_position=Geometry.spawn_point(map_index)
  app.completed_tasks.clear();app.task_progress.clear()
  for i in Data.COMMON_TASKS.size():app.completed_tasks.append(0);app.task_progress.append(0)
  await app.build_game();app.player_body.set_physics_process(false);app.show_map_overlay();await settle()
  var view:Control=app.find_child("MapOverlay",true,false)
  check(view.find_child("MapViewPanel",true,false).get_theme_stylebox("panel").bg_color==Data.SECTION_PANEL,"Shared dark brown panel on map %d"%map_index)
  check(not view._route.visible,"No route prompt before choosing a task")
  await tap(view._tasks_tab);await tap(view._buttons[2])
  check(view.selected==2 and view._map_tab.button_pressed and not view._tasks.visible,"Task touch automatically opens MAP")
  check(view.canvas.selected==2 and view._details.visible and view._route.visible,"Chosen task and details appear on map")
  check(view._buttons[2].get_theme_stylebox("normal").texture==UI.menu_button_style("red").texture,"Selected task stays red")
  check(view._route_glow.visible and view._route_pulse!=null and view._route_pulse.is_valid(),"Route button animation starts")
  await create_timer(0.35).timeout
  check(view._route.scale.x>1.001 and view._route.scale.x<=1.031,"Route button gently pulses")
  await capture("map_%d"%map_index)
  await tap(view._tasks_tab)
  check(not view._route_glow.visible and view._route.scale==Vector2.ONE,"Animation stops in TASKS")
  app.completed_tasks[0]=1;await settle()
  check(view._tasks.visible,"Unrelated task update does not force MAP tab")
  for i in Data.COMMON_TASKS.size():
   view._tab(true);view._buttons[i].pressed.emit();await settle()
   check(view.selected==i and view._map_tab.button_pressed and not view._tasks.visible,"Every task opens MAP")
  view._choose(2);app.completed_tasks[2]=1;await settle()
  check(view._route.disabled and view._route.text=="COMPLETED" and not view._route_glow.visible,"Completed task does not ask for route")
  view._choose(1);await settle();await tap(view._route)
  check(app.route_active and app.route_target==Geometry.task_points(map_index)[1],"Show Route activates the chosen route")
  check(app.find_child("MapOverlay",true,false)==null,"Show Route closes the map viewer")
  var line:Line2D=app.game_world.get_node("RouteLine")
  check(line.visible and line.default_color==Color("17151c"),"Selected route uses dark charcoal")
  await capture("game_route_%d"%map_index)
  app.show_map_overlay();await settle();view=app.find_child("MapOverlay",true,false)
  view._choose(1);app.player_sleeping=true;view._refresh_selection_details()
  check(view._route.disabled and not view._route_glow.visible,"Sleeping players do not get an actionable route prompt")
  app.player_sleeping=false;view.queue_free();await settle()
 app.queue_free();await settle()
 print("MAP ROUTE FLOW: %d checks; %d failures"%[checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
