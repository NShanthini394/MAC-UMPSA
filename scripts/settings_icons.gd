extends RefCounted
## One line-icon family, rendered from vectors for clear phone-sized controls.
static var cache: Dictionary = {}
static func icon(kind: String) -> Texture2D:
	if cache.has(kind): return cache[kind]
	var paths: String = {
		"language": '<path d="M2 7h17M10 3v4M6 8c0 7 5 12 12 15M16 8C14 15 9 20 3 23M20 28l5-15 5 15m-8-5h6"/>',
		"profile": '<circle cx="16" cy="10" r="5"/><path d="M5 29v-4c0-10 22-10 22 0v4"/>',
		"security": '<path d="m16 3 11 4v10c0 7-11 13-11 13S5 24 5 17V7Z"/><path d="m10 16 4 4 8-9"/>',
		"audio": '<path d="M4 12h6l8-7v22l-8-7H4ZM23 10c5 3 5 9 0 12M27 6c8 6 8 14 0 20"/>',
		"controls": '<rect x="3" y="8" width="26" height="18" rx="6"/><path d="M8 17h8m-4-4v8M22 14v1m3 5v1"/>',
		"text": '<path d="M3 6h26M16 6v23M10 29h12M3 10V6m26 4V6"/>',
		"report": '<path d="M5 4h22v20H15l-8 6v-6H5ZM16 8v8m0 4v1"/>',
		"help": '<circle cx="16" cy="16" r="13"/><path d="M12 11c0-6 11-6 9 1-1 4-5 3-5 8m0 4v1"/>',
		"info": '<circle cx="16" cy="16" r="13"/><path d="M16 14v11m0-18v2"/>',
		"exit": '<path d="M16 4H4v24h12M13 16h17m-6-6 6 6-6 6"/>',
		"reset": '<path d="M7 9a12 12 0 1 1-2 13M3 3v9h9"/>'
	}.get(kind, '<path d="m10 5 12 11-12 11"/>')
	var image := Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 32 32"><g fill="none" stroke="#f7c35a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'+paths+'</g></svg>')
	cache[kind] = ImageTexture.create_from_image(image)
	return cache[kind]
