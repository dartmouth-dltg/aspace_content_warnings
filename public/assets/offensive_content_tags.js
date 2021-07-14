// offensive content tags
// corrects link in sidebar in edit mode
function setup_offensive_tags(offensive_tags, ext_link) {
  if (offensive_tags.length > 0) {
    var $offensive_content_tags = $('<div class="offensive-tags"></div>');
    apply_offensive_tags(offensive_tags, $offensive_content_tags, ext_link);
  }
}

function setup_iherited_offensive_content_tags(obj, ext_link) {
  var $inherited_tags = $('<div class="offensive-tags inherited-offensive-tags">Applied at the <a href="' + obj.uri + '">' + obj.level + '</a> level:</div>');
  apply_offensive_tags(obj.tags, $inherited_tags, ext_link);
}

function apply_offensive_tags(offensive_tags, tag_wrapper, ext_link) {
  $.each(offensive_tags, function(idx, val) {
      tag_wrapper.append('<span>' + val + '</span>');
    });
  if (ext_link != '') {
    tag_wrapper.append('<div class="offensive-content-external-link">' + ext_link + '</div>');
  }
  $('#main-content h1').after(tag_wrapper);
}

$().ready(function() {
  $('.offensive-tags').click(function() {
    if ($('a[href="#aspace_offensive_content_tags_list"]').attr('aria-expanded') == "false") {
      $('a[href="#aspace_offensive_content_tags_list"]').click();
    }
    document.getElementById('aspace_offensive_content_tags_list').scrollIntoView();
  });
});