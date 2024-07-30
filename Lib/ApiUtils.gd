extends Node

var api_url : String
var api_key : String
var api_mod : int
var _quality : String
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
	api_mod = $"../ApiInput/APIMod".selected
	_quality = $"../ApiInput/ImageQ".text
	time_out = $"../ApiInput/Timeout".value
	prompt = $"../Prompt".text

const API_TYPE = ["gpt-4o", "qwen-vl-plus", "qwen-vl-max", "claude", "local", "???"]
const RETRY_ATTEMPTS = 5

func is_api_id(url : String) -> int:
	if url.ends_with("/v1/services/aigc/multimodal-generation/generation"):
		return 1
	elif url.ends_with("v1/messages") or (API_TYPE[api_mod] == "claude"):
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
	if API_TYPE[api_mod].begins_with("qwen") and mod.begins_with("qwen"):
		mod = API_TYPE[api_mod]
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

func run_api(image_path: String):
	api_save()
	var image = Global.image_to_base64(image_path)
	var current_prompt = addition_prompt(prompt, image_path)

func qwen_api():
	pass


##func qwen_api(image_path, prompt, api_key):
	## 设置环境变量
	#os.environ['DASHSCOPE_API_KEY'] = api_key
#
	## 构造请求体
	#var request_body = JSON.stringify({
		#"model": QWEN_MOD,
		#"input": {
			#"messages": [
				#{
					#"role": "system",
					#"content": [
						#{"text": "You are a helpful assistant."}
					#]
				#},
				#{
					#"role": "user",
					#"content": [
						#{"image": "file://" + image_path},
						#{"text": prompt}
					#]
				#}
			#]
		#}
	#})
#
	## 创建HTTP请求对象
	#var http_request = HTTPRequest.new()
	#http_request.set_method("POST")
	#http_request.set_uri(DASHSCOPE_API_URL)
	#http_request.set_header("Content-Type", "application/json")
	#http_request.set_header("Authorization", "Bearer " + api_key)
	#http_request.set_body(request_body)
#
	## 发送HTTP请求
	#http_request.connect("response_received", self, "_on_http_response_received")
	#HTTPClient.new().request(http_request)
#
## 处理HTTP响应
#func _on_http_response_received(http_request, response):
	#if response.get_error() == OK:
		#var json_result = JSON.parse(response.get_body())
		#if '"status_code": 400' in json_result:
			#print("API error: " + json_result)
			#return
		#if json_result.get("output") and json_result["output"].get("choices") and json_result["output"]["choices"][0].get("message") and json_result["output"]["choices"][0]["message"].get("content"):
			#var content = json_result["output"]["choices"][0]["message"]["content"]
			#if content[0].get("text", False):
				#print(content[0]["text"])
			#else:
				#var box_value = content[0]["box"]
				#var text_value = content[1]["text"]
				#var b_value = re_search(r"<ref>(.*?)</ref>", box_value).get_group(1)
				#print(b_value + text_value)
		#else:
			#print(json_result)
	#else:
		#print("Error:", response.get_error_message())
##

func claude_api():
	pass

func openai_api():
	pass

func addition_prompt(text : String, image_path : String):
	if '{' not in text and '}' not in text:
		return prompt
	var file_name = image_path.get_file().rstrip("." + image_path.get_extension()) + ".txt"
	var dir_path = text.substr(text.find("{")+1, text.find("}")-text.find("{")-1)
	var full_path = (dir_path + "/" + file_name).simplify_path()
	var file = FileAccess.open(full_path, FileAccess.READ)
	var file_content := ""
	if file:
		file_content = file.get_as_text()
		file.close()
	else:
		return "Error reading file: Could not open file."
	return text.replace("{" + dir_path + "}", file_content)

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
