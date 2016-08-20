class XlsxHelper

  INVALID_WORKSHEET_NAME_CHARS_REGEX = /[:\\\/\[\]*?]/

  def initialize
    @truncated_name_count = 0
  end

  def standard_package_settings(axlsx_package)
    axlsx_package.use_shared_strings = true # OS X Numbers interoperability
    axlsx_package.workbook.styles.fonts.first.name = 'Helvetica Neue'
    axlsx_package.workbook.styles.fonts.first.sz = 11
  end

  # Worksheet name ostensible is "#{name}#{suffix}".  Both name and suffix
  # will be sanitized for disallowed characters.  The `name` may be shortened
  # to account for max name lengths.  The suffix will not be shortened as it
  # is intended to come from the developer (and so shouldn't be too long --
  # in any event, the suffix must be 27 characters or less.)
  #
  def sanitized_worksheet_name(name:, suffix: nil)
    # worksheet names cannot contain characters :\/?*[]

    raise(IllegalArgument, "`name` must be provided") if name.nil?
    suffix ||= ""

    # In some cases suffix can be longer, but it is more clear to make this a
    # simple requirement that is always the same.
    raise(IllegalArgument, "`suffix` is limited to 27 characters") if suffix.size > 27

    name = name.gsub(INVALID_WORKSHEET_NAME_CHARS_REGEX, '-')
    suffix = suffix.gsub(INVALID_WORKSHEET_NAME_CHARS_REGEX, '-')

    # worksheet names cannot be longer than 31 characters so we truncate any
    # names that will be 31 characters or longer when the suffix is included.
    # we also add a counter to avoid collisions between truncated names.

    if name.size <= 31 - suffix.size
      "#{name}#{suffix}"
    else
      "#{name[0..(30-3-suffix.size)]}-#{'%02d' % next_truncated_name_count}#{suffix}"
    end
  end

  # Normally, when adding a row in Axlsx you have to specify the values separately
  # from the values, e.g.:
  #
  #   sheet.add_row(["Foo", "Bar", "Hi"], style: [black, blue, red])
  #
  # which is a little error prone when your rows get long.  This `add_row` method lets
  # you specify :style, :type, :comment, :cols right next to the value, e.g.
  #
  #   helper.add_row(
  #     "Unstyled text",
  #     ["Foo", {style: black}],
  #     ["Bar", {comment: "I use to hate saying 'foo' and 'bar'"}]
  #   )
  #
  # Options:
  #
  #   :style -- just like the normal Axlsx :style
  #   :type -- just like the normal Axlsx :type
  #   :comment -- text of a comment to add to the cell
  #   :cols -- a number specifying the width of the column (triggers `merge_cells`)
  #
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
      next if comment.blank?
      sheet.add_comment(ref: row.cells[index], text: comment, author: "", visible: false)
      # TODO might need to product comments like values and data validations
    end

    optioned_values.data_validations.each_with_index do |dv, index|
      next unless dv.present?
      sheet.add_data_validation(row.cells[index].r, dv)
    end
  end

  def merge_and_style(sheet, range, styles)
    if range.is_a?(Array)
      # assume columns are 1-indexed, to match row numbers
      range = "#{Axlsx::col_ref(range[0]-1)}#{range[1]}:#{Axlsx::col_ref(range[2]-1)}#{range[3]}"
    end

    sheet.merge_cells(range)
    sheet[range].each{|cell| cell.style = styles} unless styles.blank?
  end

  private

  def next_truncated_name_count
    @truncated_name_count += 1
  end

  # OptionedValues and its inner class OptionedValue are used to parse and expand
  # the options passed to the `add_row` method above.

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
          @data_validation = hash[:data_validation]

          start_column = column
          end_column = column + (hash[:cols] ? hash[:cols] - 1 : 0)

          # Expand a value to have extra empty cells and style and type to be repeated
          # if spans multiple columns
          if hash[:cols] && hash[:cols] > 1
            @value = [@value].product(*(hash[:cols]-1).times.map{[""]}).flatten
            @style = hash[:cols].times.map{@style}
            @type = hash[:cols].times.map{@type}
            @data_validation = [@data_validation].product(*(hash[:cols]-1).times.map{[nil]}).flatten
          end
        end

        @merge_range = (start_column || column)..(end_column || column)
      end

      attr_accessor :value, :style, :type, :merge_range, :comment, :data_validation

      def last_column
        merge_range.max
      end
    end

    def initialize(raw_optioned_values)
      column = 0
      items = raw_optioned_values.map do |rov|
        OptionedValue.new(rov, column).tap do |ov|
          column = ov.last_column + 1
        end
      end

      @values = items.map(&:value).flatten
      @styles = items.map(&:style).flatten
      @types = items.map(&:type).flatten
      @merge_ranges = items.map(&:merge_range)
      @comments = items.map(&:comment)
      @data_validations = items.map(&:data_validation).flatten
    end

    attr_accessor :values, :styles, :types, :merge_ranges, :comments, :data_validations
  end

end
