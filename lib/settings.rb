module Settings
  mattr_accessor :store
  class << self

    def timecop_offset
      store.get('timecop:offset')
    end

    def timecop_offset=(value)
      store.set('timecop:offset', value)
    end

  end
end

require_relative 'settings/notifications'
