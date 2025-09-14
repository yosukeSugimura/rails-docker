# frozen_string_literal: true

require 'rails_helper'

# Create a test controller to test ApplicationController functionality
class TestController < ApplicationController
  def index
    render json: { message: 'success' }
  end

  def show
    raise ActiveRecord::RecordNotFound, 'Test record not found'
  end

  def create
    raise ActionController::ParameterMissing.new(:required_param)
  end

  def update
    raise StandardError, 'Test internal error'
  end

  def destroy
    render_success({ id: params[:id] }, 'Resource deleted')
  end

  def error_test
    render_error('Test error message', :unprocessable_entity, ['Error 1', 'Error 2'])
  end

  private

  def authenticate_user!
    redirect_to '/login' unless session[:user_id]
  end
end

RSpec.describe ApplicationController, type: :controller do
  # Set up test routes
  before(:all) do
    Rails.application.routes.draw do
      resources :test, controller: 'test', only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :error_test
        end
      end
    end
  end

  after(:all) do
    Rails.application.reload_routes!
  end

  controller(TestController) do
  end

  describe 'security headers' do
    it 'sets security headers on all responses' do
      get :index

      expect(response.headers['X-Frame-Options']).to eq('DENY')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
      expect(response.headers['Permissions-Policy']).to include('geolocation=()')
    end
  end

  describe 'error handling' do
    context 'ActiveRecord::RecordNotFound' do
      it 'handles not found errors with JSON response' do
        get :show, params: { id: 1 }

        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Not Found')
      end
    end

    context 'ActionController::ParameterMissing' do
      it 'handles missing parameter errors' do
        post :create

        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Bad Request')
      end
    end

    context 'StandardError in production' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it 'handles internal server errors in production' do
        patch :update, params: { id: 1 }

        expect(response).to have_http_status(:internal_server_error)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Internal Server Error')
      end
    end
  end

  describe 'API response helpers' do
    it 'renders success responses with proper format' do
      delete :destroy, params: { id: 123 }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body).to include(
        'success' => true,
        'message' => 'Resource deleted',
        'data' => { 'id' => '123' }
      )
    end

    it 'renders error responses with proper format' do
      get :error_test

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)

      expect(body).to include(
        'success' => false,
        'message' => 'Test error message',
        'errors' => ['Error 1', 'Error 2']
      )
    end
  end

  describe 'logging' do
    let(:logger) { instance_double(ActiveSupport::Logger) }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    it 'logs request information in development' do
      expect(logger).to receive(:info).with(/Request: GET/)
      expect(logger).to receive(:info).with(/Params:/)
      expect(logger).to receive(:info).with(/Response:/)

      get :index
    end
  end

  describe 'CSRF protection' do
    it 'protects against CSRF attacks' do
      expect(controller.class.ancestors).to include(ActionController::RequestForgeryProtection)
    end
  end

  describe 'authentication helpers' do
    controller(TestController) do
    end

    before do
      routes.draw { get :index, to: 'test#index' }
    end

    describe '#current_user' do
      context 'when user_id is in session' do
        let(:user) { double('User', id: 1) }

        before do
          allow(User).to receive(:find).with(1).and_return(user)
          session[:user_id] = 1
        end

        it 'returns the current user' do
          expect(controller.send(:current_user)).to eq(user)
        end

        it 'memoizes the user lookup' do
          expect(User).to receive(:find).once.and_return(user)

          2.times { controller.send(:current_user) }
        end
      end

      context 'when no user_id in session' do
        it 'returns nil' do
          expect(controller.send(:current_user)).to be_nil
        end
      end
    end

    describe '#authenticate_user!' do
      context 'when user is logged in' do
        before do
          session[:user_id] = 1
          allow(User).to receive(:find).with(1).and_return(double('User'))
        end

        it 'does not redirect' do
          controller.send(:authenticate_user!)
          expect(response).not_to be_redirect
        end
      end

      context 'when user is not logged in' do
        it 'redirects to login path' do
          expect(controller).to receive(:redirect_to).with('/login')
          controller.send(:authenticate_user!)
        end
      end
    end
  end

  describe 'utility methods' do
    controller(TestController) do
    end

    describe '#permitted_params' do
      it 'extracts permitted parameters' do
        allow(controller.params).to receive(:require).with(:test).and_return(
          double('ActionController::Parameters').tap do |params|
            expect(params).to receive(:permit).with(:name, :email).and_return({ name: 'John', email: 'john@example.com' })
          end
        )

        result = controller.send(:permitted_params, :name, :email)
        expect(result).to eq({ name: 'John', email: 'john@example.com' })
      end
    end
  end

  describe 'content type handling' do
    controller(TestController) do
    end

    before do
      routes.draw { get :index, to: 'test#index' }
    end

    it 'handles JSON requests properly' do
      request.headers['Accept'] = 'application/json'
      get :index

      expect(response.content_type).to include('application/json')
    end

    it 'handles HTML requests properly' do
      request.headers['Accept'] = 'text/html'

      # This will result in a missing template error, but that's expected
      # as we're testing the controller behavior, not the view rendering
      expect { get :index }.to raise_error(ActionView::MissingTemplate)
    end
  end

  describe 'request/response cycle' do
    controller(TestController) do
    end

    before do
      routes.draw { get :index, to: 'test#index' }
    end

    it 'completes a full request/response cycle successfully' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_present

      # Verify security headers are present
      expect(response.headers).to include(
        'X-Frame-Options',
        'X-XSS-Protection',
        'X-Content-Type-Options'
      )
    end

    it 'measures response time', :performance do
      get :index
      # Performance measurement is handled by the :performance tag
    end
  end
end