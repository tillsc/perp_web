//= require dragula
//= require moment
//= require moment/de.js

var selected = document.getElementById('participants');
var selectable = document.getElementById('available_participants');

var startedAt;
if (document.getElementById('started_at') && document.getElementById('started_at').getAttribute('datetime')) {
  startedAt = moment(document.getElementById('started_at').getAttribute('datetime'));

  var startTimer = document.createElement('time');
  document.getElementById('started_at').parentElement.appendChild(startTimer);
  setInterval(() => {
    startTimer.innerHTML = " (" + moment().subtract(startedAt).utc().format('HH:mm:ss').replace(/^00:/, '') + ")";
  }, 500);
}

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

[...document.querySelectorAll("#participants .item_list__item, #available_participants .item_list__item")].forEach((item) => {
  const quickButton = document.createElement('button');
  quickButton.classList.add('btn', 'btn-primary', 'quick-button');
  quickButton.innerText = '⤒';
  quickButton.addEventListener('click', (e) => {
    selected.append(item);
    e.preventDefault();
  });
  item.append(quickButton);
})

var times = document.getElementById('times')

if (times) {

  function stopTime(time) {
    var now, relative;
    if (!time) {
      now = moment();
    }
    else if (time.includes("T")) {
      now = moment(time);
    }
    else {
      now = moment(time, "HH:mm:ss.SS");
    }
    time = now.format('HH:mm:ss.SS')

    if (startedAt) {
      relative = now.subtract(startedAt).utc().format('HH:mm:ss.SS').replace(/^00:/, '');
    }

    var t = document.createElement('div');
    t.classList.add('item_list__item', 'd-flex', 'gap-2');
    t.innerHTML = '<div><span class="text-nowrap time">' + time + '</span>' + (relative ? ' (<span class="text-nowrap time">' + relative + '</span>)' : '') + '<input type="hidden" name="times[]" value="' + time + '"></div>';
    times.appendChild(t);

    var delBtn = document.createElement('a');
    delBtn.classList.add('btn', 'btn-danger', 'btn-sm');
    delBtn.innerHTML = 'X';
    delBtn.addEventListener("click", function () {
      t.remove();
    });
    t.appendChild(delBtn);

    return t;
  }

  var existing = times.querySelectorAll('[type=hidden]');
  for (var i = 0; i < existing.length; i++) {
    if (existing[i].value != '') {
      stopTime(existing[i].value);
    }
    existing[i].remove();
  }

  document.getElementById('stop_time').addEventListener("click", function (e) {
    stopTime();
    e.preventDefault();
    return false;
  })
  document.addEventListener("keydown", function (e) {
    if (!e.handled && e.key == 'Enter') {
      stopTime();

      e.handled = true;
      return true;
    }
  })

}