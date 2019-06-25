class CreateResultStringCounts < ActiveRecord::Migration[5.2]
  def change
    create_table :result_string_counts do |t|
      t.integer :count
      t.integer :result_comment_master_id
      t.integer :rank_master_id

      t.timestamps
    end
  end
end
