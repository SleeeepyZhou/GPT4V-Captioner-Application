extends Node

const SAVEPATH = "user://data.save"

func zerojson():
	var prompt1 : String = "As an AI image tagging expert, please provide precise tags for these images to enhance CLIP model's understanding of the content. Employ succinct keywords or phrases, steering clear of elaborate sentences and extraneous conjunctions. Prioritize the tags by relevance. Your tags should capture key elements such as the main subject, setting, artistic style, composition, image quality, color tone, filter, and camera specifications, and any other tags crucial for the image. When tagging photos of people, include specific details like gender, nationality, attire, actions, pose, expressions, accessories, makeup, composition type, age, etc. For other image categories, apply appropriate and common descriptive tags as well. Recognize and tag any celebrities, well-known landmark or IPs if clearly featured in the image. Your tags should be accurate, non-duplicative, and within a 20-75 word count range. These tags will use for image re-creation, so the closer the resemblance to the original image, the better the tag quality. Tags should be comma-separated. Exceptional tagging will be rewarded with $10 per image."
	var zero_data = {
		"api" : {
			"gpt-4o" : [true, "https://api.openai.com/v1/chat/com", ""],
			"local" : [false, "http://127.0.0.1:8000/v1/chat/completions", ""]
		},
		"prompt" : [prompt1, "Describe this image in a very detailed manner."]
			}
	var json_string = JSON.stringify(zero_data)
	var save_data = FileAccess.open(Global.SAVEPATH, FileAccess.WRITE)
	save_data.store_string(json_string)
	save_data.close()

func readjson():
	if FileAccess.file_exists(Global.SAVEPATH):
		var json_string = FileAccess.open(SAVEPATH, FileAccess.READ).get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error")
			return
		var save_data = json.get_data()
		return save_data
	else:
		zerojson()
		var save_data = readjson()
		return save_data
		
