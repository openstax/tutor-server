class AddReadingProcessingInstructionsToContentBooks < ActiveRecord::Migration
  HS_BOOK_UUIDS = [
    '334f8b61-30eb-4475-8e05-5260a4866b4b', # k12phys
    'd52e93f4-8653-4273-86da-3850001c0786', # apbio
    '93e2b09d-261c-4007-a987-0b3062fe154b'  # Physics (Demo)
  ]

  def change
    add_column :content_books, :reading_processing_instructions, :jsonb, null: false, default: '[]'

    reversible do |dir|
      dir.up do
        Content::Models::Book.where(uuid: HS_BOOK_UUIDS).each do |book|
          book.reading_processing_instructions = [
            { css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]' },
            { css: '.ost-exercise-choice', fragments: ["exercise", "optional_exercise"] },
            { css: ".os-exercise", fragments: ["exercise"] },
            { css: ".ost-video", fragments: ["video"] },
            { css: ".os-interactive, .ost-interactive", fragments: ["interactive"] },
            { css: ".worked-example", fragments: ["reading"], labels: ["worked-example"] },
            { css: ".ost-feature, .ost-assessed-feature", fragments: ["reading"] }
          ]
          book.save!
        end
      end
    end
  end
end
