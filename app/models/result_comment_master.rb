class ResultCommentMaster < ApplicationRecord
    has_many :result_string_counts, dependent: :destroy
end
