class Api::V1::NameJudgmentController < ActionController::API
    include NameJudgment
  
    def index
      unless params[:name].present?
        render json: { error: "名前を入力してください" }, status: :bad_request
        return
      end
  
      begin
        unicode = change_unicode_point(params[:name].to_s)
        count = all_count_get(unicode)
        result = name_count_result(count)
  
        if result[:error]
          render json: result, status: :not_found
        else
          render json: result, status: :ok
        end
  
      rescue StandardError => e
        render json: { error: "予期しないエラーが発生しました: #{e.message}" }, status: :internal_server_error
      end
    end
  end
  