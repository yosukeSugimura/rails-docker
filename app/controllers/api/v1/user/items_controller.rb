class Api::V1::User::ItemsController < ApplicationController
    def index
        test = "test   wwww"
        render json: test
    end
end
