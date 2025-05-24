class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Builds an Arel EXISTS condition for a given `has_many` association
  #
  # Example:
  #   Post.where(Post.exists_association(:comments))
  def self.exists_association(association_name)
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

    # Produces an EXISTS (SELECT 1 FROM ... WHERE ...) clause
    target_table.project(Arel.sql("1")).where(join_conditions).exists
  end

  # Scope: WHERE EXISTS (SELECT 1 FROM ... WHERE ...)
  scope :with_existing, ->(association_name) {
    where(exists_association(association_name))
  }

  # Scope: WHERE NOT EXISTS (SELECT 1 FROM ... WHERE ...)
  scope :without_existing, ->(association_name) {
    where.not(exists_association(association_name))
  }

  def to_anchor
    "#{self.class.name.underscore}_#{self.to_param}"
  end
end
