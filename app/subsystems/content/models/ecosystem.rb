module Content
  module Models
    class Ecosystem < Tutor::SubSystems::BaseModel

      wrapped_by ::Content::Strategies::Direct::Ecosystem

      has_many :course_ecosystems, dependent: :destroy, subsystem: :course_content
      has_many :courses, through: :course_ecosystems, subsystem: :course_profile

      has_many :task_plans, subsystem: :tasks, dependent: :destroy

      has_many :books, dependent: :destroy, inverse_of: :ecosystem
      has_many :chapters, through: :books
      has_many :pages, through: :chapters
      has_many :exercises, through: :pages

      has_many :pools, dependent: :destroy, inverse_of: :ecosystem

      has_many :tags, dependent: :destroy, inverse_of: :ecosystem

      has_many :to_maps, class_name: '::Content::Models::Map',
                         foreign_key: :content_from_ecosystem_id,
                         dependent: :destroy,
                         inverse_of: :from_ecosystem
      has_many :from_maps, class_name: '::Content::Models::Map',
                           foreign_key: :content_to_ecosystem_id,
                           dependent: :destroy,
                           inverse_of: :to_ecosystem

      validates :title, presence: true

      default_scope -> { order(created_at: :desc) }

      def deletable?
        courses.empty?
      end

      def manifest_hash
        {
          title: title,
          books: books.map(&:manifest_hash)
        }
      end

    end
  end
end
