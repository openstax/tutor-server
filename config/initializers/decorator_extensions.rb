class Roar::Decorator

  def self.chapter_section_formatter
    lambda {|*| ChapterSectionFormatter.format(chapter_section) }
  end

end
