extends VBoxContainer

@onready var Api_utils = $ApiUtils
const IMAGE_TYPE = ["jpg", "png", "bmp", "gif", "tif", "tiff", "jpeg", "webp"]

func _ready():
	get_viewport().files_dropped.connect(on_files_dropped) # 文件拖拽信号
	if !FileAccess.file_exists(Global.SAVEPATH):
		Global.zerojson()
	updata_list()

# 图片放入
var single_path : String
func on_files_dropped(files):
	var path : String = files[0]
	if IMAGE_TYPE.has(path.get_extension()):
		var image = Image.load_from_file(path)
		$"Tab/Image Process/Single Image/SingleImage/UpOut/ImageUp/Label".visible = false
		$"Tab/Image Process/Single Image/SingleImage/UpOut/ImageUp".texture \
		= ImageTexture.create_from_image(image)
		single_path = path

# 链接跳转
func _on_thank_meta_clicked(meta):
	OS.shell_open(meta)

# 提示词存储
func updata_list():
	$PromptSave/PromptList.clear()
	var list = Global.readjson()["prompt"]
	for prompt in list:
		$PromptSave/PromptList.add_item(prompt)
func _prompt_save_pressed():
	var dir = Global.readjson()
	dir["prompt"].append($Prompt.text)
	var save_file = FileAccess.open(Global.SAVEPATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(dir))
	save_file.close()
	updata_list()
func _prompt_delete_pressed():
	var dir = Global.readjson()
	dir["prompt"].erase($PromptSave/PromptList.text)
	var save_file = FileAccess.open(Global.SAVEPATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(dir))
	save_file.close()
	updata_list()
func _prompt_load_pressed():
	$Prompt.text = $PromptSave/PromptList.text

