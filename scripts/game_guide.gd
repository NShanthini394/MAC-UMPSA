extends RefCounted
## Shared, localized content for both in-game How to Play guides.
const Lang = preload("res://scripts/app_language.gd")

const SOURCE_SECTIONS := [
	[
		"Playing modes",
		"Start Game → Play with Friends, Solo vs Bots, or Quick Match.\nFriends: create or join a private room with a code. The host starts when at least two human players are ready.\nSolo: play offline as one Villager with nine bots.\nQuick Match searches for up to 60 seconds; bots fill empty spaces after the wait.\nEvery match has ten characters: eight Villagers and two Nenek Kebayan."
	],
	[
		"Villagers",
		"Vote out both Nenek Kebayan to win, even if tasks are unfinished. Follow task routes, inspect clues, and compare observations."
	],
	[
		"Nenek Kebayan",
		"Blend in with the Villagers and use your abilities carefully. Sleep Spell puts human Villagers to sleep for the rest of the match; they can move but cannot chat, vote, or complete tasks. Fog lasts 20 seconds; Door Lock lasts 10 seconds. Both abilities recharge in two minutes."
	],
	[
		"Meetings & Voting",
		"Approach the gong and press Interact to call a meeting. Discuss for 45 seconds, then vote or skip within 20 seconds. Votes cannot be changed after submission."
	],
	[
		"Controls",
		"On a phone, drag the touch pad in the lower-left area to move. On a computer, use WASD or the arrow keys. Press E or tap Interact near a task or the gong. Use the map for routes and the journal to review clues."
	]
]

static func sections() -> Array[Dictionary]:
	var localized: Array[Dictionary] = []
	for section in SOURCE_SECTIONS:
		localized.append({"title": Lang.text(section[0]), "body": Lang.text(section[1])})
	return localized

static func rich_text() -> String:
	var blocks: Array[String] = []
	for section in sections():
		blocks.append("[color=#f7c35a][b]%s[/b][/color]\n%s" % [section.title.to_upper(), section.body])
	return "\n\n".join(blocks)

static func plain_text() -> String:
	var blocks: Array[String] = []
	for section in sections():
		blocks.append("%s\n%s" % [section.title.to_upper(), section.body])
	return "\n\n".join(blocks)
