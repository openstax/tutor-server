source 'https://rubygems.org'

gem 'rails', '4.2.0.beta1'

gem 'sass-rails', '~> 5.0.0.beta1'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'bootstrap-sass', '~> 3.2.0'
gem 'autoprefixer-rails'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'jquery-rails'
gem 'turbolinks'

gem 'rails-html-sanitizer', '~> 1.0'

gem 'squeel'
gem 'lev'

group :development, :test do
  gem 'thin'
  gem 'sqlite3'

  gem 'byebug'                           # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'web-console', '~> 2.0.0.beta2'    # Access an IRB console on exceptions page and /console in development
  gem 'spring'                           # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'quiet_assets'

  gem 'rails-erd'
  gem 'cheat'
  gem 'brakeman'

  gem 'timecop'

  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'faker'

  gem 'nifty-generators'
  gem 'coffee-rails-source-maps'
end

group :production do
  gem 'unicorn'
end

gem "codeclimate-test-reporter", group: :test, require: nil
gem 'coveralls', group: :test, require: false