require 'rails_helper'

RSpec.describe 'Api::Statuses', type: :request do
  describe 'GET /api/statuses' do
    context 'when there are statuses' do
      let!(:in_progress) { create(:status, name: 'In Progress', color: '#F39C12', position: 2) }
      let!(:backlog)     { create(:status, name: 'Backlog',     color: '#95A5A6', position: 0) }
      let!(:todo)        { create(:status, name: 'Todo',        color: '#3498DB', position: 1) }

      before { get '/api/statuses' }

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON content type' do
        expect(response.content_type).to start_with('application/json')
      end

      it 'returns statuses ordered by position' do
        json = JSON.parse(response.body)
        expect(json.map { |s| s['name'] }).to eq([ 'Backlog', 'Todo', 'In Progress' ])
      end

      it 'returns camelCase keys with id, name, color, position' do
        json = JSON.parse(response.body)
        first = json.first
        expect(first.keys).to match_array(%w[id name color position])
        expect(first['id']).to eq(backlog.id)
        expect(first['name']).to eq('Backlog')
        expect(first['color']).to eq('#95A5A6')
        expect(first['position']).to eq(0)
      end
    end

    context 'when there are no statuses' do
      it 'returns an empty array' do
        get '/api/statuses'
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe 'POST /api/statuses' do
    context 'with valid params' do
      let(:body) { { name: 'カスタム', color: '#1ABC9C' } }

      it 'returns 201 Created' do
        post '/api/statuses', params: body, as: :json
        expect(response).to have_http_status(:created)
      end

      it 'persists a new Status' do
        expect {
          post '/api/statuses', params: body, as: :json
        }.to change(Status, :count).by(1)
      end

      it 'returns camelCase keys for the created record' do
        post '/api/statuses', params: body, as: :json
        json = JSON.parse(response.body)
        expect(json.keys).to match_array(%w[id name color position])
        expect(json['name']).to eq('カスタム')
        expect(json['color']).to eq('#1ABC9C')
      end

      it 'auto-numbers position to MAX(position)+1' do
        create(:status, name: 'A', color: '#FFFFFF', position: 0)
        create(:status, name: 'B', color: '#FFFFFF', position: 5)
        post '/api/statuses', params: body, as: :json
        expect(JSON.parse(response.body)['position']).to eq(6)
      end

      it 'starts position at 1 when no statuses exist yet' do
        post '/api/statuses', params: body, as: :json
        expect(JSON.parse(response.body)['position']).to eq(1)
      end
    end

    context 'when name is blank' do
      it 'returns 422 with details for the name field' do
        post '/api/statuses', params: { name: '', color: '#3498DB' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UNPROCESSABLE_ENTITY')
        fields = json['details'].map { |d| d['field'] }
        expect(fields).to include('name')
      end
    end

    context 'when name exceeds 100 characters' do
      it 'returns 422' do
        post '/api/statuses', params: { name: 'a' * 101, color: '#3498DB' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        fields = JSON.parse(response.body)['details'].map { |d| d['field'] }
        expect(fields).to include('name')
      end
    end

    context 'when color is not a valid hex' do
      it 'returns 422 for plain words' do
        post '/api/statuses', params: { name: 'New', color: 'red' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        fields = JSON.parse(response.body)['details'].map { |d| d['field'] }
        expect(fields).to include('color')
      end

      it 'returns 422 for short hex' do
        post '/api/statuses', params: { name: 'New', color: '#ZZZ' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when name key is missing' do
      it 'returns 400 with required reason' do
        post '/api/statuses', params: { color: '#3498DB' }, as: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('BAD_REQUEST')
        expect(json['details']).to include('field' => 'name', 'reason' => 'required')
      end
    end

    context 'when color key is missing' do
      it 'returns 400 with required reason' do
        post '/api/statuses', params: { name: 'NoColor' }, as: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('BAD_REQUEST')
        expect(json['details']).to include('field' => 'color', 'reason' => 'required')
      end
    end

    context 'when MAX_COUNT statuses already exist' do
      it 'returns 422 with base/max_count_exceeded' do
        Status::MAX_COUNT.times { |n| create(:status, name: "S#{n}", color: '#3498DB', position: n) }
        post '/api/statuses', params: { name: 'over', color: '#3498DB' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['details']).to include('field' => 'base', 'reason' => 'max_count_exceeded')
      end

      it 'still allows creation when count is exactly MAX_COUNT - 1' do
        (Status::MAX_COUNT - 1).times { |n| create(:status, name: "S#{n}", color: '#3498DB', position: n) }
        post '/api/statuses', params: { name: 'last', color: '#3498DB' }, as: :json
        expect(response).to have_http_status(:created)
      end
    end
  end
end
