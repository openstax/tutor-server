module OpenStax::Cnx::V1
  class BookPart

    def initialize(hash: {}, path: nil, title: nil, contents: nil, parts: nil)
      @hash     = hash
      @path     = path
      @title    = title
      @contents = contents
      @parts    = parts
    end

    attr_reader :hash, :path

    def title
      @title ||= hash.fetch('title') { |key|
        raise "BookPart id=#{id} is missing #{key}"
      }
    end

    def contents
      @contents ||= hash.fetch('contents') { |key|
        raise "BookPart id=#{id} is missing #{key}"
      }
    end

    def parts
      @parts ||= contents.each_with_index.collect do |hash, idx|
        next_path = path.blank? ? "#{idx.to_s}" : "#{path}.#{idx.to_s}"

        if hash['id'] == 'subcol'
          BookPart.new(hash: hash, path: next_path)
        else
          Page.new(hash: hash, path: next_path)
        end
      end
    end

    def to_s(indent: 0)
      s = "#{' '*indent}PART #{title}\n"
      s << parts.collect{|part| part.to_s(indent: indent+2)}.join('')
    end

  end
end
