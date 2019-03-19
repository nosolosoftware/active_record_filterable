require 'active_record_filterable/version'
require 'active_record_filterable/filter'
require 'active_record_filterable/filterable'

ActiveRecord::Relation.send(:include, ActiveRecord::Filterable::Filter)
