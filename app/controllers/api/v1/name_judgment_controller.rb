class Api::V1::NameJudgmentController < ActionController::API
  include NameJudgment

  def index
    if params[:name].blank? || params[:name].match(/\A[ぁ-んァ-ヶー一-龠]+\z/).nil?
      render json: { error: "有効な名前を入力してください" }, status: :bad_request
      return
    end

    begin
      unicode = change_unicode_point(params[:name].to_s)
      count = all_count_get(unicode)
      result = name_count_result(count)

      if result[:error]
        render json: { error: "指定された名前に対応するデータがありません" }, status: :not_found
      else
        render json: result, status: :ok
      end

    rescue StandardError => e
      Rails.logger.error("予期しないエラー: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: "予期しないエラーが発生しました" }, status: :internal_server_error
    end
  end
end
