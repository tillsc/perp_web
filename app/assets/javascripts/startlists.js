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
