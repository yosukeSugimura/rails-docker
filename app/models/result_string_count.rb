class ResultStringCount < ApplicationRecord
    belongs_to :rank_master
    alias_attribute :rank, :rank_master

    belongs_to :result_comment_master
    alias_attribute :comment, :result_comment_master

    belongs_to :result_detaile_master, :foreign_key => "id"
    alias_attribute :detaile, :result_detaile_master
end
