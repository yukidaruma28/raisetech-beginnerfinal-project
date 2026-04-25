module Api
  class PrioritiesController < BaseController
    # GET /api/priorities
    # 優先度を position 昇順で返却。Status と同じ縦串パターン。
    def index
      priorities = Priority.ordered
      render json: serialize_collection(priorities)
    end

    private

    # jsonapi-serializer は { data: [{ id, type, attributes: { ... } }] } 形式で返すため、
    # api-design.md が要求する `[{ id, name, level, color, position }]` に整形する。
    def serialize_collection(priorities)
      records = PrioritySerializer.new(priorities).serializable_hash[:data]
      records.map do |record|
        record[:attributes].merge(id: record[:id].to_i)
      end
    end
  end
end
