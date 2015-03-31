module HtmlTreeOperations
  # Recursively removes a node and its empty parents
  def recursive_compact(node, stop_node)
    return if node == stop_node

    # Get parent
    parent = node.parent

    # Remove current node
    node.remove

    # Remove parent if empty
    recursive_compact(parent, stop_node) if parent.content.blank?
  end

  # Recursively removes all siblings before a node and its parents
  # Returns the stop_node
  def remove_before(node, stop_node)
    # Stopping condition
    return if node == stop_node

    # Get parent
    parent = node.parent

    # Get siblings
    siblings = parent.children

    # Get node's index
    index = siblings.index(node)

    # Remove siblings before node
    parent.children = siblings.slice(index..-1)

    # Remove nodes after the parent
    remove_before(parent, stop_node)
  end

  # Recursively removes all siblings after a node and its parents
  # Returns the stop_node
  def remove_after(node, stop_node)
    # Stopping condition
    return if node == stop_node

    # Get parent
    parent = node.parent

    # Get siblings
    siblings = parent.children

    # Get node's index
    index = siblings.index(node)

    # Remove siblings after node
    parent.children = siblings.slice(0..index)

    # Remove nodes after the parent
    remove_after(parent, stop_node)
  end
end
