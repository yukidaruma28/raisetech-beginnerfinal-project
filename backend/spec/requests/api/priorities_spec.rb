require 'rails_helper'

RSpec.describe 'Api::Priorities', type: :request do
  describe 'GET /api/priorities' do
    context 'when there are priorities' do
      let!(:medium) { create(:priority, level: 2, name: '中', color: '#F1C40F', position: 1) }
      let!(:high)   { create(:priority, level: 1, name: '高', color: '#E74C3C', position: 0) }
      let!(:low)    { create(:priority, level: 3, name: '低', color: '#3498DB', position: 2) }

      before { get '/api/priorities' }

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON content type' do
        expect(response.content_type).to start_with('application/json')
      end

      it 'returns priorities ordered by position' do
        json = JSON.parse(response.body)
        expect(json.map { |p| p['name'] }).to eq([ '高', '中', '低' ])
      end

      it 'returns camelCase keys with id, name, level, color, position' do
        json = JSON.parse(response.body)
        first = json.first
        expect(first.keys).to match_array(%w[id name level color position])
        expect(first['id']).to eq(high.id)
        expect(first['level']).to eq(1)
        expect(first['color']).to eq('#E74C3C')
      end
    end

    context 'when there are no priorities' do
      it 'returns an empty array' do
        get '/api/priorities'
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end
end
