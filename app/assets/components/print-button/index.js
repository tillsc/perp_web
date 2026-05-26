class PrintButtonElement extends HTMLElement {
  connectedCallback() {
    this.addEventListener('click', this);
  }

  disconnectedCallback() {
    this.removeEventListener('click', this);
  }

  handleEvent(e) {
    if (e.type === 'click') this.#activate();
  }

  #activate() {
    const cssUrl = this.getAttribute('paged-css-url');
    const win = window.open('', '_blank');
    const doc = win.document;

    // Copy importmap so import('pagedjs') resolves in the new window
    const importmapSrc = document.querySelector('script[type="importmap"]');
    if (importmapSrc) {
      const importmap = doc.createElement('script');
      importmap.type = 'importmap';
      importmap.textContent = importmapSrc.textContent;
      doc.head.appendChild(importmap);
    }

    // Carry over all stylesheets from the current page
    document.querySelectorAll('link[rel="stylesheet"]').forEach(link => {
      const el = doc.createElement('link');
      el.rel = 'stylesheet';
      el.href = link.href;
      doc.head.appendChild(el);
    });

    if (cssUrl) {
      const el = doc.createElement('link');
      el.rel = 'stylesheet';
      el.href = cssUrl;
      doc.head.appendChild(el);
    }

    const configScript = doc.createElement('script');
    configScript.textContent = 'window.PagedConfig = { auto: false };';
    doc.head.appendChild(configScript);

    const moduleScript = doc.createElement('script');
    moduleScript.type = 'module';
    moduleScript.textContent = `
      import 'pagedjs';
      class ReadyHandler extends window.Paged.Handler {
        afterRendered() { window.print(); }
      }
      window.Paged.registerHandlers(ReadyHandler);
      window.PagedPolyfill.preview();
    `;
    doc.head.appendChild(moduleScript);

    // Clone body content, stripping nav/footer/no-print/scripts
    const bodyClone = document.body.cloneNode(true);
    bodyClone.querySelectorAll('nav, footer, .no-print, script').forEach(el => el.remove());
    // PagedJS activates position:running() only from the page where the element appears in flow.
    // Prepend running elements so they're active from page 1, not just the last page.
    bodyClone.querySelectorAll('.running-print-footer').forEach(el => bodyClone.prepend(el));
    doc.body.innerHTML = bodyClone.innerHTML;
  }
}

document.addEventListener('DOMContentLoaded', () => customElements.define('print-button', PrintButtonElement));
