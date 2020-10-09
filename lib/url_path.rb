# https://stackoverflow.com/a/34620369
module UrlPath

  def self.join(*paths, separator: '/')
    paths = paths.compact.reject(&:empty?)
    last = paths.length - 1
    paths.each_with_index.reduce([]) { |parts, (path, index)|
      # remove url part above when ../ is encountered
      path.gsub!(%r{\.\.\/}) do |_|
        parts.pop
        index -= 1
        last -= 1
        ''
      end

      parts << _expand(path, index, last, separator)
      parts
    }.join
  end

  def self._expand(path, current, last, separator)
    if path.start_with?(separator) && current != 0
      path = path[1..-1]
    end

    unless path.end_with?(separator) || current == last
      path = [path, separator]
    end
    path
  end
end
