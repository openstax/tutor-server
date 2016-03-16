module Settings
  module Db
    mattr_accessor :store
  end

  module Redis
    mattr_accessor :store
  end
end

Dir[File.join(__dir__, 'settings', '*.rb')].each{ |file| require file }
