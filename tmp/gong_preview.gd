extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 root.size=Vector2i(600,400)
 for i in 3:
  var world=Node2D.new()
  root.add_child(world)
  var map=Sprite2D.new()
  var data=load("res://scripts/game_data.gd")
  var geo=load("res://scripts/map_geometry.gd")
  map.texture=ImageTexture.create_from_image(Image.load_from_file(data.map_art_path(i)))
  map.centered=false
  map.position=Vector2(300,270)-geo.gong_point(i)
  world.add_child(map)
  var gong=load("res://scripts/gong_marker.gd").new()
  gong.map_index=i
  gong.position=Vector2(300,270)
  world.add_child(gong)
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://tmp/gong-preview-%d.png"%i)
  world.queue_free()
  await process_frame
 quit()
