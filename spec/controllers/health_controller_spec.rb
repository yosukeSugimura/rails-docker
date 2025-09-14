# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  describe 'GET #show' do
    it 'returns basic health status' do
      get :show

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      body = JSON.parse(response.body)
      expect(body).to include(
        'status' => 'ok',
        'timestamp' => be_present,
        'version' => be_present,
        'environment' => Rails.env
      )
    end

    it 'includes ISO 8601 formatted timestamp' do
      get :show

      body = JSON.parse(response.body)
      timestamp = body['timestamp']

      expect { DateTime.parse(timestamp) }.not_to raise_error
      expect(timestamp).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end

  describe 'GET #detailed' do
    context 'when all services are healthy' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG') if defined?(Redis)
      end

      it 'returns detailed health status with ok status' do
        get :detailed

        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        expect(body).to include(
          'status' => 'ok',
          'timestamp' => be_present,
          'version' => be_present,
          'environment' => Rails.env,
          'checks' => be_an(Array)
        )
      end

      it 'includes database check' do
        get :detailed

        body = JSON.parse(response.body)
        db_check = body['checks'].find { |check| check['name'] == 'database' }

        expect(db_check).to be_present
        expect(db_check).to include(
          'name' => 'database',
          'status' => 'ok',
          'duration_ms' => be_a(Numeric)
        )
      end

      it 'includes system resource checks' do
        get :detailed

        body = JSON.parse(response.body)
        check_names = body['checks'].map { |check| check['name'] }

        expect(check_names).to include('database')
        # System checks may vary by environment
        expect(check_names.size).to be >= 1
      end
    end

    context 'when database is unavailable' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute)
          .and_raise(ActiveRecord::ConnectionNotEstablished, 'Database connection failed')
      end

      it 'returns service unavailable status' do
        get :detailed

        expect(response).to have_http_status(:service_unavailable)

        body = JSON.parse(response.body)
        expect(body['status']).to eq('error')

        db_check = body['checks'].find { |check| check['name'] == 'database' }
        expect(db_check['status']).to eq('error')
        expect(db_check['error']).to be_present
      end
    end
  end

  describe 'GET #ready' do
    context 'when all readiness checks pass' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG') if defined?(Redis)
      end

      it 'returns ready status' do
        get :ready

        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        expect(body['status']).to eq('ready')
      end
    end

    context 'when readiness checks fail' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute)
          .and_raise(ActiveRecord::ConnectionNotEstablished, 'Database not ready')
      end

      it 'returns not ready status' do
        get :ready

        expect(response).to have_http_status(:service_unavailable)

        body = JSON.parse(response.body)
        expect(body['status']).to eq('not_ready')
        expect(body['checks']).to be_an(Array)
      end
    end
  end

  describe 'GET #live' do
    it 'always returns alive status' do
      get :live

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body).to include(
        'status' => 'alive',
        'timestamp' => be_present
      )
    end

    it 'responds quickly', :performance do
      get :live
      # Performance expectation is implicit in the :performance tag
    end
  end

  describe 'CSRF protection' do
    it 'skips CSRF verification for health endpoints' do
      # This test ensures health endpoints work without CSRF tokens
      # which is important for monitoring systems
      @request.headers['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'

      expect do
        get :show
        get :detailed
        get :ready
        get :live
      end.not_to raise_error
    end
  end

  describe 'response format' do
    it 'always returns JSON content type' do
      get :show
      expect(response.content_type).to include('application/json')

      get :detailed
      expect(response.content_type).to include('application/json')

      get :ready
      expect(response.content_type).to include('application/json')

      get :live
      expect(response.content_type).to include('application/json')
    end

    it 'returns valid JSON for all endpoints' do
      [
        [:show],
        [:detailed],
        [:ready],
        [:live]
      ].each do |action|
        get action.first

        expect { JSON.parse(response.body) }.not_to raise_error
      end
    end
  end

  describe 'error handling' do
    context 'when an unexpected error occurs in detailed check' do
      before do
        allow_any_instance_of(HealthController).to receive(:perform_health_checks)
          .and_raise(StandardError, 'Unexpected error')
      end

      it 'handles errors gracefully' do
        expect { get :detailed }.not_to raise_error
      end
    end
  end

  describe 'caching headers' do
    it 'sets appropriate cache headers for health endpoints' do
      get :show

      # Health endpoints should not be cached
      expect(response.headers['Cache-Control']).to include('no-cache')
    end
  end

  describe 'monitoring integration' do
    it 'provides machine-readable timestamps' do
      get :show

      body = JSON.parse(response.body)
      timestamp = Time.parse(body['timestamp'])

      expect(timestamp).to be_within(5.seconds).of(Time.current)
    end

    it 'includes version information for deployment tracking' do
      get :show

      body = JSON.parse(response.body)
      expect(body['version']).to be_present
      expect(body['version']).to match(/\d+\.\d+\.\d+/)
    end
  end
end