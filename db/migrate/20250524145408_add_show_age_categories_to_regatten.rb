class AddShowAgeCategoriesToRegatten < ActiveRecord::Migration[8.0]
  def change

    add_column :regatten, :show_age_categories, :string
    add_column :regatten, :show_countries, :boolean, default: true

  end
end
