// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require popper
//= require bootstrap
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .

var scrollPosition,
  autoreloadRunning = false,
  autoscroll = false,
  status = 0

var cancelAutoreload = function () {
  if (autoreloadRunning) {
    clearTimeout(autoreloadRunning)
  }
  autoreloadRunning = false
}

var autoreloadAfter = function(secs) {
  cancelAutoreload()
  autoscroll = true
  autoreloadRunning = setTimeout(reloadWithTurbolinks, secs)
}

var reloadWithTurbolinks = function () {
  cancelAutoreload()
  Turbolinks.visit(window.location.toString(), { action: 'replace' })
}

document.addEventListener('turbolinks:request-end', function(event) {
  status = event.data.xhr.status
})

document.addEventListener('turbolinks:before-render', function(event) {
  if (status >= 399) {
    console.log("HTTP Error: ", status)
    event.preventDefault()
    event.stopImmediatePropagation()
    return false
  }
  else if (autoscroll) {
    autoscroll = false
    scrollPosition = [window.scrollX, window.scrollY]
  }
})

document.addEventListener('turbolinks:load', function () {
  if (scrollPosition) {
    window.scroll(scrollPosition[0], scrollPosition[1])
    setTimeout(() => {
      window.scroll(scrollPosition[0], scrollPosition[1])
      scrollPosition = null
    }, 50);
  }
})

jQuery(function () {
  jQuery('[data-toggle="tooltip"]').tooltip()
})
