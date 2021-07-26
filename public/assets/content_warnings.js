// content warnings
function setup_content_warnings(content_warnings, ext_link) {
  if (content_warnings.length > 0) {
    var $content_warnings = $('<div class="content-warnings"></div>');
    apply_content_warnings(content_warnings, $content_warnings, ext_link);
  }
}

function setup_iherited_content_warnings(obj, ext_link) {
  var $inherited_tags = $('<div class="content-warnings inherited-content-warnings"><div class="inherited-content-warning-prefix">Applied at the <a href="' + obj.uri + '">' + obj.level + '</a> level</div></div>');
  apply_content_warnings(obj.tags, $inherited_tags, ext_link);
}

function apply_content_warnings(content_warnings, tag_wrapper, ext_link) {
  $.each(content_warnings, function(idx, val) {
      tag_wrapper.append('<span>' + val + '</span>');
    });
  if (ext_link != '') {
    tag_wrapper.append('<div class="content-warning-external-link">' + ext_link + '</div>');
  }
  $('#main-content h1').after(tag_wrapper);
}

function setup_content_warning_submit(modalId, text) {
    $(".noscript").hide();
    $('#main-content h1').after('<button id="content-warning-sub" class="btn btn-success content-warning-submit"><i class="fa fa-paper-plane"></i>&nbsp;Help us add a Content Warning</button>');
    $('#main-content').on('click', '#content-warning-sub', function(e) {
      e.preventDefault();
      content_warning_form(text);
    });
}

function content_warning_form(text) {
  console.log('foo');
    var $modal = $("#content_warning_submit_modal");
    $modal.modal('show');
    var x = $modal.find('.action-btn');
    var btn;
    if (x.length == 1) {
        btn = x[0];
    }
    else {
        btn = x;
    }
    $(btn).attr('id', "submit_content_warning_btn");
    $(btn).html(text);
    $('body').on('click', '#submit_content_warning_btn', function(e) {
        $("#submit_content_warning_form").submit();
    });

    $('#user_name',this).closest('.form-group').removeClass('has-error');
    $('#user_email',this).closest('.form-group').removeClass('has-error');

    $('#submit_content_warning_form', '#content_warning_submit_modal').on('submit', function() {
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
  $('.content-warnings span').click(function() {
    if ($('a[href="#aspace_content_warnings_list"]').attr('aria-expanded') == "false") {
      $('a[href="#aspace_content_warnings_list"]').click();
    }
    panelHeaderHeight = $('#aspace_content_warnings_list').siblings('.panel-heading').outerHeight();
    offsetTop = $('#aspace_content_warnings_list').offset().top - panelHeaderHeight;
    window.scrollTo({top: offsetTop, behavior: 'smooth'})
  });
});