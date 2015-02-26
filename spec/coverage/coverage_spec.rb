require 'rails_helper'

RSpec.describe 'Coverage' do
  TESTABLE_FOLDERS = [:app, :lib]

  IGNORED_PATHS = [
    'helpers/application_helper.rb', # Empty
    'lib/generators/secrets/secrets_generator.rb', # Add secrets.yml to repo and remove
    'lib/lev/delegator.rb', # Move to lev
    'lib/markdown_wrapper.rb' # Move to OSU
  ]

  it 'has specs for all rb files in app and lib' do
    rb_files = Dir[
      "{#{TESTABLE_FOLDERS.collect{ |tf| tf.to_s }.join(',')}}/**/*.rb"
    ]
    speccable_paths = rb_files.collect{ |rf| rf.gsub('app/', '') }

    spec_files = Dir["spec/**/*_spec.rb"]
    specced_paths = spec_files.collect{ |sf| sf.gsub('_spec', '')
                                               .gsub('spec/', '') }

    unspecced_paths = (speccable_paths - specced_paths) - IGNORED_PATHS

    unless unspecced_paths.empty?
      message = "The following files have no associated spec file:\n  #{
                  unspecced_paths.join("\n  ")
                }"

      fail message
    end
  end
end
