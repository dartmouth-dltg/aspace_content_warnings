// content warnings
function setupContentWarnings(content_warnings, ext_link) {
  if (content_warnings.length > 0) {
    var content_warnings_wrapper = $('<div class="content-warnings"></div>');
    applyContentWarnings(content_warnings, content_warnings_wrapper, ext_link);
  }
}

function setupInheritedContentWarnings(obj, ext_link) {
  var inherited_prefix = '<div class="inherited-content-warning-prefix">Applied at the <a href="' + obj.uri + '">' + obj.level + '</a> level</div>';
  var inherited_tags_wrapper = $('<div class="content-warnings inherited-content-warnings"></div>');
  applyContentWarnings(obj.tags, inherited_tags_wrapper, ext_link, inherited_prefix);
}

function applyContentWarnings(content_warnings, tag_wrapper, ext_link, prefix = null) {
  $.each(content_warnings, function(idx, val) {
    tag_wrapper.append('<span class="cw-tag"><span class="cw-text">' + val + '</span></span>');
  });
  $('#main-content h1').after(tag_wrapper);
  if (prefix != null) {
    $('#main-content h1').after(prefix);
  }
  if (ext_link != '') {
    tag_wrapper.after('<div class="content-warning-external-link">' + ext_link + '</div>');
  }
}

function addHeaderLinkToHCStatement(stmnt) {
  $().ready(function() {
    $('#navigation').append('<div class="harmful-content-header">' + stmnt + '</div>');
  });
}

function setupContentWarningSubmit(modalId, text, btnText) {
  $(".noscript").hide();
  var target = $('#main-content h1');
  if ($('.content-warnings').length > 0 ) {
    target = $('.content-warnings');
  }
  else if ($('.content-warning-external-link').length > 0) {
    target = $('.content-warning-external-link');
  }

  target.after('<button id="content-warning-sub" class="btn btn-primary content-warning-submit"><i class="fa fa-paper-plane"></i>&nbsp;' + btnText + '</button>');
  $('#main-content').on('click', '#content-warning-sub', function(e) {
    e.preventDefault();
    contentWarningForm(text);
  });
}

function contentWarningForm(text) {
  var $modal = $("#content_warning_submit_modal");
  $modal.modal('show');
  var x = $modal.find('.action-btn');
  var btn;
  if (x.length == 1) {
    btn = x[0];
  } else {
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
  $('.content-warnings').not('.inherited-content-warnings').children('span').click(function() {
    const headerHeight = $('.aspace-content-warnings-list').prevAll('h2:first').outerHeight(true);
    const offsetTop = $('.aspace-content-warnings-list').offset().top - headerHeight;
    window.scrollTo({top: offsetTop, behavior: 'smooth'})
  });
});