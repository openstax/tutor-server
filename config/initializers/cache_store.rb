# Be sure to restart your server when you modify this file.

Rails.application.config.cache_store = :redis_store,
                                       'redis://localhost:6379/0/cache',
                                       { expires_in: 90.minutes }
