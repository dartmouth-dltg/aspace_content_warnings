// content warnings

const createEl = (tag, className, text) => {
  const el = document.createElement(tag);
  if (className) el.className = className;
  if (text !== undefined) el.textContent = text;
  return el;
};

class ContentWarningTags {
  #title = document.querySelector('#main-content h1');

  constructor(tags, extLink = '') {
    this.tags = tags;
    this.extLink = extLink;
  }

  render({ inherited = false, prefix = null } = {}) {
    const wrapper = createEl('div', inherited ? 'content-warnings inherited-content-warnings' : 'content-warnings');
    this.tags.forEach((tag) => {
      const item = createEl('span', 'cw-tag');
      item.append(createEl('span', 'cw-text', tag));
      wrapper.append(item);
    });

    this.#title?.after(wrapper);
    if (prefix) this.#title?.after(prefix);
    if (this.extLink) {
      // extLink is trusted markup built server-side (see _upper_record_innards)
      const link = createEl('div', 'content-warning-external-link');
      link.innerHTML = this.extLink;
      wrapper.after(link);
    }
    return wrapper;
  }

  static inheritedPrefix({ uri, level }) {
    const prefix = createEl('div', 'inherited-content-warning-prefix');
    const anchor = createEl('a', null, level);
    anchor.href = uri;
    prefix.append('Applied at the ', anchor, ' level');
    return prefix;
  }
}

class ContentWarningSubmit {
  static REQUIRED_FIELDS = ['#user_name', '#user_email'];

  constructor(modalId, submitText, buttonText) {
    this.$modal = $(`#${modalId}`);
    this.submitText = submitText;
    this.buttonText = buttonText;
  }

  init() {
    $('.noscript').hide();
    this.#addTriggerButton();
    this.#bindModal();
  }

  #addTriggerButton() {
    const target = document.querySelector('.content-warnings')
      ?? document.querySelector('.content-warning-external-link')
      ?? document.querySelector('#main-content h1');

    const button = createEl('button', 'btn btn-primary content-warning-submit');
    button.id = 'content-warning-sub';
    button.innerHTML = '<i class="fa fa-paper-plane"></i>&nbsp;';
    button.append(this.buttonText);
    target?.after(button);

    $('#main-content').on('click', '#content-warning-sub', (e) => {
      e.preventDefault();
      this.#open();
    });
  }

  // bind once so reopening the modal doesn't stack handlers
  #bindModal() {
    $('body').on('click', '#submit_content_warning_btn', () => {
      $('#submit_content_warning_form').submit();
    });

    this.$modal.find('#submit_content_warning_form').on('submit', (e) => {
      const form = $(e.currentTarget);
      let proceed = true;
      ContentWarningSubmit.REQUIRED_FIELDS.forEach((selector) => {
        const field = form.find(selector);
        const missing = field.val().trim() === '';
        field.closest('.form-group').toggleClass('has-error', missing);
        if (missing) proceed = false;
      });
      return proceed;
    });
  }

  #open() {
    this.$modal.modal('show');
    this.$modal.find('.action-btn').attr('id', 'submit_content_warning_btn').html(this.submitText);
    this.$modal.find('.form-group').removeClass('has-error');
  }
}

// entry points called from inline <script> tags in the PUI views
const setupContentWarnings = (tags, extLink) => {
  if (tags.length > 0) new ContentWarningTags(tags, extLink).render();
};

const setupInheritedContentWarnings = (obj, extLink) => {
  new ContentWarningTags(obj.tags, extLink).render({
    inherited: true,
    prefix: ContentWarningTags.inheritedPrefix(obj),
  });
};

const addHeaderLinkToHCStatement = (statement) => {
  $(() => {
    const el = createEl('div', 'harmful-content-header');
    el.innerHTML = statement;
    $('#navigation').append(el);
  });
};

const setupContentWarningSubmit = (modalId, submitText, buttonText) => {
  new ContentWarningSubmit(modalId, submitText, buttonText).init();
};

// clicking a tag scrolls to the full list
$(() => {
  $('.content-warnings').not('.inherited-content-warnings').children('span').on('click', () => {
    const list = $('.aspace-content-warnings-list');
    const headerHeight = list.prevAll('h2:first').outerHeight(true);
    window.scrollTo({ top: list.offset().top - headerHeight, behavior: 'smooth' });
  });
});
