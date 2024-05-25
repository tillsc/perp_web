//= require dragula
//= require moment
//= require moment/de.js

let scrollable = true;

const listener = (e) => {
  if (!scrollable) {
    e.preventDefault();
  }
}
document.addEventListener('touchmove', listener, { passive:false });

var drake = dragula([...document.querySelectorAll('.participants')], {
  copy: (el, source) => {
    return el.classList.contains('empty-lane') && source.classList.contains('remaining-participants');
  },
  remove: (el, source) => {
    return ;
  }
});

drake.on('drag', (_el, _source) => scrollable = false);

drake.on('drop', (el, target, source, _sibling) => {
  scrollable = true;
  if (el.classList.contains('empty-lane') && target.classList.contains('remaining-participants') && !source.classList.contains('remaining-participants')) {
    el.remove();
  }
});
drake.on('dragend', (_el, _source) => scrollable = true);

function select(el) {
  el?.classList?.add('selected');
}

function unselect(el) {
  el?.classList?.remove('selected');
}

function unselectAll() {
  unselect(document.querySelector('.item_list__item.selected'));
}

function selectNext(el) {
  const nextSibling = el?.nextElementSibling?.closest('.item_list__item:not(.empty-lane)');
  if (nextSibling) {
    unselect(el);
    select(nextSibling);
  }
  return nextSibling;
}

function selectPrevious(el) {
  const prevSibling = el?.previousElementSibling?.closest('.item_list__item:not(.empty-lane)');
  if (prevSibling) {
    unselect(el);
    select(prevSibling);
  }
  return prevSibling;
}

function moveToColumn(el, targetColumn) {
  if (targetColumn && el) {
    if (el.classList.contains('empty-lane')) {
      const clone = el.cloneNode(true);
      unselect(clone);
      targetColumn.appendChild(clone);
    }
    else {
      selectNext(el) || selectPrevious(el);
      unselect(el);
      if (targetColumn.getAttribute('data-column') === '0') {
        targetColumn.prepend(el);
        [...targetColumn.querySelectorAll('.item_list__item:not(.empty-lane)')]
          .sort((a, b) => parseInt(a.getAttribute('data-number')) > parseInt(b.getAttribute('data-number'))  ? -1 : 1)
          .forEach(node => targetColumn.prepend(node));

      }
      else {
        targetColumn.append(el);
      }
    }
  }
}

document.addEventListener('keyup', (e) => {
  const selected = document.querySelector('.item_list__item.selected');
  let raceColumn;
  if (e.key === 'Escape' || e.key === 'Delete' || e.key === 'Backspace') {
    raceColumn = 0;
  }
  else if (e.key === 'ArrowDown') {
    selectNext(selected);
  }
  else if (e.key === 'ArrowUp') {
    selectPrevious(selected);
  }
  else {
    raceColumn = (e.key.match(/^F(\d+)$/) || [])[1];
  }
  if (raceColumn !== undefined) {
    const target = document.querySelector(`[data-column="${raceColumn}"]`);
    moveToColumn(selected, target);
    if (e.target.classList.contains('filter')) {
      e.target.select();
    }
  }
});

document.addEventListener('click', (e) => {
  const selected = e.target.closest('.item_list__item');
  if (selected) {
    unselectAll();
    select(selected);
  }
});

const filterInput = document.querySelector('.filter');
const remainingContainer = document.querySelector('.remaining-participants');
let oldVal;
if (filterInput && remainingContainer) {
  filterInput.addEventListener('keyup', (e) => {
    if (oldVal !== filterInput.value) {
      unselectAll();
      if (filterInput.value !== '') {
        const found = remainingContainer.querySelector(`[data-number="${filterInput.value}"]`);
        select(found);
      }
      oldVal = filterInput.value;
    }
  });

}