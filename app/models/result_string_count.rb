class ResultStringCount < ApplicationRecord
    belongs_to :rank_master, optional: true
    alias_attribute :rank, :rank_master

    belongs_to :result_comment_master, optional: true
    alias_attribute :comment, :result_comment_master

    belongs_to :result_detaile_master, :foreign_key => "id", optional: true
    alias_attribute :detaile, :result_detaile_master
end
