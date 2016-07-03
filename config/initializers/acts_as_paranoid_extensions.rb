# https://github.com/goncalossilva/acts_as_paranoid/pull/115/files
module ActsAsParanoid
  module PreloaderAssociation
    def self.included(base)
      base.class_eval do
        def build_scope_with_deleted
          scope = build_scope_without_deleted
          scope = scope.with_deleted if options[:with_deleted] && klass.respond_to?(:with_deleted)
          scope
        end

        alias_method_chain :build_scope, :deleted
      end
    end
  end
end

ActiveRecord::Associations::Preloader::Association.send :include, ActsAsParanoid::PreloaderAssociation
