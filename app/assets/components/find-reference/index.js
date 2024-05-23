

class FindReferenceElement extends HTMLElement {
  constructor() {
    super();
    this.autocompleteFuture = import('bootstrap5-autocomplete')
      .then(({default: Autocomplete}) => Autocomplete);
  }

  connectedCallback() {
    this.input = this.querySelector('input');
    this.valueField = this.getAttribute('value-field') || 'value';
    this.labelField = this.getAttribute('label-field') || 'label';

    this.autocompleteFuture.then((Autocomplete) => {
      this.queryInput = document.createElement('input');
      this.queryInput.classList = this.input.classList;
      this.queryInput.required = this.input.required;
      this.queryInput.type = 'text';
      this.queryInput.value = this.getAttribute('initial-label');
      this.queryInput.addEventListener("keydown", this);
      this.input.after(this.queryInput);
      this.input.type = 'hidden';
      this.autocomplete = new Autocomplete(this.queryInput, {
        liveServer: true, server: this.getAttribute('href'),
        showAllSuggestions: true, // Stop Autocomplete searching in JSON again
        suggestionsThreshold: 3, // 3 letters required before fetching
        notFoundMessage: 'Nix gefunden. Sorry.',
        fixed: true,
        noCache: false, // Disable timestamp query param
        valueField: this.valueField, labelField: this.labelField,
        onSelectItem: (item) => this.selectItem(item)
      });
    });

    this.addEventListener("dialog-opener:finished", this);
  }

  handleEvent(e) {
    if (e.target == this.queryInput) {
      switch (e.type) {
        case "keydown":
          if (e.key == 'Enter') {
            this.autocomplete._dropElement?.querySelector('a')?.click();
            e.preventDefault();
          }
          break;
      }
    }
    switch (e.type) {
      case "dialog-opener:finished":
        e.preventDefault();
        break;
    }
  }

  fetchLabel(id) {

  }

  selectItem(item) {
    this.input.value = item[this.valueField];
  }

}

document.addEventListener('DOMContentLoaded', () => customElements.define('find-reference', FindReferenceElement));