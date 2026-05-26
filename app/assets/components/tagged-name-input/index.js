class TaggedNameInputElement extends HTMLElement {
  #tags = [];
  #input;
  #queryInput;
  #tagContainer;

  constructor() {
    super();
    this.autocompleteFuture = import('bootstrap5-autocomplete')
      .then(({default: Autocomplete}) => Autocomplete);
  }

  connectedCallback() {
    this.#input = this.querySelector('input');
    this.labelField = this.getAttribute('label-field') || 'name';

    const initialValue = this.#input.value || '';
    if (initialValue) {
      // split on "/" with optional surrounding spaces/NBSPs (handles raw "/" and sanitize_name " / " format)
      this.#tags = initialValue.split(/[\s ]*\/[\s ]*/).map(s => s.trim()).filter(Boolean);
    }

    this.#buildUI();
    this.#setupAutocomplete();

    this.closest('form')?.addEventListener('submit', this);
  }

  disconnectedCallback() {
    this.closest('form')?.removeEventListener('submit', this);
  }

  #buildUI() {
    const wrapper = document.createElement('div');
    wrapper.className = 'form-control tagged-name-input d-flex flex-wrap align-items-center gap-1';
    wrapper.style.cssText = 'height:auto; min-height:2.375rem; padding:0.25rem 0.5rem; cursor:text';

    this.#tagContainer = document.createElement('span');
    this.#tagContainer.className = 'd-inline-flex flex-wrap align-items-center gap-1';

    this.#queryInput = document.createElement('input');
    this.#queryInput.type = 'text';
    this.#queryInput.style.cssText = 'border:0; outline:0; background:transparent; min-width:80px; flex:1; padding:0; line-height:1.5';

    wrapper.appendChild(this.#tagContainer);
    wrapper.appendChild(this.#queryInput);
    wrapper.addEventListener('click', this);

    this.#input.after(wrapper);
    this.#input.type = 'hidden';

    this.#queryInput.addEventListener('keydown', this);
    this.#renderTags();
  }

  #setupAutocomplete() {
    this.autocompleteFuture.then((Autocomplete) => {
      const hrefUrl = new URL(this.getAttribute('href'), document.location.href);
      const serverParams = Object.fromEntries(hrefUrl.searchParams.entries());
      const serverBase = hrefUrl.origin + hrefUrl.pathname;
      this.autocomplete = new Autocomplete(this.#queryInput, {
        liveServer: true, server: serverBase, serverParams,
        showAllSuggestions: true,
        suggestionsThreshold: 3,
        fixed: true,
        noCache: false,
        labelField: this.labelField,
        onSelectItem: (item) => this.#addTag(item[this.labelField]),
      });
    });
  }

  handleEvent(e) {
    switch (e.type) {
      case 'keydown':
        if (e.target === this.#queryInput) this.#handleKeydown(e);
        break;
      case 'click':
        if (e.target.closest('.tni-remove')) {
          this.#removeTag(parseInt(e.target.closest('.tni-remove').dataset.idx));
        } else {
          this.#queryInput.focus();
        }
        break;
      case 'submit':
        if (this.#queryInput.value.trim()) this.#addTag(this.#queryInput.value.trim());
        break;
    }
  }

  #handleKeydown(e) {
    if (e.key === 'Enter') {
      const firstLink = this.autocomplete?._dropElement?.querySelector('a');
      if (firstLink) {
        firstLink.click();
      } else if (this.#queryInput.value.trim()) {
        this.#addTag(this.#queryInput.value.trim());
      }
      e.preventDefault();
    } else if (e.key === 'Backspace' && this.#queryInput.value === '') {
      this.#removeLastTag();
      e.preventDefault();
    }
  }

  #addTag(label) {
    this.#tags.push(label);
    this.#queryInput.value = '';
    this.#sync();
  }

  #removeTag(idx) {
    this.#tags.splice(idx, 1);
    this.#sync();
  }

  #removeLastTag() {
    if (this.#tags.length > 0) {
      this.#tags.pop();
      this.#sync();
    }
  }

  #sync() {
    this.#input.value = this.#tags.join(' / ');
    this.#renderTags();
  }

  #renderTags() {
    this.#tagContainer.innerHTML = '';
    this.#tags.forEach((tag, idx) => {
      const badge = document.createElement('span');
      badge.className = 'badge bg-secondary d-inline-flex align-items-center gap-1';
      badge.style.cssText = 'font-size:0.875em; font-weight:normal';
      badge.appendChild(document.createTextNode(tag));

      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'tni-remove btn-close btn-close-white';
      btn.style.cssText = 'font-size:0.55em';
      btn.dataset.idx = idx;
      btn.setAttribute('aria-label', 'Entfernen');
      badge.appendChild(btn);

      this.#tagContainer.appendChild(badge);
    });

    this.#queryInput.required = !!(this.#input?.required && this.#tags.length === 0);
  }
}

document.addEventListener('DOMContentLoaded', () => customElements.define('tagged-name-input', TaggedNameInputElement));
