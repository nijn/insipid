
// detect tag insertion and provide suggestions
$(document).ready(function()
{
	var f = $('form input[name=tags]');
	var ls = $('#suggestlist');

	var stopSuggesting = false;
	//var isFocussed = true;
	//var defaultTab = false; // set true to allow tabbing to the next element
	
	f.keyup(function(e)
	{
		var ulist = f.val().split(' ');
		
		var k = e.keyCode || e.which;
		switch (k)
		{
			// tab to navigate suggestions
			// The first suggestion is already selected. Tabbing 
			// selects the next suggestion, until the end of the 
			// list is reached, from which the selection loops to
			// the start of the list.
			case 9:
				// implemented at document level
				break;

			// esc halts suggestions for this tag
			case 27:
				hide(ls);
				stopSuggesting = true;
				break;

			// Spacebar to make a selection or add a new tag.
			// If there is a selection, pressing spacebar will add
			// the selection to the field. Keep typing the preferred
			// tag name if none of the suggestions are valid. The
			// suggestions list will disappear - pressing spacebar
			// at this point allows for adding the next tag.
			case 32:
				if (ls.css('display') != 'none' && ls.find('li.sel').index() >= 0) {
					ulist.pop(); ulist.pop();
					
					var v = ulist.join(' ');
					if (ulist.length) {
						v += ' ';
					}
					f.val(v + ls.find('li.sel').text() + ' ');
					hide(ls);
					//defaultTab = true;
				}
				else {
					hide(ls);
					stopSuggesting = false;
				}
				break;
			
			// left arrow makes previous selection
			case 37:
				next(ls, 'backward');
				break;

			// right arrow makes next selection
			case 39:
				next(ls, 'forward');
				break;

			// initiate suggestions
			default:
				var w = ulist.pop();

				if (w.length > 1 && stopSuggesting == false) {
					$.ajax({
						url: 'lib/tagsSuggest.pl?' + w,
						dataType: 'html',
						success: function(o) {
							if (o.length > 0) {
								ls.slideDown('fast');
								ls.find('ul').html(o);
							}
							else {
								hide(ls);
							}
						}
					});
					//defaultTab = false;
				}
				else {
					hide(ls);
				}
				break;
		} //switch
	});
}).keydown(function(e)
{
	var k = e.keyCode || e.which;
	var ls = $('#suggestlist');
	var defaultTab = ls.css('display') == 'none'; 
	var isFocussed = e.target.tagName.toLowerCase() == 'input' && e.target.name == 'tags';

	if (k == 9 && isFocussed && !defaultTab) {
		e.preventDefault();
		next(ls);
	}
});

// Allows for directional navigation of suggestion list.
// With forward direction, tabbing selects the right-next 
// suggestion. When the end of the list is reached, the 
// selection jumps to the start of the list.
//
// @param ls:obj - the suggest list
// @param dir:string - "forward" | "backward"
function next(ls, dir)
{
	var n;
	var	i = ls.find('li.sel').index();
	var c = ls.find('li.sel');
	c.removeClass('sel');

	switch (dir)
	{
		case 'backward':
			i--;
			n = c.prev('li');
			break;

		case 'forward':
		default:
			if (i < 0) {
				i = 0;
			}
			else {
				i++;
			}
			n = c.next('li');
			break;
	}
	
	// jump to the start
	if (i >= ls.find('li').size() || i == 0) {
		ls.find('li:first-child').addClass('sel');
	}
	// jump to the end
	else if (i < 0) {
		ls.find('li:last-child').addClass('sel');
	}
	// select the next suggestion
	else {
		n.addClass('sel');
	}
}

// Hides the suggest list.
// @param ls:obj - the suggest list
function hide(ls)
{
	ls.find('ul').empty();
	ls.hide();
}

