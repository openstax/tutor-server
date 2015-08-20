module HtmlTreeOperations
  # Recursively removes a node and its empty parents
  def recursive_compact(node, stop_node)
    return if node == stop_node

    parent = node.parent
    node.remove

    if parent && parent.content.blank?
      recursive_compact(parent, stop_node)
    end
  end

  # Recursively removes all siblings before a node and its parents
  # Returns the stop_node
  def remove_before(node, stop_node)
    return if node == stop_node

    if parent = node.parent
      siblings = parent.children
      index = siblings.index(node)
      parent.children = siblings.slice(index..-1)
      remove_before(parent, stop_node)
    end
  end

  # Recursively removes all siblings after a node and its parents
  # Returns the stop_node
  def remove_after(node, stop_node)
    return if node == stop_node

    if parent = node.parent
      siblings = parent.children
      index = siblings.index(node)
      parent.children = siblings.slice(0..index)
      remove_after(parent, stop_node)
    end
  end
end
