module Settings
  mattr_accessor :store

  def self.timecop_offset
    store.get('timecop:offset')
  end

  def self.timecop_offset=(value)
    store.set('timecop:offset', value)
  end
end
