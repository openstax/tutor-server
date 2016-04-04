module OpenStax::Cnx::V1
  class FragmentSplitter

    include HtmlTreeOperations

    attr_reader :processing_instructions

    def initialize(processing_instructions)
      @processing_instructions = processing_instructions.map{ |pi| Hashie::Mash.new(pi) }
    end

    # Splits the given node into fragments according to the processing instructions
    def split_into_fragments(node)
      result = [node.dup]

      processing_instructions.each do |processing_instruction|
        next if processing_instruction.css.blank?

        result = process_array(result, processing_instruction)
      end

      cleanup_array(result)
    end

    protected

    # Gets the fragments for a Nokogiri::XML::Node according to a ProcessingInstruction
    def get_fragments(node, processing_instruction)
      (processing_instruction.fragments || []).map do |fragment_name|
        fragment_class = "OpenStax::Cnx::V1::Fragment::#{fragment_name.classify}".constantize
        fragment_class.new(node: node, labels: processing_instruction.labels)
      end
    end

    # Process a single Nokogiri::XML::Node
    def process_node(node, processing_instruction)
      # Find first match
      match = node.at_css(processing_instruction.css)

      return node if match.nil?

      # Get fragments for the match
      fragments = get_fragments(match, processing_instruction)

      # Copy the node content and find the same match in the copy
      node_copy = node.dup
      match_copy = node_copy.at_css(processing_instruction.css)

      # One copy retains the content before the match;
      # the other retains the content after the match
      remove_after(match, node)
      remove_before(match_copy, node_copy)

      # Remove the split node, its copy and any empty parents from the 2 trees
      recursive_compact(match, node)
      recursive_compact(match_copy, node_copy)

      # Repeat the processing until no more matches
      [node, fragments, process_node(node_copy, processing_instruction)]
    end

    # Recursively process an array of Nodes and Fragments
    def process_array(array, processing_instruction)
      array.map do |elt|
        case elt
        when Array
          process_array(elt, processing_instruction)
        when Nokogiri::XML::Node
          process_node(elt, processing_instruction)
        else
          elt
        end
      end
    end

    # Flatten, remove empty nodes and transform remaining nodes into reading fragments
    def cleanup_array(array)
      array.flatten.map do |obj|
        next obj unless obj.is_a?(Nokogiri::XML::Node)
        next if obj.content.blank?

        OpenStax::Cnx::V1::Fragment::Reading.new(node: obj)
      end.compact
    end

  end
end
