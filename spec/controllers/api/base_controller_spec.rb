# frozen_string_literal: true

require 'rails_helper'

# Test controller to test Api::BaseController functionality
class TestApiController < Api::BaseController
  def index
    render_success({ items: ['item1', 'item2'] }, 'Items retrieved')
  end

  def show
    render_error('Item not found', :not_found)
  end

  def create
    render_success({ id: 1, name: 'New item' }, 'Item created', :created)
  end

  def update
    raise ActiveRecord::RecordInvalid.new(double('record', errors: double('errors', full_messages: ['Name is required'])))
  end

  def destroy
    raise ActionController::ParameterMissing.new(:id)
  end

  def test_version
    render json: { version: api_version }
  end

  def test_auth
    authenticate_api_user!
    render_success({ user: 'authenticated' })
  end

  private

  def authenticate_with_token(token)
    return double('User', id: 1, name: 'Test User') if token == 'valid_token'
    nil
  end
end

RSpec.describe Api::BaseController, type: :controller do
  before(:all) do
    Rails.application.routes.draw do
      namespace :api do
        resources :test_api, controller: 'test_api', only: [:index, :show, :create, :update, :destroy] do
          collection do
            get :test_version
            get :test_auth
          end
        end
      end
    end
  end

  after(:all) do
    Rails.application.reload_routes!
  end

  controller(TestApiController) do
  end

  describe 'CSRF protection' do
    it 'skips CSRF verification for API endpoints' do
      post :create
      expect(response).to have_http_status(:created)
    end
  end

  describe 'default format setting' do
    it 'sets JSON as default format' do
      get :index
      expect(response.content_type).to include('application/json')
    end

    it 'respects explicit format parameter' do
      get :index, params: { format: :json }
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'API versioning' do
    it 'defaults to v1 when no version specified' do
      get :test_version
      body = JSON.parse(response.body)
      expect(body['version']).to eq('v1')
    end

    it 'accepts version from Accept-Version header' do
      request.headers['Accept-Version'] = 'v1'
      get :test_version
      body = JSON.parse(response.body)
      expect(body['version']).to eq('v1')
    end

    it 'accepts version from params' do
      get :test_version, params: { version: 'v1' }
      body = JSON.parse(response.body)
      expect(body['version']).to eq('v1')
    end

    it 'rejects unsupported API version' do
      request.headers['Accept-Version'] = 'v999'
      get :index

      expect(response).to have_http_status(:not_acceptable)
      body = JSON.parse(response.body)
      expect(body['message']).to eq('Unsupported API version')
    end
  end

  describe 'success responses' do
    it 'renders success response with correct format' do
      get :index

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body).to include(
        'success' => true,
        'message' => 'Items retrieved',
        'data' => { 'items' => ['item1', 'item2'] },
        'meta' => hash_including(
          'timestamp' => be_present,
          'version' => 'v1'
        )
      )
    end

    it 'renders success response with custom status' do
      post :create

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)

      expect(body).to include(
        'success' => true,
        'message' => 'Item created'
      )
    end
  end

  describe 'error responses' do
    it 'renders error response with correct format' do
      get :show, params: { id: 1 }

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)

      expect(body).to include(
        'success' => false,
        'message' => 'Item not found',
        'meta' => hash_including(
          'timestamp' => be_present,
          'version' => 'v1'
        )
      )
    end
  end

  describe 'error handling' do
    context 'ActiveRecord::RecordInvalid' do
      it 'handles validation errors' do
        patch :update, params: { id: 1 }

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)

        expect(body).to include(
          'success' => false,
          'message' => 'Validation failed',
          'errors' => ['Name is required']
        )
      end
    end

    context 'ActionController::ParameterMissing' do
      it 'handles missing parameter errors' do
        delete :destroy, params: { id: 1 }

        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)

        expect(body).to include(
          'success' => false,
          'message' => 'Missing required parameter: id'
        )
      end
    end
  end

  describe 'authentication' do
    context 'with valid token' do
      before do
        request.headers['Authorization'] = 'Bearer valid_token'
      end

      it 'authenticates successfully' do
        get :test_auth

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)

        expect(body).to include(
          'success' => true,
          'data' => { 'user' => 'authenticated' }
        )
      end
    end

    context 'with invalid token' do
      before do
        request.headers['Authorization'] = 'Bearer invalid_token'
      end

      it 'returns authentication error' do
        get :test_auth

        expect(response).to have_http_status(:unauthorized)
        body = JSON.parse(response.body)

        expect(body).to include(
          'success' => false,
          'message' => 'Authentication required'
        )
      end
    end

    context 'without token' do
      it 'returns authentication error' do
        get :test_auth

        expect(response).to have_http_status(:unauthorized)
        body = JSON.parse(response.body)

        expect(body).to include(
          'success' => false,
          'message' => 'Authentication required'
        )
      end
    end
  end

  describe 'token extraction' do
    it 'extracts token from Authorization header' do
      request.headers['Authorization'] = 'Bearer test_token_123'
      get :index

      expect(controller.send(:extract_token_from_header)).to eq('test_token_123')
    end

    it 'returns nil for invalid Authorization header format' do
      request.headers['Authorization'] = 'InvalidFormat token'
      get :index

      expect(controller.send(:extract_token_from_header)).to be_nil
    end

    it 'returns nil when Authorization header is missing' do
      get :index

      expect(controller.send(:extract_token_from_header)).to be_nil
    end
  end

  describe 'API version validation' do
    it 'validates supported versions' do
      expect(controller.send(:valid_api_version?, 'v1')).to be true
      expect(controller.send(:valid_api_version?, 'v2')).to be false
      expect(controller.send(:valid_api_version?, 'invalid')).to be false
    end
  end

  describe 'response metadata' do
    it 'includes timestamp in all responses' do
      freeze_time do
        get :index

        body = JSON.parse(response.body)
        expect(body['meta']['timestamp']).to eq(Time.current.iso8601)
      end
    end

    it 'includes API version in all responses' do
      get :index

      body = JSON.parse(response.body)
      expect(body['meta']['version']).to eq('v1')
    end
  end

  describe 'inheritance behavior' do
    it 'inherits from ApplicationController' do
      expect(Api::BaseController.superclass).to eq(ApplicationController)
    end

    it 'provides API-specific functionality' do
      expect(controller.class.ancestors).to include(Api::BaseController)
      expect(controller.class.ancestors).to include(ApplicationController)
    end
  end
end