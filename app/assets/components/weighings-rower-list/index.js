class WeighingsRowerList extends HTMLElement {

  connectedCallback() {
    [...this.querySelectorAll('.weighings-rower-list-generated')].forEach((e) => e.remove());
    const searchBox = document.createElement('label');
    searchBox.classList.add('col-search', 'weighings-rower-list-generated');
    searchBox.innerText = 'Suchen: ';

    this.searchInput = document.createElement('input');
    this.searchInput.type = 'search';
    this.searchInput.classList.add('form-control');
    this.searchInput.addEventListener('keyup', this.debounce(this.filterList, 100));
    searchBox.append(this.searchInput);

    this.prepend(searchBox);
  }

  debounce(func, timeout = 300) {
    return (...args) => {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = setTimeout(() => func.apply(this, args), timeout);
    };
  }

  filterList() {
    const searchFor = this.searchInput.value;

    if (searchFor.trim() != '') {
      const allWordRowIds = searchFor.split(' ').map((word) => {
        let wordRowIds = [];

        const query = document.evaluate(`.//*[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), "${word.toLowerCase()}")]`, this, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE);
        for (let i = 0, length = query.snapshotLength; i < length; ++i) {
          const element = query.snapshotItem(i).closest("[data-row-id]");
          let rowId = element?.getAttribute('data-row-id');
          if (toString(rowId) != '') {
            wordRowIds.push(rowId)
          }
        }
        return wordRowIds;
      });
      [...this.querySelectorAll("[data-row-id]")].forEach((e) => e.style.display = 'none');
      allWordRowIds
        .reduce((a, b) => a.filter(value => b.includes(value))) // Intersect all rows (logical AND)
        .forEach(rowId => {
          [...this.querySelectorAll("[data-row-id=" + rowId + "]")].forEach((e) => e.style.display = '');
        });
    }
    else {
      [...this.querySelectorAll("[data-row-id]")].forEach((e) => e.style.display = '');
    }
  }
}

customElements.define('weighings-rower-list', WeighingsRowerList);