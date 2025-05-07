let switcherTimeout;

const checkForUpdate = async (current_url) => {
  if (switcherTimeout) {
    clearTimeout(switcherTimeout);
  }

  try {
    const res = await fetch(window.location.toString(), {
      headers: {"Accept": "application/json"}
    });
    const data = await res.json();
    if (data['url'] != current_url) {
      console.log("Reload!", data['url'], '!=', current_url);
      clearTimeout(switcherTimeout);
      reloadWithTurbolinks();
    }
  }
  catch(e) {
    console.log("fetch error, trying again later", e);
  }

  switcherTimeout = setTimeout(() => {
    checkForUpdate(current_url);
  }, 2000);
}