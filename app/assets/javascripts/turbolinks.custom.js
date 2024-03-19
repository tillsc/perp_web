//= require turbolinks

let scrollPosition,
  autoreloadRunning = false,
  autoscroll = false,
  status = 0

let cancelAutoreload = function () {
  if (autoreloadRunning) {
    clearTimeout(autoreloadRunning)
  }
  autoreloadRunning = false
}

let autoreloadAfter = function (secs) {
  cancelAutoreload()
  autoreloadRunning = setTimeout(reloadWithTurbolinks, secs)
}

let reloadWithTurbolinks = function () {
  cancelAutoreload()
  autoscroll = true
  Turbolinks.visit(window.location.toString(), {action: 'replace'})
}

document.addEventListener('turbolinks:request-end', function (event) {
  status = event.data.xhr.status
})

document.addEventListener('turbolinks:before-render', function (event) {
  if (status >= 399) {
    console.log("HTTP Error: ", status)
    event.preventDefault()
    event.stopImmediatePropagation()
    return false
  } else if (autoscroll) {
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
});