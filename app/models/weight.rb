class Weight < ApplicationRecord

  self.table_name = 'gewichte'

  belongs_to :rower, foreign_key: 'Ruderer_ID'

  alias_attribute :weight, 'Gewicht'
  alias_attribute :date, 'Datum'
  alias_attribute :rower_id, 'Ruderer_ID'

  default_scope do
    order(arel_table[:date].asc, arel_table[:rower_id].asc)
  end

  def self.left_join_weights_for(date)


    participants.join(weights, Arel::Nodes::OuterJoin).on(join_condition).join_sources
  end

  # Adds info columns for weighting.
  #
  # Assumes tables/relationships :event, :race and :participant to be present/joined correctly before
  def self.apply_info_scope(outer_scope, date)
    g = arel_table.alias('g')
    rowers_join = arel_table.join(g, Arel::Nodes::OuterJoin).on(
      g[:date].between(date.all_day).
        and(Participant.any_rower_eq_condition(g[:rower_id], no_cox: true))
    ).join_sources

    g_st = arel_table.alias('gSt')
    cox_join = arel_table.join(g_st, Arel::Nodes::OuterJoin).on(
      g_st[:date].between(date.all_day).
        and(Participant.arel_table[:rowers_id].eq(g_st[:rower_id]))
    ).join_sources

    outer_scope.
      joins(rowers_join).
      joins(cox_join).
      select(g[:weight].average.as('average_rower_weight'),
             g[:weight].maximum.as('maximum_rower_weight'),
             g_st[:weight].maximum.as('minimum_cox_weight'),
             Participant.arel_table[:participant_id].count(true).as('participants_count'),
             g[:rower_id].count(true).as('rower_weights_count'),
             Arel::Nodes::Multiplication.new(
               Participant.arel_table[:participant_id].count(true),
               Event.arel_table[:rower_count]
             ).as('expected_rower_weights_count'),
             g_st[:rower_id].count(true).as('cox_weights_count'),
             Arel::Nodes::Multiplication.new(
               Participant.arel_table[:participant_id].count(true),
               bool_to_int_sql(Event.arel_table[:has_cox])
             ).as('expected_cox_weights_count'),
             Race.arel_table[:planned_for].minimum.as('min_started_at'),
             Race.arel_table[:weight_list_approved_at].maximum.as('approved'))
  end

  def self.info_scope_group_by_columns(base_table: Event)
    if base_table != Event
      [ base_table.arel_table[:event_number],
        base_table.arel_table[:regatta_id],
      ]
    else
      []
    end + [
      Event.arel_table[:number],
      Event.arel_table[:regatta_id],
      Event.arel_table[:rower_count], Event.arel_table[:has_cox]
    ]
  end

end
