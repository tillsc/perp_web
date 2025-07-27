class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # General subquery builder for associations
  def self.association_subquery(association_name, mode: :exists, &extra_conditions_block)
    reflection = reflections[association_name.to_s]

    unless reflection
      raise ArgumentError, "Unknown association: #{association_name}"
    end

    unless reflection.macro == :has_many
      raise ArgumentError, "Only has_many associations are supported (got #{reflection.macro})"
    end

    foreign_keys = Array(reflection.foreign_key)
    primary_keys = Array(reflection.active_record_primary_key)

    unless foreign_keys.size == primary_keys.size
      raise ArgumentError, "Mismatch in key counts: #{foreign_keys} vs #{primary_keys}"
    end

    source_table = arel_table
    target_table = reflection.klass.arel_table

    join_conditions = foreign_keys.zip(primary_keys).map do |fk, pk|
      target_table[fk].eq(source_table[pk])
    end.reduce(&:and)

    if extra_conditions_block
      join_conditions = extra_conditions_block.call(join_conditions, target_table)
    end

    case mode
    when :exists
      target_table.project(Arel.sql("1")).where(join_conditions).exists
    when :count
      Arel::Nodes::Grouping.new(
        target_table.project(Arel.star.count).where(join_conditions)
      )
    else
      raise ArgumentError, "Unknown mode: #{mode.inspect} (expected :exists or :count)"
    end
  end

  # Alias for mode: :exists
  def self.exists_association(association_name, &block)
    association_subquery(association_name, mode: :exists, &block)
  end

  # Alias for mode: :count
  def self.count_association(association_name, &block)
    association_subquery(association_name, mode: :count, &block)
  end

  # Scope: WHERE EXISTS (SELECT 1 FROM ... WHERE ...)
  scope :with_existing, ->(association_name, &block) {
    where(exists_association(association_name))
  }

  # Scope: WHERE NOT EXISTS (SELECT 1 FROM ... WHERE ...)
  scope :without_existing, ->(association_name, &block) {
    where.not(exists_association(association_name, &block))
  }

  # Scope: SELECT *, (SELECT COUNT(*) FROM ...) AS <association_name>_count for the given associations
  scope :with_counts, ->(*association_names, &block) {
    selections = [arel_table[Arel.star]] +
                 association_names.map do |name|
                   count_association(name).as("#{name}_count", &block)
                 end

    select(*selections)
  }

  def to_anchor
    "#{self.class.name.underscore}_#{self.to_param}"
  end

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
