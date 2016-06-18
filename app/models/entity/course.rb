class Entity::Course < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :course_profile, dependent: :destroy, autosave: true

  has_many :periods, subsystem: :course_membership, dependent: :destroy
  has_many :periods_with_deleted, -> { with_deleted }, subsystem: :course_membership,
           dependent: :destroy, class_name: 'CourseMembership::Models::Period'

  has_many :teachers, subsystem: :course_membership, dependent: :destroy
  has_many :students, subsystem: :course_membership, dependent: :destroy

  has_many :excluded_exercises, subsystem: :course_content, dependent: :destroy

  has_many :course_ecosystems, subsystem: :course_content, dependent: :destroy
  has_many :ecosystems, through: :course_ecosystems, subsystem: :content

  has_many :course_assistants, subsystem: :tasks, dependent: :destroy

  has_many :taskings, through: :periods, subsystem: :tasks

  delegate :name, :appearance_code, :is_concept_coach, :offering, :teach_token,
           :time_zone, :default_open_time, :default_due_time,
           :name=, :default_open_time=, :default_due_time=, :is_college,
           to: :profile

  def deletable?
    periods.empty? && teachers.empty? && students.empty?
  end
end


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
