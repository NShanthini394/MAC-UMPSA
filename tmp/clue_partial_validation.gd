extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Art=preload("res://scripts/clue_art.gd")
var failures=0
var checks=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func run() -> void:
 var names=[]
 for group in Data.CHARACTER_CLUES.values(): names.append_array(group)
 names=names.filter(func(c):return ResourceLoader.exists(Art.asset_path(c)))
 for clue in names:
  var path=Art.asset_path(clue)
  check(ResourceLoader.exists(path),"Image exists: "+clue)
  var image=Image.load_from_file(path)
  check(image!=null and not image.is_empty(),"Image is readable: "+clue)
  if image!=null and not image.is_empty():
   check(image.detect_alpha()!=Image.ALPHA_NONE,"Transparent cutout: "+clue)
 var app=load("res://scenes/main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 await process_frame
 await create_timer(1.0).timeout
 await app.build_menu()
 app.set_process(false)
 names=names.filter(func(c):return ResourceLoader.exists(Art.asset_path(c)))
 for clue in names:
  app.show_clue_panel(clue,"hidden")
  var panel=app.find_child("ClueOverlay",true,false)
  check(panel!=null,"Clue popup opens")
  var icon=panel.find_child("ClueIllustration",true,false)
  check(icon!=null and icon.texture!=null,"Popup uses clue illustration")
  for node in panel.find_children("*","Label",true,false):
   check(node.text.is_empty(),"No wording in clue popup")
  panel.get_parent().remove_child(panel)
  panel.queue_free()
 app.collected_clues.assign(names)
 app.show_journal()
 var journal=app.find_child("JournalOverlay",true,false)
 check(journal.find_children("ClueIllustration","TextureRect",true,false).size()==names.size(),"Journal shows all images")
 var icon=journal.find_children("ClueIllustration","TextureRect",true,false)[0]
 var start_y=icon.position.y
 await create_timer(0.6).timeout
 check(icon.modulate.a>0.99,"Reveal fades in")
 check(icon.position.y<start_y,"Clue illustration floats")
 app.queue_free()
 await process_frame
 print("CLUE ART CHECKS: %d checks; %d failures"%[checks,failures])
 quit(1 if failures else 0)
