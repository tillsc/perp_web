class AddRefereesToMeasurementSets < ActiveRecord::Migration[7.1]
  def change
    add_column :measurement_sets, :referee_starter_id, :integer
    add_column :measurement_sets, :referee_aligner_id, :integer
    add_column :measurement_sets, :referee_umpire_id, :integer
    add_column :measurement_sets, :referee_finish_judge_id, :integer
  end
end
