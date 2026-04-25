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
        expect(json.map { |i| i['title'] }).to eq([ 'Backlog 0', 'Todo 0', 'Todo 1' ])
      end

      it 'returns camelCase keys with id, statusId, priorityId, title, description, position, createdAt, updatedAt' do
        json = JSON.parse(response.body)
        first = json.first
        expect(first.keys).to match_array(%w[id statusId priorityId title description position createdAt updatedAt])
        expect(first['id']).to eq(i_backlog_0.id)
        expect(first['statusId']).to eq(backlog.id)
        expect(first['title']).to eq('Backlog 0')
        expect(first['position']).to eq(0)
      end

      it 'always returns a non-null priorityId (priority is required)' do
        json = JSON.parse(response.body)
        json.each do |inquiry|
          expect(inquiry['priorityId']).not_to be_nil, "inquiry #{inquiry['id']} should have priority"
        end
      end

      it 'returns the assigned priorityId' do
        # 既存 priority（level=1, factory のデフォルト）以外を別 level で作成
        explicit_priority = create(:priority, level: 2, name: '中', color: '#F1C40F', position: 1)
        with_priority = create(:inquiry, status: backlog, title: 'With priority', position: 99, priority: explicit_priority)

        get '/api/inquiries'
        json = JSON.parse(response.body)
        target = json.find { |i| i['id'] == with_priority.id }
        expect(target).not_to be_nil
        expect(target['priorityId']).to eq(explicit_priority.id)
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

  describe 'POST /api/inquiries' do
    let!(:todo)        { create(:status, name: 'Todo', color: '#3498DB', position: 0) }
    let!(:high)        { create(:priority, level: 1, name: '高', color: '#E74C3C', position: 0) }
    let!(:medium)      { create(:priority, level: 2, name: '中', color: '#F1C40F', position: 1) }
    let!(:low)         { create(:priority, level: 3, name: '低', color: '#3498DB', position: 2) }

    context 'with valid camelCase params' do
      let(:body) do
        { statusId: todo.id, priorityId: medium.id, title: '新規問い合わせ', description: '本文' }
      end

      it 'returns 201 Created' do
        post '/api/inquiries', params: body, as: :json
        expect(response).to have_http_status(:created)
      end

      it 'persists a new Inquiry' do
        expect {
          post '/api/inquiries', params: body, as: :json
        }.to change(Inquiry, :count).by(1)
      end

      it 'returns camelCase keys for the created record' do
        post '/api/inquiries', params: body, as: :json
        json = JSON.parse(response.body)
        expect(json.keys).to match_array(%w[id statusId priorityId title description position createdAt updatedAt])
        expect(json['statusId']).to eq(todo.id)
        expect(json['priorityId']).to eq(medium.id)
        expect(json['title']).to eq('新規問い合わせ')
      end

      it 'auto-numbers position to MAX(position)+1 within the status' do
        create(:inquiry, status: todo, priority: low, position: 5, title: 'existing')
        post '/api/inquiries', params: body, as: :json
        expect(JSON.parse(response.body)['position']).to eq(6)
      end

      it 'starts position at 1 when no inquiries exist in the status' do
        post '/api/inquiries', params: body, as: :json
        expect(JSON.parse(response.body)['position']).to eq(1)
      end
    end

    context 'when priorityId is omitted' do
      it 'defaults to the "低" (level=3) priority' do
        post '/api/inquiries',
             params: { statusId: todo.id, title: '優先度省略' },
             as: :json
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['priorityId']).to eq(low.id)
      end
    end

    context 'when description is omitted' do
      it 'creates an inquiry with null description' do
        post '/api/inquiries',
             params: { statusId: todo.id, title: '本文なし' },
             as: :json
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['description']).to be_nil
      end
    end

    context 'when title is blank' do
      it 'returns 422 with details for the title field' do
        post '/api/inquiries',
             params: { statusId: todo.id, title: '' },
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UNPROCESSABLE_ENTITY')
        fields = json['details'].map { |d| d['field'] }
        expect(fields).to include('title')
      end
    end

    context 'when title exceeds 255 characters' do
      it 'returns 422' do
        post '/api/inquiries',
             params: { statusId: todo.id, title: 'a' * 256 },
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when statusId is missing' do
      it 'returns 400 with details for statusId' do
        post '/api/inquiries', params: { title: 'test' }, as: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('BAD_REQUEST')
        expect(json['details'].first).to include('field' => 'statusId', 'reason' => 'required')
      end
    end

    context 'when statusId does not exist' do
      it 'returns 404' do
        post '/api/inquiries',
             params: { statusId: 999_999, title: 'test' },
             as: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('NOT_FOUND')
      end
    end

    context 'when priorityId does not exist' do
      it 'returns 404' do
        post '/api/inquiries',
             params: { statusId: todo.id, priorityId: 999_999, title: 'test' },
             as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with snake_case params (backwards compatible)' do
      it 'accepts status_id / priority_id keys as well' do
        post '/api/inquiries',
             params: { status_id: todo.id, priority_id: medium.id, title: 'snake' },
             as: :json
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['statusId']).to eq(todo.id)
      end
    end
  end

  describe 'PATCH /api/inquiries/:id' do
    let!(:backlog) { create(:status, name: 'Backlog', color: '#95A5A6', position: 0) }
    let!(:todo)    { create(:status, name: 'Todo',    color: '#3498DB', position: 1) }
    let!(:high)    { create(:priority, level: 1, name: '高', color: '#E74C3C', position: 0) }
    let!(:medium)  { create(:priority, level: 2, name: '中', color: '#F1C40F', position: 1) }
    let!(:low)     { create(:priority, level: 3, name: '低', color: '#3498DB', position: 2) }
    let!(:inquiry) do
      create(:inquiry, status: backlog, priority: low,
                       title: '元のタイトル', description: '元の本文', position: 5)
    end

    context 'with valid title-only patch (camelCase)' do
      it 'returns 200 and updates only title' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { title: '更新後タイトル' }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['title']).to eq('更新後タイトル')
        expect(json['description']).to eq('元の本文')
        expect(json['statusId']).to eq(backlog.id)
        expect(json['priorityId']).to eq(low.id)
        expect(json['position']).to eq(5)
      end
    end

    context 'with description-only patch' do
      it 'updates description and leaves other fields' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { description: '新しい本文' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['description']).to eq('新しい本文')
        expect(inquiry.reload.title).to eq('元のタイトル')
      end

      it 'allows clearing description by sending empty string' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { description: '' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(inquiry.reload.description).to eq('')
      end
    end

    context 'with statusId-only patch' do
      it 'changes status without changing position' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { statusId: todo.id }, as: :json
        expect(response).to have_http_status(:ok)
        expect(inquiry.reload.status_id).to eq(todo.id)
        expect(inquiry.position).to eq(5)
      end
    end

    context 'with priorityId-only patch' do
      it 'changes priority' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { priorityId: high.id }, as: :json
        expect(response).to have_http_status(:ok)
        expect(inquiry.reload.priority_id).to eq(high.id)
      end
    end

    context 'with all fields patched' do
      it 'updates everything atomically' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { title: 't', description: 'd', statusId: todo.id, priorityId: medium.id },
              as: :json
        expect(response).to have_http_status(:ok)
        inquiry.reload
        expect(inquiry.title).to eq('t')
        expect(inquiry.description).to eq('d')
        expect(inquiry.status_id).to eq(todo.id)
        expect(inquiry.priority_id).to eq(medium.id)
      end
    end

    context 'when title is blank' do
      it 'returns 422 with title detail' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { title: '' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('UNPROCESSABLE_ENTITY')
        fields = json['details'].map { |d| d['field'] }
        expect(fields).to include('title')
      end
    end

    context 'when title exceeds 255 characters' do
      it 'returns 422' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { title: 'a' * 256 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when statusId does not exist' do
      it 'returns 404' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { statusId: 999_999 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when priorityId does not exist' do
      it 'returns 404' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { priorityId: 999_999 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when inquiry id does not exist' do
      it 'returns 404' do
        patch '/api/inquiries/999999',
              params: { title: 'x' }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with snake_case params' do
      it 'accepts status_id / priority_id keys' do
        patch "/api/inquiries/#{inquiry.id}",
              params: { status_id: todo.id, priority_id: medium.id }, as: :json
        expect(response).to have_http_status(:ok)
        inquiry.reload
        expect(inquiry.status_id).to eq(todo.id)
        expect(inquiry.priority_id).to eq(medium.id)
      end
    end

    context 'with empty body' do
      it 'leaves all fields unchanged and returns 200' do
        patch "/api/inquiries/#{inquiry.id}", params: {}, as: :json
        expect(response).to have_http_status(:ok)
        inquiry.reload
        expect(inquiry.title).to eq('元のタイトル')
        expect(inquiry.description).to eq('元の本文')
      end
    end
  end
end
