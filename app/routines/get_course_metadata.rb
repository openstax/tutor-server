class GetCourseMetadata
  lev_routine express_output: :metadata

  protected

  def mapping
    @@mapping ||=
      YAML.load_file(Rails.root.join('config', 'book-metadata-mapping.yml'))
  end

  def exec(course:, strategy_class: Content::Strategies::Direct::Ecosystem)
    ecosystem = GetCourseEcosystem[course: course, strategy_class: strategy_class]
    outputs[:metadata] = mapping[ecosystem.books.first.uuid]
  end
end
