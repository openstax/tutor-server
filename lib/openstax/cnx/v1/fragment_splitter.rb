module OpenStax::Cnx::V1
  class FragmentSplitter
    include HtmlTreeOperations

    attr_reader :processing_instructions, :reference_view_url

    def initialize(processing_instructions, reference_view_url)
      @processing_instructions = processing_instructions.map do |processing_instruction|
        OpenStruct.new(processing_instruction.to_h).tap do |pi_struct|
          pi_struct.fragments = [pi_struct.fragments].flatten.map(&:to_s).map(&:camelize) \
            unless pi_struct.fragments.nil?
          pi_struct.only = [pi_struct.only].flatten.map(&:to_s) unless pi_struct.only.nil?
          pi_struct.except = [pi_struct.except].flatten.map(&:to_s) unless pi_struct.except.nil?
        end
      end

      @reference_view_url = reference_view_url
    end

    # Splits the given root node into fragments according to the processing instructions
    def split_into_fragments(root, type = nil)
      result = [root.dup]
      type_string = type.to_s

      pis = processing_instructions.reject do |processing_instruction|
        processing_instruction.css.blank? ||
        processing_instruction.fragments.nil? ||
        processing_instruction.fragments == ['Node'] ||
        (!processing_instruction.only.nil? && !processing_instruction.only.include?(type_string)) ||
        (!processing_instruction.except.nil? && processing_instruction.except.include?(type_string))
      end

      @media_nodes = []

      pis.each { |processing_instruction| result = process_array(result, processing_instruction) }

      # Flatten, remove empty nodes and transform remaining nodes into reading fragments
      result.map do |obj|
        next obj unless obj.is_a?(Nokogiri::XML::Node)
        next if obj.content.blank?

        OpenStax::Cnx::V1::Fragment::Reading.new node: obj, reference_view_url: reference_view_url
      end.compact.tap do |result|
        @media_nodes.each do |node|
          # Media processing instructions
          node.css('[id], [name]', custom_css).each do |linkable|
            css_array = []
            css_array << "[href$=\"##{linkable[:id]}\"]" unless linkable[:id].nil?
            css_array << "[href$=\"##{linkable[:name]}\"]" unless linkable[:name].nil?
            css = css_array.join(', ')

            result.select(&:html?)
                  .select { |fragment| fragment.has_css? css, custom_css }
                  .each   { |fragment| fragment.append node.dup }
          end
        end

        result.select(&:html?).each(&:transform_links!)
      end
    end

    protected

    def custom_css
      OpenStax::Cnx::V1::CustomCss.instance
    end

    # Returns an instance of the given fragment class
    def get_fragment_instance(fragment_name, node, labels)
      fragment_class = "OpenStax::Cnx::V1::Fragment::#{fragment_name}".constantize
      args = { node: node, labels: labels }
      args[:reference_view_url] = reference_view_url \
        if fragment_class.is_a? OpenStax::Cnx::V1::Fragment::Reading
      fragment = fragment_class.new args
      fragment unless fragment.blank?
    end

    # Process a single Nokogiri::XML::Node
    def process_node(root, processing_instruction)
      # Find first match
      node = root.at_css(processing_instruction.css, custom_css)

      # Base case
      return [ root ] if node.nil?

      num_fragments = processing_instruction.fragments.size
      if num_fragments == 0 # No splitting needed
        # Remove the match node and any empty parents from the tree
        recursive_compact(node, root)

        # Repeat the processing until no more matches
        process_node(root, processing_instruction)
      else
        compact_before = true
        compact_after = true

        # Check for special fragment cases (node)
        fragments = []
        processing_instruction.fragments.each_with_index do |fragment, index|
          if fragment == 'Node'
            if index == 0
              # fragments: [node, anything] - Don't remove node from root before fragments
              compact_before = false
            elsif index == num_fragments - 1
              # fragments: [anything, node] - Don't remove node from root after fragments
              compact_after = false
            else
              # General case
              # Make a copy of the current node (up to the root), but remove all other nodes
              root_copy = root.dup
              node_copy = root_copy.at_css(processing_instruction.css, custom_css)

              remove_before(node_copy, root_copy)
              remove_after(node_copy, root_copy)

              fragments << root_copy
            end
          elsif fragment == 'Media'
            @media_nodes << node
          else
            fragments << get_fragment_instance(fragment, node, processing_instruction.labels)
          end
        end

        # Need to split the node tree
        # Copy the node content and find the same match in the copy
        root_copy = root.dup
        node_copy = root_copy.at_css(processing_instruction.css, custom_css)

        # One copy retains the content before the match;
        # the other retains the content after the match
        remove_after(node, root)
        remove_before(node_copy, root_copy)

        # Remove the match, its copy and any empty parents from the 2 trees
        recursive_compact(node, root) if compact_before
        recursive_compact(node_copy, root_copy) if compact_after

        # Repeat the processing until no more matches
        [ root ] + fragments + process_node(root_copy, processing_instruction)
      end
    end

    # Recursively process an array of Nodes and Fragments
    def process_array(array, processing_instruction)
      array.flat_map do |obj|
        case obj
        when Array
          process_array(obj, processing_instruction)
        when Nokogiri::XML::Node
          process_node(obj, processing_instruction)
        else
          obj
        end
      end
    end
  end
end
