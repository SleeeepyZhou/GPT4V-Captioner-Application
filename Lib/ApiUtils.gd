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
func run_api(image_path: String):
	api_save()
	var base64image = Global.image_to_base64(image_path, _quality)
	var current_prompt = Global.addition_prompt(prompt, image_path)
	API_FUNC[api_mod].call(current_prompt, base64image)

const RETRY_ATTEMPTS = 5
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
	var headers = JSON.stringify({
		"Content-Type": "application/json",
		"Authorization": "Bearer " + api_key
		})
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)
	var error = http_request.request("https://")
	if error != OK:
		push_error("在HTTP请求中发生了一个错误。")
	var body = JSON.new().stringify({"name": "Godette"})
	error = http_request.request("https://httpbin.org/post", [], HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("在HTTP请求中发生了一个错误。")

func qwen_api(inputprompt : String, base64image : String):
	var request_body = JSON.stringify({
		"model": API_TYPE[api_mod],
		"input": {
			"messages": [
				{"role": "system",
				"content": [{"text": "You are a helpful assistant."}]
				},
				{"role": "user",
				"content": [{"image": "data:image/jpeg;base64," + base64image},
						{"text": inputprompt}]
				}
						]
					}
				})
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

func claude_api():
	# Claude API
	#data = {
		#"model": model,
		#"max_tokens": 300,
		#"messages": [
			#{"role": "user", "content": [
					#{"type": "image", "source": {
							#"type": "base64",
							#"media_type": "image/jpeg",
							#"data": image_base64
						#}
					#},
					#{"type": "text", "text": prompt}
				#]  
			#}
		#]
	#}
#
	## print(f"data: {data}\n")
#
	#headers = {
		#"Content-Type": "application/json",
		#"x-api-key:": api_key,
		#"anthropic-version": "2023-06-01"
	#}
	pass

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
