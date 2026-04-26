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

  describe 'DELETE /api/statuses/:id' do
    context 'when the status has no inquiries' do
      let!(:status) { create(:status, name: 'Empty', color: '#3498DB', position: 0) }

      it 'returns 204 No Content' do
        delete "/api/statuses/#{status.id}"
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it 'removes the record from the database' do
        expect { delete "/api/statuses/#{status.id}" }
          .to change(Status, :count).by(-1)
      end

      it 'no longer appears in GET /api/statuses' do
        delete "/api/statuses/#{status.id}"
        get '/api/statuses'
        ids = JSON.parse(response.body).map { |s| s['id'] }
        expect(ids).not_to include(status.id)
      end

      it 'ignores move_to query when there are no inquiries' do
        other = create(:status, name: 'Other', color: '#FFFFFF', position: 1)
        delete "/api/statuses/#{status.id}", params: { move_to: other.id }
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when the status does not exist' do
      it 'returns 404 NOT_FOUND' do
        delete '/api/statuses/999999'
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('NOT_FOUND')
      end
    end

    context 'when the status has inquiries and move_to is omitted' do
      let!(:priority) { create(:priority, level: 3) }
      let!(:source)   { create(:status, name: 'Source', color: '#3498DB', position: 0) }
      let!(:inquiry)  { create(:inquiry, status: source, priority: priority, position: 1) }

      it 'returns 409 CONFLICT' do
        delete "/api/statuses/#{source.id}"
        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('CONFLICT')
        expect(json['details']).to include('field' => 'moveTo', 'reason' => 'required_when_inquiries_exist')
      end

      it 'leaves the status and the inquiry untouched' do
        delete "/api/statuses/#{source.id}"
        expect(Status.exists?(source.id)).to be true
        expect(Inquiry.find(inquiry.id).status_id).to eq(source.id)
      end
    end

    context 'when move_to references a non-existent status' do
      let!(:priority) { create(:priority, level: 3) }
      let!(:source)   { create(:status, name: 'Source', color: '#3498DB', position: 0) }
      let!(:inquiry)  { create(:inquiry, status: source, priority: priority, position: 1) }

      it 'returns 404 NOT_FOUND with field=moveTo' do
        delete "/api/statuses/#{source.id}", params: { move_to: 999_999 }
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('NOT_FOUND')
        expect(json['details']).to include('field' => 'moveTo', 'reason' => 'not_found')
      end

      it 'leaves the source status and inquiry intact' do
        delete "/api/statuses/#{source.id}", params: { move_to: 999_999 }
        expect(Status.exists?(source.id)).to be true
        expect(Inquiry.find(inquiry.id).status_id).to eq(source.id)
      end
    end

    context 'when move_to equals the status itself' do
      let!(:priority) { create(:priority, level: 3) }
      let!(:source)   { create(:status, name: 'Source', color: '#3498DB', position: 0) }
      let!(:inquiry)  { create(:inquiry, status: source, priority: priority, position: 1) }

      it 'returns 422 UNPROCESSABLE_ENTITY with cannot_move_to_self' do
        delete "/api/statuses/#{source.id}", params: { move_to: source.id }
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UNPROCESSABLE_ENTITY')
        expect(json['details']).to include('field' => 'moveTo', 'reason' => 'cannot_move_to_self')
      end
    end

    context 'when relocating inquiries to a valid move_to' do
      let!(:priority) { create(:priority, level: 3) }
      let!(:source)   { create(:status, name: 'Source', color: '#3498DB', position: 0) }
      let!(:target)   { create(:status, name: 'Target', color: '#FFFFFF', position: 1) }
      let!(:source_inq_a) { create(:inquiry, status: source, priority: priority, title: 'A', position: 1) }
      let!(:source_inq_b) { create(:inquiry, status: source, priority: priority, title: 'B', position: 2) }

      it 'returns 204 No Content and deletes the source status' do
        delete "/api/statuses/#{source.id}", params: { move_to: target.id }
        expect(response).to have_http_status(:no_content)
        expect(Status.exists?(source.id)).to be false
      end

      it 'reassigns all inquiries to the target status' do
        delete "/api/statuses/#{source.id}", params: { move_to: target.id }
        expect(Inquiry.find(source_inq_a.id).status_id).to eq(target.id)
        expect(Inquiry.find(source_inq_b.id).status_id).to eq(target.id)
      end

      it 'renumbers target inquiries densely starting from 1' do
        delete "/api/statuses/#{source.id}", params: { move_to: target.id }
        positions = Inquiry.where(status_id: target.id).order(:position, :id).pluck(:position)
        expect(positions).to eq([ 1, 2 ])
      end

      context 'when the target already has inquiries' do
        let!(:target_inq_x) { create(:inquiry, status: target, priority: priority, title: 'X', position: 1) }
        let!(:target_inq_y) { create(:inquiry, status: target, priority: priority, title: 'Y', position: 2) }

        it 'appends moved inquiries after existing ones with dense positions 1..N+M' do
          delete "/api/statuses/#{source.id}", params: { move_to: target.id }
          rows = Inquiry.where(status_id: target.id).order(:position, :id).pluck(:title, :position)
          expect(rows).to eq([
            [ 'X', 1 ],
            [ 'Y', 2 ],
            [ 'A', 3 ],
            [ 'B', 4 ]
          ])
        end
      end
    end
  end

  describe 'PATCH /api/statuses/:id/move' do
    let!(:s1) { create(:status, name: 'Backlog',     color: '#95A5A6', position: 0) }
    let!(:s2) { create(:status, name: 'Todo',        color: '#3498DB', position: 1) }
    let!(:s3) { create(:status, name: 'In Progress', color: '#F39C12', position: 2) }

    context 'with a valid position' do
      it 'returns 200' do
        patch "/api/statuses/#{s1.id}/move", params: { position: 3 }, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns the moved status as a flat JSON object' do
        patch "/api/statuses/#{s1.id}/move", params: { position: 3 }, as: :json
        json = JSON.parse(response.body)
        expect(json.keys).to match_array(%w[id name color position])
        expect(json['id']).to eq(s1.id)
      end

      it 'reorders statuses correctly when moving to the end' do
        patch "/api/statuses/#{s1.id}/move", params: { position: 3 }, as: :json
        names = Status.ordered.pluck(:name)
        expect(names).to eq([ 'Todo', 'In Progress', 'Backlog' ])
      end

      it 'reorders statuses correctly when moving to the beginning' do
        patch "/api/statuses/#{s3.id}/move", params: { position: 1 }, as: :json
        names = Status.ordered.pluck(:name)
        expect(names).to eq([ 'In Progress', 'Backlog', 'Todo' ])
      end

      it 'reorders statuses correctly when moving to the middle' do
        patch "/api/statuses/#{s3.id}/move", params: { position: 2 }, as: :json
        names = Status.ordered.pluck(:name)
        expect(names).to eq([ 'Backlog', 'In Progress', 'Todo' ])
      end

      it 'renumbers all positions as dense 0-indexed integers' do
        patch "/api/statuses/#{s1.id}/move", params: { position: 3 }, as: :json
        positions = Status.ordered.pluck(:position)
        expect(positions).to eq([ 0, 1, 2 ])
      end
    end

    context 'when position is missing' do
      it 'returns 400' do
        patch "/api/statuses/#{s1.id}/move", params: {}, as: :json
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when the status does not exist' do
      it 'returns 404' do
        patch '/api/statuses/999999/move', params: { position: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
