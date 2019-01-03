module ActiveRecord
  module Filterable
    module Filter
      ##
      # Applies params scopes to current scope
      #
      def filter(filtering_params, operator='and')
        return all if filtering_params.blank?
        criteria = nil

        unscoped do
          criteria = is_a?(ActiveRecord::Relation) ? self : all

          filtering_params.each do |key, value|
            next unless respond_to?("filter_with_#{key}")

            # Add support for both kind of scopes: scope with multiple arguments and scope with
            # one argument as array
            value = [value] unless value.is_a?(Array) &&
              scope_arities["filter_with_#{key}".to_sym] > 1

            # check the number of arguments of filter scope
            criteria =
              if operator == 'and' || criteria.where_clause.empty?
                criteria.public_send("filter_with_#{key}", *value)
              else
                criteria.or(all.public_send("filter_with_#{key}", *value))
              end
          end
        end

        criteria == self ? none : merge(criteria)
      end
    end
  end
end
