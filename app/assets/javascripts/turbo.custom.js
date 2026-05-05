let scrollPosition,
  autoreloadRunning = false,
  autoscroll = false

let cancelAutoreload = function () {
  if (autoreloadRunning) {
    clearTimeout(autoreloadRunning)
  }
  autoreloadRunning = false
}

let autoreloadAfter = function (secs) {
  cancelAutoreload()
  autoreloadRunning = setTimeout(reloadPage, secs)
}

let reloadPage = function () {
  cancelAutoreload()
  autoscroll = true
  Turbo.visit(window.location.toString(), {action: 'replace'})
}


document.addEventListener('turbo:before-fetch-response', function (event) {
  if (!event.detail.fetchResponse.succeeded) {
    console.log("HTTP Error: ", event.detail.fetchResponse.status)
    event.preventDefault()
  }
})

document.addEventListener('turbo:before-render', function (event) {
  if (autoscroll) {
    autoscroll = false
    scrollPosition = [window.scrollX, window.scrollY]
  }
})

document.addEventListener('turbo:load', function () {
  if (scrollPosition) {
    window.scroll(scrollPosition[0], scrollPosition[1])
    setTimeout(() => {
      window.scroll(scrollPosition[0], scrollPosition[1])
      scrollPosition = null
    }, 50);
  }
});
