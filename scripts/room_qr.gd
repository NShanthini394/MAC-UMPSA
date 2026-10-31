extends RefCounted
## Version-1, low-ECC, byte-mode QR for the bounded NKR1:ABCDE invite format.
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const PREFIX := "NKR1:"
var modules := PackedByteArray()
var reserved := PackedByteArray()

static func clean_code(value: String) -> String:
	var code := value.strip_edges().to_upper()
	if code.length()!=5: return ""
	for c in code:
		if not ALPHABET.contains(c): return ""
	return code

static func payload(code: String) -> String:
	var normalized := clean_code(code)
	return "" if normalized.is_empty() else PREFIX+normalized

static func parse(value: String) -> String:
	if value.length()!=10 or not value.begins_with(PREFIX): return ""
	var code := clean_code(value.substr(5))
	return code if PREFIX+code==value else ""

static func image_for_code(code: String) -> Image:
	var value := payload(code)
	if value.is_empty(): return null
	var encoder = new()
	return encoder.encode(value)

func _function(x: int, y: int, black: bool) -> void:
	modules[y*21+x] = 1 if black else 0
	reserved[y*21+x] = 1

func _finder(cx: int, cy: int) -> void:
	for dy in range(-4,5):
		for dx in range(-4,5):
			var x := cx+dx; var y := cy+dy
			if x<0 or y<0 or x>=21 or y>=21: continue
			var distance := maxi(absi(dx),absi(dy))
			_function(x,y,distance!=2 and distance!=4)

func _format() -> void:
	var data := 8 # LOW error correction, mask zero.
	var remainder := data
	for i in 10: remainder = (remainder<<1)^((remainder>>9)*0x537)
	var bits := ((data<<10)|remainder)^0x5412
	for i in 6: _function(8,i,((bits>>i)&1)!=0)
	_function(8,7,((bits>>6)&1)!=0)
	_function(8,8,((bits>>7)&1)!=0)
	_function(7,8,((bits>>8)&1)!=0)
	for i in range(9,15): _function(14-i,8,((bits>>i)&1)!=0)
	for i in 8: _function(20-i,8,((bits>>i)&1)!=0)
	for i in range(8,15): _function(8,6+i,((bits>>i)&1)!=0)
	_function(8,13,true)

func _append_bits(bits: Array[int], value: int, length: int) -> void:
	for i in range(length-1,-1,-1): bits.append((value>>i)&1)

func _multiply(a: int, b: int) -> int:
	var result := 0
	for i in range(7,-1,-1):
		result = (result<<1)^((result>>7)*0x11D)
		result ^= ((b>>i)&1)*a
	return result

func _ecc(data: Array[int]) -> Array[int]:
	var divisor: Array[int] = [0,0,0,0,0,0,1]
	var root := 1
	for i in 7:
		for j in 7:
			divisor[j] = _multiply(divisor[j],root)
			if j<6: divisor[j] ^= divisor[j+1]
		root = _multiply(root,2)
	var remainder: Array[int] = [0,0,0,0,0,0,0]
	for byte in data:
		var factor: int = byte^remainder.pop_front()
		remainder.append(0)
		for j in 7: remainder[j] ^= _multiply(divisor[j],factor)
	return remainder

func encode(value: String) -> Image:
	var bits: Array[int] = []
	_append_bits(bits,4,4)
	_append_bits(bits,value.length(),8)
	for byte in value.to_ascii_buffer(): _append_bits(bits,byte,8)
	_append_bits(bits,0,4)
	while bits.size()%8!=0: bits.append(0)
	var data: Array[int] = []
	for i in range(0,bits.size(),8):
		var byte := 0
		for j in 8: byte = (byte<<1)|bits[i+j]
		data.append(byte)
	var pad := 0
	while data.size()<19:
		data.append(0xEC if pad%2==0 else 0x11)
		pad += 1
	var ecc := _ecc(data)
	data.append_array(ecc)
	bits.clear()
	for byte in data: _append_bits(bits,byte,8)
	modules.resize(441); modules.fill(0)
	reserved.resize(441); reserved.fill(0)
	for i in 21:
		_function(6,i,i%2==0); _function(i,6,i%2==0)
	_finder(3,3); _finder(17,3); _finder(3,17)
	_format()
	var cursor := 0
	var right := 20
	while right>=1:
		if right==6: right=5
		for vertical in 21:
			var y := 20-vertical if ((right+1)&2)==0 else vertical
			for j in 2:
				var x := right-j
				if reserved[y*21+x]!=0: continue
				var black: bool = cursor<bits.size() and bits[cursor]!=0
				modules[y*21+x] = 1 if black!=((x+y)%2==0) else 0
				cursor += 1
		right -= 2
	var image := Image.create(232,232,false,Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	for y in 21:
		for x in 21:
			if modules[y*21+x]==0: continue
			image.fill_rect(Rect2i((x+4)*8,(y+4)*8,8,8),Color.BLACK)
	return image
