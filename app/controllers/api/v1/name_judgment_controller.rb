class Api::V1::NameJudgmentController < ApplicationController
    require 'net/http'

    def index
        string= '亜'
        test = {
            test:change_unicode_point(string)
        }
        render json: test
    end

    #　文字のうにコード変換
    #
    def change_unicode_point(string)
        arr_unicode = string.force_encoding("utf-8").unpack("U*")
        unicode = sprintf("%#x", arr_unicode[0])
        unicode[0,2] = "U+"
        unicode
    end
end
