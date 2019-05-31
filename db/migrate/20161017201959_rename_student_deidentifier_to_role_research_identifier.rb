class RenameStudentDeidentifierToRoleResearchIdentifier < ActiveRecord::Migration[4.2]
  def up
    add_column :entity_roles, :research_identifier, :string

    print "\nMigrating #{Entity::Role.count} roles"

    Entity::Role.preload(:student).find_each do |role|
      if role.student.present?
        role.research_identifier = role.student.try!(:deidentifier)
      else
        role.send :generate_unique_token, :research_identifier, mode: :hex, length: 4
      end

      role.save(validate: false)

      print '.'
    end

    task_plan_count = Tasks::Models::TaskPlan.unscoped.where(type: 'external').count
    print "\n\nMigrating #{task_plan_count} external task plans"

    Tasks::Models::TaskPlan.unscoped.where(type: 'external').find_each do |task_plan|
      url = task_plan.settings['external_url']
      task_plan.settings['external_url'] = url.gsub('{{deidentifier}}', '{{research_identifier}}')
      task_plan.save(validate: false)

      print '.'
    end

    print "\n\n"

    add_index :entity_roles, :research_identifier, unique: true
    remove_column :course_membership_students, :deidentifier
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
