class Api::V1::User::ItemsController < ApplicationController
    require 'net/http'

    def index
        test = {
            test:"test wwww"
        }
        render json: test
    end
end
