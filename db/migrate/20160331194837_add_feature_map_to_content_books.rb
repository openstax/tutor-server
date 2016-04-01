class AddFeatureMapToContentBooks < ActiveRecord::Migration
  HS_BOOK_UUIDS = [
    '334f8b61-30eb-4475-8e05-5260a4866b4b', # k12phys
    'd52e93f4-8653-4273-86da-3850001c0786', # apbio
    '93e2b09d-261c-4007-a987-0b3062fe154b'  # Physics (Demo)
  ]

  def change
    add_column :content_books, :split_reading_css, :string,
               array: true, null: false, default: []
    add_column :content_books, :split_video_css, :string,
               array: true, null: false, default: []
    add_column :content_books, :split_interactive_css, :string,
               array: true, null: false, default: []
    add_column :content_books, :split_required_exercise_css, :string,
               array: true, null: false, default: []
    add_column :content_books, :split_optional_exercise_css, :string,
               array: true, null: false, default: []
    add_column :content_books, :discard_css, :string,
               array: true, null: false, default: []

    reversible do |dir|
      dir.up do
        Content::Models::Book.where(uuid: HS_BOOK_UUIDS).each do |book|
          book.split_reading_css           = ['.ost-assessed-feature', '.ost-feature']
          book.split_video_css             = ['.ost-video']
          book.split_interactive_css       = ['.os-interactive', '.ost-interactive']
          book.split_required_exercise_css = ['.os-exercise']
          book.split_optional_exercise_css = ['.ost-exercise-choice']
          book.discard_css                 = ['.ost-reading-discard', '.os-teacher',
                                              '[data-type="glossary"]']
          book.save!
        end
      end
    end
  end
end
