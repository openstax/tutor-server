# https://github.com/zdennis/activerecord-import/issues/162
module ActiveRecord
  class Base
    def self.import!(*args)
      result = import(*args)
      failed_instances = result.failed_instances
      raise(RecordInvalid.new(failed_instances.first)) if failed_instances.any?
      result
    end
  end
end
