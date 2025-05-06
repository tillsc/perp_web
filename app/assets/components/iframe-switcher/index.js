class IFrameSwitcher extends HTMLElement {

  constructor() {
    super();
    this.actioncableFuture = import('@rails/actioncable');
  }

  connectedCallback() {
    this.init();
  }
  async init() {
    this.links = [...this.querySelectorAll('a')].reduce((acc, cur) => {
      acc[cur.textContent] = cur.getAttribute('href');
      return acc;
    }, {});
    console.log("found links", this.links)

    const element = this;
    const actioncable = await this.actioncableFuture;
    this.consumer = actioncable.createConsumer();
    this.consumer.subscriptions.create({ channel: 'TvSwitcherChannel' }, {
      connected() {

      },
      disconnected() {
      },
      received(data) {
        console.log("[iframe-switcher] Switching to:", data);
        element.switchTo(data);
      }
    });
  }

  switchTo(key) {
    const link = this.links[key];
    this.innerHTML = ('Switching to ' + link);
  }

}

document.addEventListener('DOMContentLoaded', () => customElements.define('iframe-switcher', IFrameSwitcher));
