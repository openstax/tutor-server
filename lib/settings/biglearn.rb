module Settings
  module Biglearn

    class << self

      def client
        # Changes to this setting in the middle of a test aren't always
        # reflected in the cached value, so reset it. Similar to calling
        # `reload!` on an activerecord in a spec, just doing it here because
        # it is easy to forget in specs.

        # Settings::Db.store.object('biglearn_client').try(:rewrite_cache) if Rails.env.test?
        Settings::Db.store.object('biglearn_client').try(:expire_cache) if Rails.env.test?

        Settings::Db.store.biglearn_client
      end

    end

  end
end
