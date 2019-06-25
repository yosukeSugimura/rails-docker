class Api::V1::NameJudgmentController < ApplicationController
    include NameJudgment

    def index
        if params[:name].present?
            name = params[:name].to_s
        else
            render json: { error:"名前を入力してください" }
            return
        end

        unicode = change_unicode_point(name)
        count = all_count_get(unicode)
        render json: name_count_result(count)
    end
end
