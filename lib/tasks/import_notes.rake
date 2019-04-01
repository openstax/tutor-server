desc 'Import notes from hypothesis'
task :import_notes, [:path, :run_mode] => :environment do |_, args|
  real_run = args[:run_mode] == 'real'
  ActiveRecord::Base.transaction do
    CSV.foreach(args[:path]) do |row|
      research_id, element_id, module_uuids, contents, annotation, created_at, updated_at = row
      role = Entity::Role.find_by(research_identifier: research_id)
      page = Content::Models::Page.where(
        uuid: module_uuids.split(':').map { |muuid| muuid.split('@').first }
      ).order('created_at desc').first
      if role.blank? || page.blank?
        STDERR.puts "#{research_id} #{module_uuids} skipped"
        next
      end
      note = Content::Models::Note.new(
        role: role, page: page, annotation: annotation,
        anchor: element_id, contents: contents
      )
      note.created_at = DateTime.parse(created_at)
      note.updated_at = DateTime.parse(updated_at)
      if real_run
        note.save!
      else
        raise note.errors unless note.valid?
      end
    end
  end
end
