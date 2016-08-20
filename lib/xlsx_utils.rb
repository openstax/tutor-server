module XlsxUtils

  def cell_ref(row:, column:)
    # There is http://www.rubydoc.info/github/randym/axlsx/Axlsx#col_ref-class_method
    # but this massive interpolated string makes me one-line-of-ruby happy.
    "#{Axlsx.col_ref(column)}#{row}"
  end

  def range(array)
    "#{Axlsx::col_ref(array[0]-1)}#{array[1]}:#{Axlsx::col_ref(array[2]-1)}#{array[3]}"
  end

  def disjoint_range(cols:, rows:, default_if_empty: "NA()")
    return default_if_empty if cols.blank? || rows.blank?

    if cols.is_a?(Array) && rows.is_a?(Array)
      raise "Dimensions don't match" if cols.length != rows.length
    elsif cols.is_a?(Array)
      rows = [rows] * cols.length
    elsif rows.is_a?(Array)
      cols = [cols] * rows.length
    else
      rows = [rows]
      cols = [cols]
    end

    cols.map.with_index{|col, ii| "#{col}#{rows[ii]}"}.join(",")
  end

end
