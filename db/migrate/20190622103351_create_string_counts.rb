class CreateStringCounts < ActiveRecord::Migration[5.2]
  def change
    create_table :string_counts do |t|
      t.string :unicode
      t.string :chara
      t.integer :count

      t.timestamps
    end
  end
end
