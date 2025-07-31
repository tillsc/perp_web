class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.bool_to_int_sql(attribute)
    unless attribute.is_a?(Arel::Attributes::Attribute)
      attribute = self.arel_table[attribute]
    end

    column = ActiveRecord::Base.connection.schema_cache.columns_hash(attribute.relation.name)[attribute.name.to_s]

    if column&.sql_type.to_s.downcase == "boolean"
      Arel.sql(%Q{"#{attribute.relation.name}"."#{attribute.name}"::int})
    else
      attribute
    end
  end
end
