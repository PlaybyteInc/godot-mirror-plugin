extends EditorExportPlugin

signal set_export_path(path)
signal export_end

func _export_begin(features, is_debug, path, flags):
	if not "web" in features:
		return
	set_export_path.emit(path)

func _export_end():
	export_end.emit()

func _get_name():
	return "playbytemirror"
