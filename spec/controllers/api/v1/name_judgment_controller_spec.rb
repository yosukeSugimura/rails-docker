require 'rails_helper'

RSpec.describe Api::V1::NameJudgmentController, type: :controller do
  describe "GET #index" do
    let(:valid_name) { "山田太郎" }
    let(:invalid_name) { "123" }
    let(:not_found_name) { "不存在の名前" }

    before do
      allow(controller).to receive(:change_unicode_point).and_return(['5C71', '7530'])
      allow(controller).to receive(:all_count_get).with(['5C71', '7530']).and_return(10)
    end

    context "名前が入力されている場合" do
      it "正しいレスポンスを返す" do
        allow(controller).to receive(:name_count_result).with(10).and_return({ count: 10, rank: "A", comment: "Good", detail: "詳細" })

        get :index, params: { name: valid_name }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['count']).to eq(10)
        expect(json['rank']).to eq("A")
      end
    end

    context "名前が空の場合" do
      it "400 Bad Requestを返す" do
        get :index, params: { name: "" }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("有効な名前を入力してください")
      end
    end

    context "不適切な名前の場合" do
      it "400 Bad Requestを返す" do
        get :index, params: { name: invalid_name }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("有効な名前を入力してください")
      end
    end

    context "データが見つからない場合" do
      it "404 Not Foundを返す" do
        allow(controller).to receive(:name_count_result).and_return({ error: "指定された名前に対応するデータがありません" })
      
        get :index, params: { name: not_found_name }
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("指定された名前に対応するデータがありません")
      end
    end

    context "予期しないエラーが発生した場合" do
      it "500 Internal Server Errorを返す" do
        allow(controller).to receive(:change_unicode_point).and_raise(StandardError, "予期しないエラー")

        get :index, params: { name: valid_name }
        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body)
        expect(json['error']).to include("予期しないエラーが発生しました")
      end
    end
  end
end
