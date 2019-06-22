class CreateResultCommentMasters < ActiveRecord::Migration[5.2]
  def change
    create_table :result_comment_masters do |t|
      t.text :comment
      t.string :woman_comment

      t.timestamps
    end
  end
end
