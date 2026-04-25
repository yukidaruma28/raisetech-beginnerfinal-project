module Api
  class InquiriesController < BaseController
    # GET /api/inquiries
    # api-design.md のレスポンス型 `Inquiry[]` (camelCase, フラット) に準拠。
    # status を includes して N+1 を回避し、status_id → position の二段ソートで返す。
    def index
      inquiries = Inquiry.includes(:status, :priority).order(:status_id, :position, :id)
      render json: serialize_collection(inquiries)
    end

    # POST /api/inquiries
    # api-design.md の仕様:
    #   - statusId 必須 / title 必須
    #   - priorityId 省略時は「低」(level=3) を割り当てる
    #   - position は同 status 内の MAX(position)+1 を採番
    #   - 成功 201 / 単一レコードを camelCase で返す
    #   - status / priority 未存在 → 404、バリデーション違反 → 422
    def create
      attrs = create_params

      # statusId が無い場合は 400（先に弾く。Rails の belongs_to required では
      # 422 になるが、構文レベルの欠落として 400 で返すほうが docs/api-design.md と整合）。
      return render_bad_request(
        message: "statusId は必須です",
        details: [ { field: "statusId", reason: "required" } ]
      ) if attrs[:status_id].blank?

      status   = Status.find(attrs[:status_id])
      priority = resolve_priority(attrs[:priority_id])

      inquiry = Inquiry.new(
        status: status,
        priority: priority,
        title: attrs[:title],
        description: attrs[:description],
        position: next_position_for(status.id)
      )

      if inquiry.save
        render json: serialize_record(inquiry), status: :created
      else
        render_validation_error(inquiry)
      end
    end

    private

    # フロントは camelCase で送る（statusId / priorityId）ため、permit 後に
    # snake_case にして扱う。両形式（snake/camel）を許容することでテスト容易性も担保。
    def create_params
      raw = params.permit(:title, :description, :statusId, :priorityId, :status_id, :priority_id)
      {
        title: raw[:title],
        description: raw[:description],
        status_id: raw[:status_id].presence || raw[:statusId].presence,
        priority_id: raw[:priority_id].presence || raw[:priorityId].presence
      }
    end

    # priority_id 未指定の場合は「低」(level=3) を返す。指定があれば該当 id を引く。
    # 存在しない id を指定した場合は ActiveRecord::RecordNotFound 経由で 404。
    def resolve_priority(priority_id)
      if priority_id.present?
        Priority.find(priority_id)
      else
        Priority.find_by!(level: 3)
      end
    end

    # 同一 status 内の末尾に追加するため MAX(position)+1 を採番する。
    # シングルユーザー前提なのでロックは取らず楽観で済ませる
    # （並行作成時に重複しても position は UNIQUE 制約ではないため許容）。
    def next_position_for(status_id)
      Inquiry.where(status_id: status_id).maximum(:position).to_i + 1
    end

    # jsonapi-serializer は { data: [{ id, type, attributes: { ... } }] } 形式で返すため、
    # api-design.md が要求する `[{ id, statusId, title, ... }]` に整形する。
    # statuses_controller.rb と同じパターン。
    def serialize_collection(inquiries)
      records = InquirySerializer.new(inquiries).serializable_hash[:data]
      records.map { |record| flatten_serialized(record) }
    end

    # 単一レコード版。create のレスポンスで使う。
    def serialize_record(inquiry)
      record = InquirySerializer.new(inquiry).serializable_hash[:data]
      flatten_serialized(record)
    end

    def flatten_serialized(record)
      record[:attributes].merge(id: record[:id].to_i)
    end
  end
end
