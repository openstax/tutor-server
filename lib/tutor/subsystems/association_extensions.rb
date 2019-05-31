module Tutor::SubSystems
  module AssociationExtensions
    extend ActiveSupport::Concern

    module ClassMethods
      def belongs_to(name, scope = nil, **options)
        set_subsystem_options(name, scope, options, true)
        super
      end

      def has_one(name, scope = nil, **options)
        set_subsystem_options(name, scope, options)
        super
      end

      def has_many(name, scope = nil, **options, &extension)
        set_subsystem_options(name, scope, options)
        super
      end

      private

      def set_subsystem_options(association_name, scope, options, is_belongs_to=false)
        # While rarely used, assocations can be created with a
        # scope to limit the record, `belongs_to :user, -> { where(id: 2) }, class_name: "MyUser"`
        # To cope with having either two or three arguments, Rails inspects the scope arguemnt.
        # If it's a Hash, then It's considered the options and the options argument is ignored.
        options = scope if scope.is_a?(Hash)
        subsystem_name = options.delete(:subsystem).to_s

        # Don't try to do subsystem stuff when the association is polymorphic and SS name unset
        return if subsystem_name.blank? && (options[:polymorphic] || options[:as])

        return if ['none','ignore'].include?(subsystem_name)

        # Find the string before the first ::, thats the subsystem module
        my_subsystem_name = self.name.to_s[/(\w+?)::/,1].underscore

        # Only extend subsystem's that are listed as valid.
        return unless Tutor::SubSystems.valid_name?(my_subsystem_name)

        # If the :subsystem wasn't specified, default to the current model's subsystem
        subsystem_name = my_subsystem_name if subsystem_name.blank?

        model_name = association_name.to_s.camelize.singularize

        if subsystem_name == 'entity'
          options[:class_name] ||= "::#{subsystem_name.camelize}::#{model_name}"
        else
          options[:class_name] ||= "::#{subsystem_name.camelize}::Models::#{model_name}"
        end

        if is_belongs_to
          options[:foreign_key] ||= "#{subsystem_name}_#{association_name.to_s.underscore}_id"
        else
          klass_name = self.name.demodulize.underscore
          options[:foreign_key] ||= "#{my_subsystem_name}_#{klass_name}_id"
        end
        options
      end
    end
  end
end
