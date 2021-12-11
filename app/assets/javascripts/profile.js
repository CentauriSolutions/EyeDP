function add_field(item) {
	var button = $(item);
	var name = button.data('name');
	var target = button.data('target');
	var text_field = $('<input class="form-control" type="text" name="' + name + '[]" value="" placeholder="Add Value">');
	var container = $('#' + target);
	container.append(text_field);
}

function remove_element(item) {
	var button = $(item);
	var target = button.data('target');
  debugger
	$('#'+target).remove()
}
