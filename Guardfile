guard :bundler do
  # If the Gemfile changed, rerun bundle install
  watch('Gemfile')
end

guard :rspec, cmd: 'bin/spring rspec' do
  # If a spec helper, fixture, support or mock changed, run all specs
  watch(%r{^spec/(?:(?:.+_helper|support/.+|mocks/.+)\.rb|fixtures/.+)$}) { 'spec' }

  # If a spec changed, run that spec
  watch(%r{^spec/.+_spec\.rb$})

  # If a lib changed, run that lib's specs
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }

  # If the routes changed, run all routing and request specs
  watch('config/routes.rb') { [ 'spec/routing', 'spec/requests' ] }

  # If the ApplicationController changed, run all controller and request specs
  watch('app/controllers/application_controller.rb') { [ 'spec/controllers', 'spec/requests' ] }

  # If the ApiController changed, run all controller and request specs for that API version
  watch(%r{^app/controllers/api/(.+?)/api_controller\.rb$}) do |m|
    [ "spec/controllers/api/#{m[1]}", "spec/requests/api/#{m[1]} "]
  end

  # If a controller changed, run the corresponding controller and request specs
  watch(%r{^app/controllers/(.+)_controller\.rb$}) do |m|
    [ "spec/controllers/#{m[1]}_controller_spec.rb" ] +
    Dir["spec/requests/#{m[1].chomp('s')}*_spec.rb"]
  end

  # If the ApplicationRecord changed, run all model, controller and request specs
  watch('app/models/application_record.rb') do
    [ 'spec/models', 'spec/controllers', 'spec/requests' ]
  end

  # If a model changed, run that model's specs and associated controller and request specs
  watch(%r{^app/models/(.+)\.rb$}) do |m|
    [ "spec/models/#{m[1]}_spec.rb", "spec/controllers/#{m[1]}s_controller_spec.rb" ] +
    Dir["spec/requests/#{m[1]}*_spec.rb"]
  end

  # If a view changed, run that view's specs and associated request specs
  watch(%r{^app/views/(.*)(/[^/]*\.erb|haml|slim)$}) do |m|
    [ "spec/views/#{m[1]}#{m[2]}_spec.rb" ] + Dir["spec/requests/#{m[1].chomp('s')}*_spec.rb"]
  end

  # If the ApplicationJob changed, run all job specs
  watch('app/jobs/application_job.rb') { 'spec/jobs' }

  # If another file in app/ changed, run that file's specs and all feature and system specs
  watch(%r{^app/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
end
