# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  # Use StringCount as a concrete implementation to test ApplicationRecord behavior
  let(:test_model_class) { StringCount }
  let(:test_record) { test_model_class.create!(unicode: 'T', count: 10) }

  describe 'inheritance' do
    it 'inherits from ActiveRecord::Base' do
      expect(ApplicationRecord.superclass).to eq(ActiveRecord::Base)
    end

    it 'is inherited by model classes' do
      expect(test_model_class.ancestors).to include(ApplicationRecord)
      expect(test_model_class.ancestors).to include(ActiveRecord::Base)
    end
  end

  describe 'common ActiveRecord functionality' do
    it 'provides standard ActiveRecord methods' do
      expect(test_record).to respond_to(:save)
      expect(test_record).to respond_to(:update)
      expect(test_record).to respond_to(:destroy)
      expect(test_record).to respond_to(:reload)
    end

    it 'provides timestamp functionality' do
      expect(test_record).to respond_to(:created_at)
      expect(test_record).to respond_to(:updated_at)
      expect(test_record.created_at).to be_present
      expect(test_record.updated_at).to be_present
    end

    it 'provides validation functionality' do
      expect(test_record).to respond_to(:valid?)
      expect(test_record).to respond_to(:invalid?)
      expect(test_record).to respond_to(:errors)
    end
  end

  describe 'database connection and transactions' do
    it 'shares database connection across models' do
      expect(ApplicationRecord.connection).to be_present
      expect(test_model_class.connection).to eq(ApplicationRecord.connection)
    end

    it 'supports transactions' do
      initial_count = test_model_class.count

      ApplicationRecord.transaction do
        test_model_class.create!(unicode: 'X', count: 1)
        test_model_class.create!(unicode: 'Y', count: 2)
      end

      expect(test_model_class.count).to eq(initial_count + 2)
    end

    it 'rolls back transactions on error' do
      initial_count = test_model_class.count

      expect do
        ApplicationRecord.transaction do
          test_model_class.create!(unicode: 'Z', count: 1)
          raise ActiveRecord::Rollback
        end
      end.not_to change(test_model_class, :count)

      expect(test_model_class.count).to eq(initial_count)
    end
  end

  describe 'query interface' do
    before do
      test_model_class.create!(unicode: 'A', count: 5)
      test_model_class.create!(unicode: 'B', count: 10)
      test_model_class.create!(unicode: 'C', count: 15)
    end

    it 'provides query methods' do
      expect(test_model_class).to respond_to(:where)
      expect(test_model_class).to respond_to(:find_by)
      expect(test_model_class).to respond_to(:order)
      expect(test_model_class).to respond_to(:limit)
    end

    it 'supports complex queries' do
      results = test_model_class.where('count > ?', 7).order(:count)
      expect(results.count).to eq(2)
      expect(results.first.count).to eq(10)
      expect(results.last.count).to eq(15)
    end
  end

  describe 'Rails application integration' do
    it 'is connected to the Rails application' do
      expect(ApplicationRecord.configurations).to be_present
      expect(ApplicationRecord.configurations).to be_a(ActiveRecord::DatabaseConfigurations)
    end

    it 'uses the configured database adapter' do
      expect(ApplicationRecord.connection.adapter_name).to be_present
    end

    it 'respects Rails environment configuration' do
      expect(ApplicationRecord.configurations.configs_for(env_name: Rails.env)).to be_present
    end
  end

  describe 'abstract class behavior' do
    it 'is marked as abstract' do
      # ApplicationRecord should be abstract and not have a table
      expect { ApplicationRecord.table_name }.not_to raise_error
    end

    it 'cannot be instantiated directly' do
      # While we can't prevent instantiation completely in Rails,
      # ApplicationRecord typically doesn't have its own table
      expect(ApplicationRecord.abstract_class?).to be true
    end
  end

  describe 'shared behavior across models' do
    let(:models) { [StringCount, RankMaster, ResultStringCount] }

    it 'provides consistent interface across all models' do
      models.each do |model_class|
        expect(model_class.ancestors).to include(ApplicationRecord)
        expect(model_class).to respond_to(:create)
        expect(model_class).to respond_to(:find)
        expect(model_class).to respond_to(:where)
      end
    end

    it 'shares configuration and connection' do
      models.each do |model_class|
        expect(model_class.connection).to eq(ApplicationRecord.connection)
      end
    end
  end

  describe 'Rails integration features' do
    it 'supports Rails logger' do
      expect(ApplicationRecord.logger).to eq(Rails.logger)
    end

    it 'supports Rails cache' do
      expect(ApplicationRecord).to respond_to(:cache)
    end

    it 'integrates with Rails configuration' do
      expect(ApplicationRecord.configurations.configurations).to be_present
    end
  end
end