class CreateResultStringCounts < ActiveRecord::Migration[5.2]
  def change
    create_table :result_string_counts do |t|
      t.integer :count
      t.integer :result_detaile_master_id
      t.integer :result_master_id

      t.timestamps
    end
  end
end
