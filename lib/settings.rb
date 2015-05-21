module Settings
  mattr_accessor :store

  def self.timecop_time
    store.get('timecop:time')
  end

  def self.timecop_time=(value)
    store.set('timecop:time', value)
  end
end
