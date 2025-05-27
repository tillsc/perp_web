# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.precompile += %w( measurements.js measurements.css
  startlists.js startlists.css internal.js internal.css switcher.js components app.js
  bootstrap5-autocomplete.js @rails--ujs.js)
