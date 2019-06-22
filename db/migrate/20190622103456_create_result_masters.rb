class CreateResultMasters < ActiveRecord::Migration[5.2]
  def change
    create_table :result_masters do |t|
      t.string :result

      t.timestamps
    end
  end
end
