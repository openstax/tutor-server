# `ClassSize` records in Salesforce are so old school.  This script updates Tutor's
# links to these records to instead point to the shiny new `OsAncillary` records.
#
# Do a dry run:
#
# $> rake migrate_salesforce_class_sizes
#
# Do a real run that saves Tutor's AttachedRecords:
#
# $> rake migrate_salesforce_class_sizes['real']

desc "Migrates from old ClassSize Salesforce records to OsAncillaries"
task :migrate_salesforce_class_sizes, [:run_mode] => :environment do |t, args|
  args ||= {}

  cs_class = OpenStax::Salesforce::Remote::ClassSize
  osa_class = OpenStax::Salesforce::Remote::OsAncillary

  Salesforce::Models::AttachedRecord.transaction do
    attached_records = Salesforce::Models::AttachedRecord.preload(:salesforce_objects)

    attached_records.each do |attached_record|
      next if attached_record.salesforce_class_name != cs_class.name

      old_id = attached_record.salesforce_id
      new_id = attached_record.salesforce_object.os_ancillary_id

      print "In AR #{attached_record.id}, ClassSize #{old_id} "

      if new_id.nil?
        puts "does not point to a new OsAncillary!"
        next
      end

      attached_record.salesforce_class_name = osa_class.name
      attached_record.salesforce_id = new_id

      print "has changed to OsAncillary #{new_id} "

      if real_run?(args)
        attached_record.save!
        attached_record.salesforce_object = nil # preloaded value invalid
        puts "(saved!)"
      else
        puts "(dry run)"
      end
    end
  end
end

private

def dry_run?(args)
  args[:run_mode] != 'real'
end

def real_run?(args)
  args[:run_mode] == 'real'
end
