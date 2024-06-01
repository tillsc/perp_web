//= require dragula
//= require moment
//= require moment/de.js

var selected = document.getElementById('participants');
var selectable = document.getElementById('available_participants');

var startedAt = null;
if (document.getElementById('started_at') && document.getElementById('started_at').getAttribute('datetime')) {
  startedAt = moment(document.getElementById('started_at').getAttribute('datetime'));

  var startTimer = document.createElement('span');
  document.getElementById('started_at').parentElement.appendChild(startTimer);
  setInterval(() => {
    startTimer.innerHTML = '&rightarrow; <span class="time">' + moment().subtract(startedAt).utc().format('HH:mm:ss').replace(/^00:/, '') + '</span>';
  }, 500);
}

var scrollable = true;

var listener = function(e) {
  if (!scrollable) {
    e.preventDefault();
  }
}
document.addEventListener('touchmove', listener, { passive:false });

var drake = dragula([selected, selectable], {
  moves: (el, _source, handle, _sibling) => {
    return !handle.classList.contains('quick-button') && el.closest('.participants_and_times');
  }
});

drake.on('drag', function(el, source) {
  scrollable = false;
});
drake.on('drop', function(el, source) {
  scrollable = true;
});
drake.on('dragend', function(el, source) {
  scrollable = true;
});

[...document.querySelectorAll("#participants .item_list__item, #available_participants .item_list__item")].forEach((item) => {
  if (item.classList.contains("sub-header")) {
    return;
  }
  item.querySelector('button.quick-button')?.remove();
  const quickButton = document.createElement('button');
  quickButton.classList.add('btn', 'btn-primary', 'quick-button', 'px-5');
  quickButton.innerText = '⤒';
  quickButton.addEventListener('click', (e) => {
    selected.append(item);
    e.preventDefault();
  });
  const teamNameElement = item.querySelector('.team_name');
  if (teamNameElement) {
    item.insertBefore(quickButton, teamNameElement)
  }
  else {
    item.append(quickButton);
  }
})

var times = document.getElementById('times');

if (times) {
  var editTimes = times.hasAttribute('data-edit-times');
  var duplicateTimes = times.hasAttribute('data-edit-times');

  function getTime(timeItem) {
    var timeElement = timeItem?.querySelector?.('.time');
    var timeInputElement = timeItem?.querySelector?.('input');
    return timeElement && moment(timeElement.innerText, "HH:mm:ss.SS");
  }

  function setTime(timeItem, time) {
    var timeElement = timeItem?.querySelector?.('.time');
    var relativeTimeElement = timeItem?.querySelector?.('.relative');
    var timeInputElement = timeItem?.querySelector?.('input');

    if (relativeTimeElement && startedAt) {
      //Force `now` date to be on the same day (for loading old measurement sets from past days)
      time.set('year', startedAt.year());
      time.set('month', startedAt.month());
      time.set('date', startedAt.date());
      var relative = time.clone().subtract(startedAt).utc();

      relativeTimeElement.innerHTML = '<span class="d-none d-sm-inline">&rightarrow; </span><span class="time">' + relative.format('HH:mm:ss.SS').replace(/^00:/, '') + '</span>';
    }

    if (timeElement) {
      timeElement.innerText = time.format('HH:mm:ss.SS');
    }
    if (timeInputElement) {
      timeInputElement.value = time.format('HH:mm:ss.SS');
    }
  }

  function increaseTime(timeItem, ms) {
    var time = getTime(timeItem);
    if (time) {
      var max = getTime(timeItem.nextSibling);
      var min = getTime(timeItem.previousSibling);
      time.add(ms, 'ms');
      if (max) {
        time = moment.min(time, moment(max, 'HH:mm:ss.SS'));
      }
      if (min) {
        time = moment.max(time, moment(min, 'HH:mm:ss.SS'));
      }
      setTime(timeItem, time);
    }
  }

  function deltaMs(event) {
    if (event.altKey) {
      return 1000;
    }
    else if (event.shiftKey) {
      return 100;
    }
    else {
      return 10;
    }
  }

  function clickPlus(event) {
    increaseTime(event.target.closest('.item_list__item'), deltaMs(event));
    event.cancelDefault;
  }

  function clickMinus(event) {
    increaseTime(event.target.closest('.item_list__item'), -deltaMs(event));
    event.cancelDefault;
  }

  function stopTime(time, after) {
    var now;
    if (!time) {
      now = moment();
    }
    else if (moment.isMoment(time)) {
      now = time.clone();
    }
    else if (time.includes("T")) {
      now = moment(time);
    }
    else {
      now = moment(time, "HH:mm:ss.SS");
    }

    var t = document.createElement('div');
    t.classList.add('item_list__item');
    t.innerHTML = '<span class="text-nowrap time"></span><small class="text-nowrap relative"></small><input type="hidden" name="times[]" value="' + time + '">';

    setTime(t, now);
    if (after) {
      after.insertAdjacentElement("afterend", t);
    }
    else {
      times.appendChild(t);
    }

    var relativeElement = t.querySelector('.relative');
    if (editTimes && relativeElement) {

      var plusMinus = document.createElement('span');
      plusMinus.classList.add('btn-group');
      relativeElement.insertAdjacentElement("beforebegin", plusMinus);

      var plusBtn = document.createElement('a');
      plusBtn.classList.add('btn', 'btn-secondary', 'btn-sm');
      plusBtn.innerHTML = '+';
      plusBtn.addEventListener("click", clickPlus);
      plusMinus.appendChild(plusBtn);

      var minusBtn = document.createElement('a');
      minusBtn.classList.add('btn', 'btn-secondary', 'btn-sm');
      minusBtn.innerHTML = '-';
      minusBtn.addEventListener("click", clickMinus);
      plusMinus.appendChild(minusBtn);
    }

    if (duplicateTimes && relativeElement) {
      var duplicateBtn = document.createElement('a');
      duplicateBtn.classList.add('btn', 'btn-secondary', 'btn-sm');
      duplicateBtn.innerHTML = '⎘';
      duplicateBtn.addEventListener("click", function() {
        stopTime(getTime(t), t);
      });
      relativeElement.insertAdjacentElement("beforebegin", duplicateBtn);
    }

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
    if (existing[i].closest('.item_list__item')) {
      // This might happen when using browser back.
      // Elements where dried out so they had to be re-initialized. But they can be thrown away now...
      existing[i].closest('.item_list__item').remove();
    }
    else {
      existing[i].remove();
    }
  }

  document.getElementById('stop_time').addEventListener("click", function (e) {
    stopTime();
    e.preventDefault();
    return false;
  });
  document.addEventListener("keydown", function (e) {
    if (!e.handled && e.key == 'Enter') {
      stopTime();

      e.handled = true;
      return true;
    }
  });

}