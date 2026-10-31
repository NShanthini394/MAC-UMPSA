extends SceneTree
var checks=0
var failures=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func run() -> void:
 var app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
 await create_timer(1.0).timeout
 app.selected_map=1;app.selected_character="Badang"
 app.completed_tasks.assign([0,0,0,0,0,0,0,0,0,0,0,0])
 app.task_progress.assign([0,0,0,0,0,0,0,0,0,0,0,0])
 await app.build_game()
 var pad=app.find_child("VirtualJoystick",true,false)
 check(pad.size.x>=560 and pad.size.y>=360,"Joystick covers lower-left area")
 check(pad.get_theme_stylebox("panel") is StyleBoxEmpty,"Joystick is invisible")
 var touch=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=Vector2(100,200)
 app._on_joystick_input(touch,pad,pad.get_child(0))
 var drag=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(180,200)
 app._on_joystick_input(drag,pad,pad.get_child(0))
 check(app.move_vector.x>0.8,"Floating joystick follows initial touch")
 touch.index=1;touch.pressed=false
 app._on_joystick_input(touch,pad,pad.get_child(0))
 check(app.move_vector.x>0.8,"Other finger does not cancel movement")
 touch.index=0
 app._on_joystick_input(touch,pad,pad.get_child(0))
 check(app.move_vector==Vector2.ZERO,"Release stops movement")
 app.player_sleeping=true;app._set_move(Vector2.RIGHT)
 check(app.move_vector==Vector2.RIGHT and not app.can_local_act(),"Sleep allows movement but blocks actions")
 app._update_power_hud()
 check(pad.visible,"Sleeping player keeps movement controls")
 check(app.find_child("InteractButton",true,false).disabled,"Sleeping player cannot interact")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://tmp/phone-hud-preview.png")
 for mode in ["voting_intro","reveal"]:
  var view=load("res://scripts/meeting_cinematic.gd").new();app.game_hud.add_child(view)
  view.configure(mode,{"id":3,"name":"Priya","character":"Mahsuri","was_nenek":true,"remaining":1})
  check(view.headline.text=="TIME TO VOTE" if mode=="voting_intro" else view.artwork.size.x>=1280,"Voting intro or full-screen reveal")
  await create_timer(0.7).timeout
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://tmp/phone-%s-preview.png"%mode)
  view.queue_free();await process_frame
 app.player_sleeping=false
 app.player_voted_out=false
 app._show_role_reveal()
 var deadline=Time.get_ticks_msec()+5000
 while app.find_child("RevealedRoleCard",true,false)==null or not app.find_child("RevealedRoleCard",true,false).visible:
  if Time.get_ticks_msec()>deadline:check(false,"Role shuffle finishes");break
  await process_frame
 await create_timer(4.5).timeout
 check(app.current_screen=="role_reveal","Role card stays visible for at least 4.5 seconds")
 await create_timer(0.7).timeout
 check(app.current_screen=="game","Five-second reveal enters game without another countdown")
 app.queue_free();await process_frame
 print("PHONE UI CHECKS: %d checks; %d failures"%[checks,failures])
 quit(1 if failures else 0)
