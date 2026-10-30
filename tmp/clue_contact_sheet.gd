extends SceneTree
const Data=preload("res://scripts/game_data.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
 root.size=Vector2i(1200,1200)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 root.content_scale_size=Vector2i.ZERO
 var holder=Control.new()
 root.add_child(holder)
 var bg=ColorRect.new();bg.color=Color("33291e");bg.size=Vector2(1200,1200);holder.add_child(bg)
 var i=0
 for group in Data.CHARACTER_CLUES.values():
  for clue in group:
   var image=Image.load_from_file(preload("res://scripts/clue_art.gd").asset_path(clue))
   if image!=null and not image.is_empty():
    var icon=TextureRect.new()
    icon.texture=ImageTexture.create_from_image(image)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.position=Vector2(10+(i%6)*200,10+floori(i/6.0)*200)
    icon.size=Vector2(180,180)
    holder.add_child(icon)
   i+=1
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tmp/clue-art-overview.png")
 quit()
