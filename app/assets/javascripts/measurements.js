//= require dragula

var selected = document.getElementById('participants')
var selectable = document.getElementById('available_participants')

var scrollable = true;

var listener = function(e) {
  if (! scrollable) {
    e.preventDefault();
  }
}
document.addEventListener('touchmove', listener, { passive:false });

dragula([selected, selectable]).on('drag', function(el, source) {
  scrollable = false;
}).on('drop', function(el, source) {
  scrollable = true;
}).on('dragend', function(el, source) {
  scrollable = true;
  // your logic on dragend
});


var times = document.getElementById('times')

document.addEventListener("keydown", function(e) {
  if (!e.handled && e.key == 'Enter') {
    var d = new Date();
    var t = document.createElement('div')
    t.classList.add('item_list__item')
    t.innerHTML = '<span class="text-nowrap time">' + d.getHours() + ':' +
      String(d.getMinutes()).padStart(2, '0')  + ':' +
      String(d.getSeconds()).padStart(2, '0') + '.' +
        String(Math.round(d.getMilliseconds() / 10)).padStart(2, '0') +
        '</span>'
    times.appendChild(t)

    var delBtn =  document.createElement('a')
    delBtn.classList.add('btn')
    delBtn.classList.add('btn-danger')
    delBtn.classList.add('btn-sm')
    delBtn.classList.add('float-right')
    delBtn.innerHTML = 'X'
    delBtn.addEventListener("click", function() {
      t.remove();
    });

    t.appendChild(delBtn)

    e.handled = true;
    return true;
  }
})