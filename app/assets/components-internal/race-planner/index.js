class RacePlannerElement extends HTMLElement {

  constructor() {
    super();
    this.Loaders = {
      core: import('https://cdn.skypack.dev/@fullcalendar/core@6.1.17'),
      timegrid: import('https://cdn.skypack.dev/@fullcalendar/timegrid@6.1.17'),
      list: import('https://cdn.skypack.dev/@fullcalendar/list@6.1.17'),
      deLocale: import('https://cdn.skypack.dev/@fullcalendar/core/locales/de'),
    }
  }

  async connectedCallback() {
    const calendar = new (await this.Loaders.core).Calendar(this, {
      plugins: [(await this.Loaders.timegrid).default, (await this.Loaders.list).default],
      locale: (await this.Loaders.deLocale).default,
      themeSystem: 'bootstrap5',
      initialView: 'timeGrid',
      visibleRange: {
        start: this.getAttribute('from') || Date.now(),
        end: this.getAttribute('to') || Date.now()
      },
      slotDuration: '00:10:00',
      headerToolbar: {
        right: 'prev,timeGrid,timeGridDay,listWeek,next'
      },
      slotMinTime: '7:00:00',
      slotMaxTime: '20:00:00',
      allDaySlot: false,
      //slotEventOverlap: false,
      events: this.loadEvents()
    });
    calendar.render();
    console.log(this.loadEvents());
  }

  loadEvents() {
    return [...document.querySelectorAll('table.table tbody tr')].map(row => {
      return {
        title: row.getAttribute('data-label'),
        start: row.getAttribute('data-start-time'),
        end: row.getAttribute('data-end-time')
      }
    })
  }
};

customElements.define('race-planner-element', RacePlannerElement);
