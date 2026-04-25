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
end
