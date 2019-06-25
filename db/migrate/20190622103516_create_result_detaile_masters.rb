class CreateResultDetaileMasters < ActiveRecord::Migration[5.2]
  def change
    create_table :result_detaile_masters do |t|
      t.text :detaile
      t.string :woman_comment

      t.timestamps
    end
  end
end
