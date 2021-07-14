// offensive content tags
// corrects link in sidebar in edit mode
function setup_offensive_tags(offensive_tags, ext_link) {
  if (offensive_tags.length > 0) {
    var $offensive_content_tags = $('<div class="offensive-tags"></div>');
    apply_offensive_tags(offensive_tags, $offensive_content_tags, ext_link);
  }
}

function setup_iherited_offensive_content_tags(obj, ext_link) {
  var $inherited_tags = $('<div class="offensive-tags inherited-offensive-tags"><div class="inherited-offensive-prefix">Applied at the <a href="' + obj.uri + '">' + obj.level + '</a> level</div></div>');
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

function setup_content_warning_submit(modalId, text) {
    $(".noscript").hide();
    $('#main-content h1').after('<button id="offensive-content-sub" class="btn btn-success offensive-content-submit"><i class="fa fa-paper-plane"></i>&nbsp;Help us add a Content Warning</button>');
    $('#main-content').on('click', '#offensive-content-sub', function(e) {
      e.preventDefault();
      offensive_content_form(text);
    });
}

function offensive_content_form(text) {
  console.log('foo');
    var $modal = $("#offensive_content_submit_modal");
    $modal.modal('show');
    var x = $modal.find('.action-btn');
    var btn;
    if (x.length == 1) {
        btn = x[0];
    }
    else {
        btn = x;
    }
    $(btn).attr('id', "submit_offensive_content_btn");
    $(btn).html(text);
    $('body').on('click', '#submit_offensive_content_btn', function(e) {
        $("#submit_offensive_content_form").submit();
    });

    $('#user_name',this).closest('.form-group').removeClass('has-error');
    $('#user_email',this).closest('.form-group').removeClass('has-error');

    $('#submit_offensive_content_form', '#offensive_content_submit_modal').on('submit', function() {
        var proceed = true;

        if ($('#user_name',this).val().trim() == '') {
            $('#user_name',this).closest('.form-group').addClass('has-error');
            proceed = false;
        } else {
            $('#user_name',this).closest('.form-group').removeClass('has-error');
        }
        if ($('#user_email',this).val().trim() == '') {
            $('#user_email',this).closest('.form-group').addClass('has-error');
            proceed = false;
        } else {
            $('#user_email',this).closest('.form-group').removeClass('has-error');
        }

        return proceed;
    });
}

$().ready(function() {
  $('.offensive-tags span').click(function() {
    if ($('a[href="#aspace_offensive_content_tags_list"]').attr('aria-expanded') == "false") {
      $('a[href="#aspace_offensive_content_tags_list"]').click();
    }
    document.getElementById('aspace_offensive_content_tags_list').scrollIntoView();
  });
});