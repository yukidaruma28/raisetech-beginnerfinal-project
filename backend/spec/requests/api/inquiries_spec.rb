require 'rails_helper'

RSpec.describe 'Api::Inquiries', type: :request do
  describe 'GET /api/inquiries' do
    context 'when there are inquiries' do
      let!(:backlog) { create(:status, name: 'Backlog', color: '#95A5A6', position: 0) }
      let!(:todo)    { create(:status, name: 'Todo',    color: '#3498DB', position: 1) }

      let!(:i_todo_1)    { create(:inquiry, status: todo,    title: 'Todo 1',    position: 1) }
      let!(:i_backlog_0) { create(:inquiry, status: backlog, title: 'Backlog 0', position: 0) }
      let!(:i_todo_0)    { create(:inquiry, status: todo,    title: 'Todo 0',    position: 0) }

      before { get '/api/inquiries' }

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON content type' do
        expect(response.content_type).to start_with('application/json')
      end

      it 'returns inquiries ordered by status_id then position' do
        json = JSON.parse(response.body)
        expect(json.map { |i| i['title'] }).to eq(['Backlog 0', 'Todo 0', 'Todo 1'])
      end

      it 'returns camelCase keys with id, statusId, title, description, position, createdAt, updatedAt' do
        json = JSON.parse(response.body)
        first = json.first
        expect(first.keys).to match_array(%w[id statusId title description position createdAt updatedAt])
        expect(first['id']).to eq(i_backlog_0.id)
        expect(first['statusId']).to eq(backlog.id)
        expect(first['title']).to eq('Backlog 0')
        expect(first['position']).to eq(0)
      end
    end

    context 'when there are no inquiries' do
      it 'returns an empty array' do
        get '/api/inquiries'
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'expected count after seeding-like setup' do
      it 'returns 10 records when 10 are created' do
        status = create(:status, name: 'Backlog', position: 0)
        10.times { |n| create(:inquiry, status: status, position: n, title: "Inq #{n}") }

        get '/api/inquiries'
        expect(JSON.parse(response.body).size).to eq(10)
      end
    end
  end
end
