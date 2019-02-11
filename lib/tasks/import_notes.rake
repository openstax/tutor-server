# Fix users enrolled multiple times in the same course

desc "Import notes from hypothesis"
task :import_notes, [:path, :run_mode] => :environment do |t, args|
  real_run = args[:run_mode] == 'real'

  ActiveRecord::Base.transaction do
    CSV.foreach(args[:path]) do |research_id, elementId, module_id, contents, created_at, updated_at |
      role = Entity::Role.where(research_identifier: research_id).first

      module_uuid, version = module_id.split('@')
#      puts "#{module_uuid} => #{version}"
      page = Content::Models::Page.where("uuid=?",
                                         module_uuid
                                        ).first
      if role.blank? || page.blank?
#        STDERR.puts "#{research_id} #{module_uuid} skipped"
        next
      end

      note = Notes::Models::Note.new(
        role: role,
        page: page,
        anchor: elementId,
        contents: contents
      )
      note.created_at = DateTime.parse(created_at)
      note.updated_at = DateTime.parse(updated_at)
      if real_run
        note.save!
      else
        raise note.errors unless note.valid?
        p note
      end
    end
  end
end
