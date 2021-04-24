function add_field(event, ) {
	var button = $(event);
	var name = button.data('name');
	var target = button.data('target');
	var text_field = $('<input class="form-control" type="text" name="' + name + '[]" value="" placeholder="Add Value">');
	var container = $('#' + target);
	container.append(text_field);
}