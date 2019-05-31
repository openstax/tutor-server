module Settings
end

Dir[File.join(__dir__, 'settings', '*.rb')].each{ |file| require file }
