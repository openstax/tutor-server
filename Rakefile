# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# Initialize config/secrets.yml if needed
file 'config/secrets.yml' => 'config/secrets.yml.example' do |task|
  cp task.prerequisites.first, task.name
end

Rake::Task['config/secrets.yml'].invoke

begin
  require 'rspec/core/rake_task'

  namespace :spec do
    desc "Run fast examples"
    RSpec::Core::RakeTask.new(:fast) do |t|
      t.rspec_opts = %w[--tag ~speed:slow]
    end

    desc "Run slow examples"
    RSpec::Core::RakeTask.new(:slow) do |t|
      t.rspec_opts = %w[--tag speed:slow]
    end
  end
rescue LoadError
end

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

if Rails.env.development?
  Dir.glob('lib/sprint/*.rake').each { |r| load r }
end
