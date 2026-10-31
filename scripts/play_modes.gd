extends RefCounted
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")

static func build(app: Control, friends: bool = false) -> void:
	app.clear_screen("friends_menu" if friends else "play_modes")
	app.add_background(load(Data.MENU_ART))
	app.add_color_overlay(Color(0.04,0.03,0.02,0.88))
	var panel: Panel = app.make_panel(Rect2(55,105,1170,510),Data.SECTION_PANEL)
	UI.make_child_label(panel,"PLAY WITH FRIENDS" if friends else "CHOOSE HOW TO PLAY",30,Data.GOLD,HORIZONTAL_ALIGNMENT_CENTER,Rect2(90,24,990,48))
	app._add_overlay_close(panel,1170,Callable(app,"build_play_modes") if friends else Callable(app,"build_menu"))
	var entries: Array = [
		["PLAY WITH FRIENDS","Create a private room or join with a room code.\n2–10 human players; bots fill empty spaces.",Callable(app,"build_friends_menu"),"FriendsModeButton"],
		["SOLO VS BOTS","1 human and 9 bots.\nYou play as a Villager.\nNo internet or search wait.",Callable(app,"_choose_solo_mode"),"SoloModeButton"],
		["QUICK MATCH","Find other players online.\nSearch for up to 60 seconds, then fill empty spaces with bots.",Callable(app,"_find_public_match"),"QuickMatchButton"]
	]
	if friends:
		entries = [
			["CREATE ROOM","Choose a map and share the room code.\nStart as soon as your friends are ready.",Callable(app,"_choose_friends_host"),"CreateRoomButton"],
			["JOIN ROOM","Enter your friend's five-character code.\nWorks across the same or different networks.",Callable(app,"show_join_room"),"JoinRoomButton"]
		]
	for index in entries.size():
		var entry: Array = entries[index]
		var width := 334.0 if not friends else 460.0
		var x := 42.0 + index*376.0 if not friends else 100.0+index*510.0
		var card := UI.make_panel(panel,Rect2(x,110,width,300),Color("241b18"))
		UI.make_child_label(card,str(entry[0]),22,Data.GOLD,HORIZONTAL_ALIGNMENT_CENTER,Rect2(15,20,width-30,50))
		UI.make_child_label(card,str(entry[1]),18,Data.CREAM,HORIZONTAL_ALIGNMENT_CENTER,Rect2(22,82,width-44,130))
		var button := UI.make_button(card,"SELECT",entry[2],width-48,52,true)
		button.name=str(entry[3]);button.position=Vector2(24,226)
	UI.make_child_label(panel,"Every match: 10 characters · 8 Villagers · 2 Nenek Kebayan",18,Data.CREAM,HORIZONTAL_ALIGNMENT_CENTER,Rect2(55,435,1060,40))
