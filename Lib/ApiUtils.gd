extends Node

var api_url : String
var api_key : String
var api_mod : int
var _quality : String
var time_out : int
var prompt : String

func _ready():
	
	var data = JSON.stringify({
		"model": "gpt-4o",
		"messages": [
				{
				"role": "user",
				"content":
					[
						{"type": "image_url", 
						"image_url":
							{"url": "data:image/jpeg;base64," + Global.image_to_base64("F:/WorkData/aiyinsitan.jpg", "auto"),
							"detail": "auto"}
						},
						{"type": "text", "text": "Hi, this is a test."}
					]
				}
			],
		"max_tokens": 300
		})
	var headers = ["Content-Type: application/json", 
					"Authorization: Bearer "]
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = time_out
	http_request.request_completed.connect(_on_openai_received)
	var error = http_request.request("http://127.0.0.1:8000/v1/chat/completions", headers, HTTPClient.METHOD_POST, data)
	if error != OK:
		print("Error: ", error)
	print(http_request.get_http_client_status())
		
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

var API_FUNC : Array[Callable] = [Callable(self,"openai_api"), 
								Callable(self,"qwen_api"), 
								Callable(self,"qwen_api"), 
								Callable(self,"claude_api"), 
								Callable(self,"openai_api"), 
								Callable(self,"openai_api")]
const RETRY_ATTEMPTS = 5
func run_api(image_path: String):
	api_save()
	var base64image = Global.image_to_base64(image_path, _quality)
	var current_prompt = Global.addition_prompt(prompt, image_path)
	API_FUNC[api_mod].call(current_prompt, base64image)

func openai_api(inputprompt : String, base64image : String):
	var data = JSON.stringify({
		"model": "gpt-4o",
		"messages": [
				{
				"role": "user",
				"content":
					[
						{"type": "image_url", 
						"image_url":
							{"url": "data:image/jpeg;base64," + base64image,
							"detail": _quality}
						},
						{"type": "text", "text": inputprompt}
					]
				}
			],
		"max_tokens": 300
		})
	var headers = ["Content-Type: application/json", 
					"Authorization: Bearer " + api_key]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = time_out
	http_request.request_completed.connect(_on_openai_received)
	var error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, data)
	if error != OK:
		print("Error: ", error)
	#print(http_request.get_http_client_status())
func _on_openai_received(result, response_code, headers, body):
	var json = JSON.new()
	var json_result = json.parse_string(body.get_string_from_utf8())
	var answer = json_result["choices"][0]["message"]["content"]
	print(answer)

func qwen_api(inputprompt : String, base64image : String):
	var data = JSON.stringify({
		"model": API_TYPE[api_mod],
		"input": {
			"messages": [
				{"role": "system",
				"content": [{"text": "You are a helpful assistant."}]},
				{"role": "user",
				"content": [{"image": "data:image/jpeg;base64," + base64image},
							{"text": inputprompt}]}
						]
				}
								})
	var headers = ["Authorization: Bearer " + api_key,
				"Content-Type: application/json"]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = time_out
	http_request.request_completed.connect(_on_qwen_received)
	var error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, data)
	if error != OK:
		print("Error: ", error)
	#print(http_request.get_http_client_status())
func _on_qwen_received(result, response_code, headers, body):
	var json = JSON.new()
	var response : String = body.get_string_from_utf8() 
	var json_result = json.parse_string(response)
	if "error" in response:
		return
	if json_result != null:
		var answer = ""
		# 安全地尝试
		if json_result.has("output") and\
			json_result["output"].has("choices") and\
			json_result["output"]["choices"].size() > 0 and\
			json_result["output"]["choices"][0].has("message") and\
			json_result["output"]["choices"][0]["message"].has("content") and\
			json_result["output"]["choices"][0]["message"]["content"].size() > 0 and\
			json_result["output"]["choices"][0]["message"]["content"][0].has("text"):
			answer = json_result["output"]["choices"][0]["message"]["content"][0]["text"]
		else:
			answer = json_result

func claude_api(inputprompt : String, base64image : String):
	var data = JSON.stringify({
		"model": "claude_api",
		"max_tokens": 300,
		"messages": [{
					"role": "user", 
					"content": [{
							"type": "image", 
							"source": {"type": "base64",
									"media_type": "image/jpeg",
									"data": base64image}
								},
								{
							"type": "text", 
							"text": inputprompt
								}]
					}]
							})
	var headers = ["Content-Type: application/json",
			"x-api-key:" + api_key,
			"anthropic-version: 2023-06-01"]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = time_out
	http_request.request_completed.connect(_on_claude_received)
	var error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, data)
	if error != OK:
		print("Error: ", error)
	#print(http_request.get_http_client_status())
func _on_claude_received(result, response_code, headers, body):
	var json = JSON.new()
	var json_result = json.parse_string(body.get_string_from_utf8())
	var answer = json_result["content"][0]["text"]

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

func _on_api_url_text_changed(new_text):
	$"../ApiInput/APIMod".select(is_api_id(new_text))
