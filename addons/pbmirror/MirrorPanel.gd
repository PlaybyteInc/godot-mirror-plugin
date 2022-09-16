tool
extends VBoxContainer

var is_deploying = false
var is_exporting = false
var http_request
var upload_queue = []
var file_count = 1
var export_time
var settings: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	read_config()
	update_deploy_btn()

func _on_deploy_btn_pressed():
	if is_deploying:
		return
	is_deploying = true
	update_deploy_btn()
	deploy_prepare_project()

func _set_export_path(path):
	var parts = path.split("/")
	var index_name = parts[parts.size() - 1]
	parts.remove(parts.size() - 1)
	var folder = parts.join("/")
	var title = index_name.trim_suffix(".html")

	is_exporting = true
	settings["dir"] = folder
	settings["title"] = title
	update_deploy_btn()
	write_config()

func _export_end():
	is_exporting = false
	update_deploy_btn()

func read_config():
	var file = File.new()
	if file.open(".playbyte.json", File.READ) != OK:
		return

	var contents = file.get_as_text()
	file.close()
	load_config(contents)

func write_config():
	var file = File.new()
	if file.open(".playbyte.json", File.WRITE) != OK:
		return

	var contents = JSON.print(settings)
	file.store_string(contents)
	file.close()

func load_config(config):
	var json = JSON.parse(config)
	var dict = json.result as Dictionary
	for key in dict:
		settings[key] = dict[key]

func get_setting(name):
	if settings.has(name):
		return settings[name]
	else:
		return ""

func deploy_prepare_project():
	if get_setting("id").length() == 0 or get_setting("key").length() == 0:
		init_project()
	else:
		upload()

func init_project():
	if http_request != null:
		remove_child(http_request)

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_init_project_completed")

	var url = "https://playbyte.dev/api/projects"
	var error = http_request.request_raw(url, [], true, HTTPClient.METHOD_POST, [])
	if error != OK:
		push_error("An error occurred when creating a new project.")

func upload():
	var export_path = get_setting("dir")
	var title = get_setting("title")
	if export_path.length() == 0:
		push_error("Cannot upload without an export directory.")
		is_deploying = false
		return

	upload_queue = get_files(export_path, title)
	file_count = upload_queue.size()
	if !upload_queue.empty():
		upload_file(upload_queue.pop_front())
	update_deploy_btn()

func upload_file(filename):
	if http_request != null:
		remove_child(http_request)

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_upload_file_completed")

	var path = get_setting("dir") + "/" + filename
	var file = File.new()
	file.open(path, File.READ)

	var content_length = file.get_len()
	var headers = [
		"content-length: " + str(content_length),
		"Authorization: " + get_setting("key")
	]
	var body = file.get_buffer(content_length)
	file.close()

	var baseUrl = "https://playbyte.dev/api/projects/" + get_setting("id") + "/"
	var url = baseUrl + filename
	var error = http_request.request_raw(url, headers, true, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _init_project_completed(result, response_code, headers, body):
	var response = body.get_string_from_utf8()
	load_config(response)
	write_config()
	upload()

func _upload_file_completed(result, response_code, headers, body):
	if !upload_queue.empty():
		upload_file(upload_queue.pop_front())
	else:
		is_deploying = false
		export_time = Time.get_datetime_string_from_system()
		$url_label.text = "https://playbyte.dev/p/" + get_setting("id")
		set_build_notification()
	update_deploy_btn()

# https://gist.github.com/hiulit/772b8784436898fd7f942750ad99e33e
func get_files(path: String, title := "", files := []):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()

		while file_name != "":
			if (not dir.current_is_dir()) and file_name.begins_with(title):
				files.append(file_name)

			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access %s." % path)
	return files

func update_deploy_btn():
	if get_setting("dir").length() == 0 or is_exporting:
		$status_label.text = "Waiting for HTML5 export..."
	elif export_time != null:
		$status_label.text = "Deployed at " + export_time
	else:
		$status_label.text = ""

	$deploy_btn.disabled = len(get_setting("dir")) == 0 or is_deploying or is_exporting
	if is_deploying:
		var index = file_count - upload_queue.size()
		$deploy_btn.text = "Uploading file " + str(index) + " of " + str(file_count)
	else:
		$deploy_btn.text = "Deploy"

func set_build_notification():
	if http_request != null:
		remove_child(http_request)

	http_request = HTTPRequest.new()
	add_child(http_request)
	var headers = [
		"Authorization: " + get_setting("key")
	]

	var url = "https://playbyte.dev/api/projects/" + get_setting("id") + "/notify"
	var error = http_request.request_raw(url, headers, true, HTTPClient.METHOD_GET, [])
	if error != OK:
		push_error("An error occurred in the HTTP request.")
