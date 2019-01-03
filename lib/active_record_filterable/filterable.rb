module ActiveRecord
  module Filterable
    extend ActiveSupport::Concern

    included do
      class_attribute(:scope_arities)
      self.scope_arities = ActiveSupport::HashWithIndifferentAccess.new
    end

    # rubocop:disable Metrics/BlockLength
    class_methods do
      include Filter

      def scope(name, scope_options, &block)
        super
        scope_arities[name] = scope_options.is_a?(Proc) ? scope_options.arity : -1
      end

      ##
      # Adds attr scope
      #
      def filter_by(attr, filter=nil)
        if filter
          scope "filter_with_#{attr}", filter
        else
          scope "filter_with_#{attr}", ->(value) { where(attr => value) }
        end
      end

      ##
      # Adds attr scope using normalized values
      #
      def filter_by_normalized(attr)
        normalized_name = (attr.to_s + '_normalized').to_sym
        adapter_name = ActiveRecord::Base.connection.adapter_name.downcase

        body =
          if adapter_name.starts_with?('postgresql')
            lambda { |value|
              where("unaccent(#{attr}) ILIKE unaccent(?)", "%#{sanitize_sql_like(value)}%")
            }
          else
            lambda { |value|
              where("#{attr} LIKE ?", "%#{sanitize_sql_like(value)}%")
            }
          end

        scope "filter_with_#{normalized_name}", body
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
