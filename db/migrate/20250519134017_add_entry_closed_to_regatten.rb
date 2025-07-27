class AddEntryClosedToRegatten < ActiveRecord::Migration[8.0]
  def change
    add_column :regatten, :entry_closed, :boolean

    up_only do
      if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")
        execute <<~SQL
          CREATE OR REPLACE FUNCTION YEAR(ts TIMESTAMP)
          RETURNS INTEGER AS $$
          BEGIN
            RETURN EXTRACT(YEAR FROM ts)::INTEGER;
          END;
          $$ LANGUAGE plpgsql IMMUTABLE STRICT;
        SQL
      end
      execute "UPDATE regatten SET entry_closed = true WHERE YEAR(\"StartDatum\") < #{Date.current.year}"
    end
  end
end
