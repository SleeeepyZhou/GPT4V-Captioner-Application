extends HTTPRequest

var api_url : String
var api_key : String
var api_mod : String
var _quality : int
var time_out : int
var prompt : String

func _ready():
	for type in API_TYPE:
		$"../Tab/API Config/API Config/API/Box/ApiList".add_item(type)
		$"../ApiInput/APIMod".add_item(type)
	var dir = Global.readjson()["api"]
	for key in dir:
		if dir[key][0]:
			$"../ApiInput/ApiURL".text = dir[key][1]
			$"../ApiInput/ApiKey".text = dir[key][2]
			break

func _update():
	api_url = $"../ApiInput/ApiURL".text
	api_key = $"../ApiInput/ApiKey".text
	api_mod = $"../ApiInput/APIMod".text
	_quality = $"../ApiInput/ImageQ".selected
	time_out = $"../ApiInput/Timeout".value
	prompt = $"../Prompt".text

const API_TYPE = ["gpt-4o", "qwen-vl-plus", "qwen-vl-max", "claude", "local", "???"]

func is_api_id(url : String) -> int:
	if url.ends_with("/v1/services/aigc/multimodal-generation/generation"):
		return 1
	elif url.ends_with("v1/messages") or ("claude" in api_mod.to_lower()):
		return 3
	elif url.begins_with("http://127.0.0.1"):
		return 4
	elif url.ends_with("/v1/chat/completions"):
		return 0
	else:
		return 5
func api_save():
	_update()
	var mod : String = API_TYPE[is_api_id(api_url)]
	if api_mod.begins_with("qwen") and mod.begins_with("qwen"):
		mod = api_mod
	var dir = Global.readjson()
	if dir["api"].has(mod):
		var is_de := false
		for key in dir["api"]:
			if dir["api"][key][0] and key == mod:
				is_de = true
				break
		dir["api"][mod] = [is_de, api_url, api_key]
	else:
		dir["api"][mod] = [false, api_url, api_key]

func run_api():
	pass

func addition_prompt(text : String, image_path : String):
	if '{' not in text and '}' not in text:
		return prompt
	var _name = image_path.get_basename().erase(0,image_path.get_base_dir().length()+1)
	var file_name = _name + ".txt"
	var dir_path = text.substr(text.find("{")+1, text.find("}")-text.find("{")-1)
	var full_path = dir_path

func _api_switch_pressed():
	var mod = API_TYPE[$"../Tab/API Config/API Config/API/Box/ApiList".selected]
	var dir = Global.readjson()
	if dir["api"].has(mod):
		$"../ApiInput/ApiURL".text = dir["api"][mod][1]
		$"../ApiInput/ApiKey".text = dir["api"][mod][2]
		$"../ApiInput/APIMod".selected = $"../Tab/API Config/API Config/API/Box/ApiList".selected
		$"../Tab/API Config/API Config/API/Box/ApiState".text = mod + " active."
	else:
		$"../Tab/API Config/API Config/API/Box/ApiState".text = "This API has not been stored."

func _set_api_default_pressed():
	var mod = API_TYPE[$"../Tab/API Config/API Config/API/Box/ApiList".selected]
	var dir = Global.readjson()
	for key in dir["api"]:
		if dir["api"][key][0]:
			["api"][key][0] = false
			break
	if dir["api"].has(mod):
		dir["api"][mod][0] = true
	else:
		_update()
		dir["api"][mod] = [true, api_url, api_key]
	var save_file = FileAccess.open(Global.SAVEPATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(dir))
	save_file.close()
	$"../Tab/API Config/API Config/API/Box/ApiState".text = mod + " has been set as default."
