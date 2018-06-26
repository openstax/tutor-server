# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( home.css
                                                  home.js
                                                  admin.css
                                                  admin.js
                                                  course_search.js
                                                  enroll.css
                                                  launch.css
                                                  payments/stub.css
                                                  payments/stub.js
                                                  customer_service.css
                                                  customer_service.js
                                                  research.css
                                                  research.js )

# initialize Assets
require 'tutor/assets'
Tutor::Assets.read_manifest if Rails.env.production?
