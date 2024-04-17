class DialogOpener extends HTMLElement {

  dialogContent = (closeText) => `
<div class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-body"></div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Schließen</button>
      </div>

    </div>
  </div>
</div>`;

  connectedCallback() {
    this.init();
  }

  init() {
    const link = this.querySelector("a");
    if (link) {
      if (this.hasAttribute('local-reload') && !this.id) {
        console.log("<dialog-opener> Problem: Element has local-reload attribute but no id!", this);
      }

      link.addEventListener("click", (e) => {
        e.preventDefault();
        this.findOrCreateDialog(this.prepareLink(link.getAttribute("href")));
        this.enhanceIFrame().then(() => this.modal.show());
        return false;
      });
    }
  }

  prepareLink(src) {
    const s = new URL(src, document.location.href);

    const defaultValues = [...this.querySelectorAll('input')].map((input) => {
      if (input.type !== 'hidden' && input.value) {
        return input.value;
      }
      else {
        return null;
      }
    }).filter(item => item !== null);

    if (defaultValues !== []) {
      s.searchParams.set("default", defaultValues.join(","));
    }

    s.searchParams.set("_layout", false);
    return s.toString();
  }

  findOrCreateDialog(src) {
    this.dialog = document.querySelector("div.dialog-opener");
    if (!this.dialog) {
      this.dialog = document.createElement("div");
      this.dialog.classList.add("dialog-opener");
      document.body.appendChild(this.dialog);
    }
    this.dialog.innerHTML = this.dialogContent(this.getAttribute('close') || 'Close');
    this.dialog.querySelector(".modal-body").innerHTML = `<iframe src="${src}" height="550px"></iframe>`;
    this.modal = new bootstrap.Modal(this.dialog.querySelector(".modal"));
  }

   enhanceIFrame() {
    this.iframe = this.dialog.querySelector("iframe");
    return new Promise((resolve, _reject) => {
      this.iframe.addEventListener("load", (e) => {
        this.iFrameLoad(e).then(resolve);
      });
    });
  }

  async iFrameLoad(e) {
    let uri = new URL(this.iframe.contentWindow.location);
    if (uri.searchParams.has("dialog_finished_with")) {
      this.modal.hide();
      uri.searchParams.delete("_layout");
      uri.searchParams.set("dummy", Math.random(100000));
      const localReloadWorked = await this.tryLocalReload(uri);
      if (!localReloadWorked) {
          window.location.href = uri.toString();
      }
    }
    else {
      this.moveElementsToOuterActions();
      this.iframe.display = 'unset';
    }
  }

  async tryLocalReload(newUri) {
    let mustReloadWindow = true;
    const currentUri = new URL(window.location.href);
    if (currentUri.hostname !== newUri.hostname || currentUri.pathname !== newUri.pathname || currentUri.protocol !== newUri.protocol) {
      console.log(`<dialog-opener> Warning: local-reload got different base uri (${newUri.toString()}) then window has (${currentUri.toString()}). This might lead to problems, but we'll try it anyway.`);
    }

    if (this.hasAttribute('local-reload') && this.id) {
      newUri.searchParams.set('local_reload', this.id);
      const res = await fetch(newUri);
      if (res.ok) {
        const html = await res.text();
        const newDocument = (new DOMParser()).parseFromString(html, 'text/html');
        const fragment = newDocument.getElementById(this.id);
        if (fragment) {
          this.replaceChildren(...fragment.children);
          this.init();
          return true;
        }
        else {
          console.log(`<dialog-opener> Problem: Element with id "${this.id}" not found in new serverside fragment`, html);
        }
      }
    }

    return false;
  }

  moveElementsToOuterActions() {
    if (!this.getAttribute("move-out")) {
      return;
    }
    let iframeDoc = this.iframe.contentWindow.document;
    if (iframeDoc) {
      let buttonContainer = this.dialog.querySelector('dialog-opener-buttons');
      if (!buttonContainer) {
        buttonContainer = document.createElement('dialog-opener-buttons');
        this.dialog.querySelector('.modal-footer').prepend(buttonContainer);
      } else {
        buttonContainer.innerHTML = '';
      }

      let selector = this.getAttribute("move-out");
      if (selector == "submit") {
        selector = "button[type=submit], input[type=submit]"
      }
      else if (selector == "primary") {
        selector = "button[type=submit].btn-primary, input[type=submit].btn-primary"
      }
      let elements =  iframeDoc.querySelectorAll(selector);
      for (let i = 0; i < elements.length; i++) {
        let btn = elements[i];
        let outerBtn = document.createElement(btn.tagName);
        outerBtn.setAttribute("class", btn.getAttribute('class'));
        outerBtn.setAttribute("type", btn.getAttribute('type'));
        outerBtn.setAttribute("value", btn.getAttribute('value'));
        outerBtn.innerHTML = btn.innerHTML;
        outerBtn.addEventListener("click", () => {
          this.iframe.display = "none";
          btn.click();
        });
        buttonContainer.append(outerBtn);
        btn.style.visibility = "hidden";
        btn.style.display = "none";
      }
    }
  }
}

document.addEventListener('DOMContentLoaded', () => customElements.define('dialog-opener', DialogOpener));
