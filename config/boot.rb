ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

require 'rails/commands/server'

Rails::Server.class_exec do
  DEV_PORT = 3001

  alias :default_options_alias :default_options
  def default_options
    default_options_alias.merge!(Port: DEV_PORT)
  end

  # https://github.com/rack/rack/pull/1080
  # Rack/Rails patch to prevent puma from crashing on exit
  def write_pid
    ::File.open(options[:pid], ::File::CREAT | ::File::EXCL | ::File::WRONLY ){ |f| f.write("#{Process.pid}") }
    at_exit { ::FileUtils.rm_f(options[:pid]) }
  rescue Errno::EEXIST
    check_pid!
    retry
  end
end
