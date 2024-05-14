class AddFinishCamFields < ActiveRecord::Migration[7.1]
  def change
    add_column :messpunkte, :finish_cam_base_url, :string
    add_column :measurement_sets, :finish_cam_metadata, :text
  end
end
