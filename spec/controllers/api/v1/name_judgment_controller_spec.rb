require 'rails_helper'

RSpec.describe Api::V1::NameJudgmentController, type: :controller do
  describe "GET #index" do
    context "名前が入力されている場合" do
      it "正しいレスポンスを返す" do
        get :index, params: { name: "example" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "名前が入力されていない場合" do
      it "エラーを返す" do
        get :index
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("名前を入力してください")
      end
    end

    context "不適切な名前の場合" do
      it "400 Bad Requestを返す" do
        get :index, params: { name: "badword" }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
