class ConditionalDisplay extends HTMLElement {

  static observedAttributes = ["selector", "value"];
  static mode = 'show';

  constructor() {
    super();
    this.values = [];
  }

  connectedCallback() {
    document.addEventListener('change', this)
  }

  attributeChangedCallback(name, oldValue, newValue) {
    switch (name) {
      case "selector":
        this.input = !!newValue && document.querySelector(newValue);
        if (!this.input && newValue) {
          console.log(`<conditional-display>: Selector ${newValue} was given but no element matched!`);
        }
        break;

      case "value":
        this.values = !!newValue && newValue.split(",") || [];
        break;
    }

    requestAnimationFrame(() => {
      this.handleChange();
    });
  }

  handleEvent(event) {
    switch (event.type) {
      case "change":
        this.handleChange();
        break;
    }
  }

  handleChange() {
    if (!this.input) {
      return;
    }
    let currentValue;
    if (this.input.type === 'checkbox' || this.input.type === 'radio') {
      currentValue = this.input.checked ? this.input.value : null;
    } else {
      currentValue = this.input.value;
    }

    let invert = false;
    const isActive = this.values.includes(currentValue ? currentValue.toString() : "undefined");
    switch (this.constructor.mode) {
      case "disable":
        invert = true;
        // intentionally falls through to "enable"
      case "enable":
        [...this.querySelectorAll('input, select, textarea')].forEach((i) => {
          i.disabled = isActive == invert;
        })
        break;
      case "hide":
        invert = true;
        // intentionally falls through to default ("show")
      default:
        if (isActive != invert) {
          this.style.display = null;
        }
        else {
          this.style.display = 'none';
        }
        break;
    }
  }
}

customElements.define('show-if',  ConditionalDisplay);

customElements.define('hidden-if',  class extends ConditionalDisplay {
  static mode = 'hide';
});

customElements.define('enabled-if',  class extends ConditionalDisplay {
  static mode = 'enable';
});

customElements.define('disabled-if',  class extends ConditionalDisplay {
  static mode = 'disable';
});
