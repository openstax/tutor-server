class XlsxHelper

  INVALID_WORKSHEET_NAME_CHARS_REGEX = /[:\\\/\[\]*?]/

  def initialize
    @truncated_name_count = 0
  end

  def standard_package_settings(package)
    package.use_shared_strings = true # OS X Numbers interoperability
    package.workbook.styles.fonts.first.name = 'Helvetica Neue'
    package.workbook.styles.fonts.first.sz = 11
  end

  # Worksheet name ostensible is "#{name}#{suffix}".  Both name and suffix
  # will be sanitized for disallowed characters.  The `name` may be shortened
  # to account for max name lengths.  The suffix will not be as it is intended
  # to come from the developer (and so shouldn't be too long).
  #
  def sanitized_worksheet_name(name:, suffix: nil)
    # worksheet names cannot contain characters :\/?*[]

    name = name.gsub(INVALID_WORKSHEET_NAME_CHARS_REGEX, '-')
    suffix = suffix.gsub(INVALID_WORKSHEET_NAME_CHARS_REGEX, '-')

    # worksheet names cannot be longer than 31 characters so we truncate any
    # names that will be 31 characters or longer when the suffix is included.
    # we also add a counter to avoid collisions between truncated names.

    if name.size < 31 - suffix.size
      "#{name}#{suffix}"
    else
      "#{name[0..(31-3-suffix.size)]}-#{'%02d' % next_truncated_name_count}#{suffix}"
    end
  end

  def add_row(sheet, optioned_values)
    optioned_values = OptionedValues.new(optioned_values)

    row = sheet.add_row(
      optioned_values.values,
      style: optioned_values.styles,
      types: optioned_values.types
    )

    optioned_values.merge_ranges.each do |merge_range|
      sheet.merge_cells sheet.rows.last.cells[merge_range] unless merge_range.size == 1
    end

    optioned_values.comments.each_with_index do |comment, index|
      next if comment.nil?
      sheet.add_comment(ref: row.cells[index], text: comment, author: "", visible: false)
    end
  end

  def self.cell_ref(row:, column:)
    "#{([''] + ('A'..'Z').to_a)[column / 26]}#{('A'..'Z').to_a[column % 26]}#{row}"
  end

  private

  def next_truncated_name_count
    @truncated_name_count += 1
  end

  class OptionedValues

    class OptionedValue
      def initialize(optioned_value, column)
        @value, hash =
          if optioned_value.is_a?(Array) && optioned_value.last.is_a?(Hash)
            [optioned_value.first, optioned_value.last]
          else
            [optioned_value, nil]
          end

        if hash
          @style = hash[:style]
          @type = hash[:type]
          @comment = hash[:comment]

          start_column = column
          end_column = column + (hash[:cols] ? hash[:cols] - 1 : 0)

          # Expand a value to have extra empty cells and style and type to be repeated
          # if spans multiple columns
          if hash[:cols] && hash[:cols] > 1
            @value = [@value].product(*(hash[:cols]-1).times.map{[""]}).flatten
            @style = hash[:cols].times.map{@style}
            @type = hash[:cols].times.map{@type}
          end
        end

        @merge_range = (start_column || column)..(end_column || column)
      end

      attr_accessor :value, :style, :type, :merge_range, :comment

      def last_column
        merge_range.max
      end
    end

    def initialize(raw_optioned_values)
      column = 0
      items = raw_optioned_values.collect do |rov|
        OptionedValue.new(rov, column).tap do |ov|
          column = ov.last_column + 1
        end
      end

      @values = items.collect(&:value).flatten
      @styles = items.collect(&:style).flatten
      @types = items.collect(&:type).flatten
      @merge_ranges = items.collect(&:merge_range)
      @comments = items.collect(&:comment)
    end

    attr_accessor :values, :styles, :types, :merge_ranges, :comments
  end

end
