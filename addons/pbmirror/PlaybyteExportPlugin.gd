extends EditorExportPlugin

signal set_export_path(path)
signal export_end()

func _export_begin(features, is_debug, path, flags):
	if not "HTML5" in features:
		return
	emit_signal("set_export_path", path)

func _export_end():
	emit_signal("export_end")
