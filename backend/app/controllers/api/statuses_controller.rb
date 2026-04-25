module Api
  class StatusesController < BaseController
    # GET /api/statuses
    # ステータスを position 昇順で返却。
    # api-design.md のレスポンス型 `Status[]` (camelCase) に準拠。
    def index
      statuses = Status.ordered
      render json: serialize_collection(statuses)
    end

    private

    # jsonapi-serializer は { data: [{ id, type, attributes: { ... } }] } 形式で返すが、
    # api-design.md は素朴な `[{ id, name, color, position }]` を要求している。
    # そのためここでフラットな配列に整形して返す。
    def serialize_collection(statuses)
      records = StatusSerializer.new(statuses).serializable_hash[:data]
      records.map do |record|
        record[:attributes].merge(id: record[:id].to_i)
      end
    end
  end
end
