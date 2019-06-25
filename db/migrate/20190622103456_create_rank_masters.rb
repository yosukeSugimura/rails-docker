class CreateRankMasters < ActiveRecord::Migration[5.2]
  def change
    create_table :rank_masters do |t|
      t.string :rank

      t.timestamps
    end
  end
end
