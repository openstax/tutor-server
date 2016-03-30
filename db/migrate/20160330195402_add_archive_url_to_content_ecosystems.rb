class AddArchiveUrlToContentEcosystems < ActiveRecord::Migration
  ARCHIVE_STAGING_TUTOR_UUIDS = Set[
    '334f8b61-30eb-4475-8e05-5260a4866b4b', # k12phys
    'd52e93f4-8653-4273-86da-3850001c0786', # apbio
    '93e2b09d-261c-4007-a987-0b3062fe154b'  # Physics (Demo)
  ]

  def up
    add_column :content_ecosystems, :archive_url, :string
    Content::Models::Ecosystem.all.preload(:books).each do |ecosystem|
      archive_url = ARCHIVE_STAGING_TUTOR_UUIDS.include?(ecosystem.books.first.uuid) ?
                      'https://archive-staging-tutor.cnx.org/' : 'https://archive.cnx.org/'
      ecosystem.update_attribute :archive_url, archive_url
    end
    change_column_null :content_ecosystems, :archive_url, false
  end

  def down
    remove_column :content_ecosystems, :archive_url
  end
end
