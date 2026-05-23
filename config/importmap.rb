# Pin npm packages by running ./bin/importmap

pin "app"

# Rails stuff
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actiontext", to: "actiontext.esm.js"

pin "bootstrap5-autocomplete" # @1.1.25

pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3

pin "tesseract.js", to: "https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.esm.min.js"

pin "pagedjs", to: "pagedjs.js"

pin "fullcalendar" # @6.1.20
pin "@fullcalendar/core/locales/de", to: "@fullcalendar--core--locales--de.js" # @6.1.20
