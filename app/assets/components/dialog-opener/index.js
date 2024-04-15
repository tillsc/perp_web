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
    const link = this.querySelector("a");
    if (link) {
      link.addEventListener("click", (e) => {
        e.preventDefault();
        this.findOrCreateDialog(this.prepareLink(link.getAttribute("href")));
        this.enhanceIFrame().then(() => this.modal.show());
        return false;
      });
    }
  }

  prepareLink(src) {
    let s = new URL(src, document.location.href);
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
    return new Promise((resolve, reject) => {
      this.iframe.addEventListener("load", (e) => {
        let uri = new URL(this.iframe.contentWindow.location);
        if (uri.searchParams.has("closeDialog")) {
          this.modal.hide();
          uri.searchParams.delete("_layout");
          uri.searchParams.delete("closeDialog");
          uri.searchParams.set("dummy", Math.random(100000));
          window.location.href = uri.toString();
          reject()
        }
        else {
          this.moveElementsToOuterActions();
          this.iframe.display = 'unset';
          resolve();
        }
      });
    });
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
