# require 'squeel'

# # Patch for https://github.com/activerecord-hackery/squeel/issues/374
# module Squeel
#   module Adapters
#     module ActiveRecord
#       module RelationExtensions
#         def execute_grouped_calculation(operation, column_name, distinct)
#           if @loaded || (defined?(@arel) && @arel)
#             dup.execute_grouped_calculation(operation, column_name, distinct)
#           else
#             arel = Arel::SelectManager.new(table.engine, table)
#             build_join_dependency(arel, joins_values.flatten) unless joins_values.empty?
#             self.group_values = group_visit(group_values.uniq.reject(&:blank?)) \
#               unless group_values.empty?
#             super
#           end
#         end
#       end
#     end
#   end
# end
