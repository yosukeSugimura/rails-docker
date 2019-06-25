class CreateResultCommentMasters < ActiveRecord::Migration[5.2]
  def change
    create_table :result_comment_masters do |t|
      t.string :comment

      t.timestamps
    end
  end
end
