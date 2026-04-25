module Api
  class InquiriesController < BaseController
    # GET /api/inquiries
    # api-design.md のレスポンス型 `Inquiry[]` (camelCase, フラット) に準拠。
    # status を includes して N+1 を回避し、status_id → position の二段ソートで返す。
    def index
      inquiries = Inquiry.includes(:status, :priority).order(:status_id, :position, :id)
      render json: serialize_collection(inquiries)
    end

    private

    # jsonapi-serializer は { data: [{ id, type, attributes: { ... } }] } 形式で返すため、
    # api-design.md が要求する `[{ id, statusId, title, ... }]` に整形する。
    # statuses_controller.rb と同じパターン。
    def serialize_collection(inquiries)
      records = InquirySerializer.new(inquiries).serializable_hash[:data]
      records.map do |record|
        record[:attributes].merge(id: record[:id].to_i)
      end
    end
  end
end
