module Api
  class StatusesController < BaseController
    # GET /api/statuses
    # ステータスを position 昇順で返却。
    # api-design.md のレスポンス型 `Status[]` (camelCase) に準拠。
    def index
      statuses = Status.ordered
      render json: serialize_collection(statuses)
    end

    # POST /api/statuses
    # api-design.md の仕様:
    #   - name / color 必須
    #   - position は MAX(position) + 1 を採番（既存の Inquiry と同じパターン）
    #   - 上限は Status::MAX_COUNT 件（モデル側 within_max_count で 422）
    #   - 成功 201 / 単一レコードを camelCase で返す
    #   - バリデーション違反 → 422 / 必須キー欠落 → 400
    def create
      # 「キーが送られていない」(400) と 「送られたが空文字」(422 = model validation)
      # を区別する。Inquiry の statusId 同様、構文レベルの欠落だけ 400 で先に弾く。
      return render_bad_request(
        message: "name は必須です",
        details: [ { field: "name", reason: "required" } ]
      ) unless params.key?(:name)

      return render_bad_request(
        message: "color は必須です",
        details: [ { field: "color", reason: "required" } ]
      ) unless params.key?(:color)

      attrs = normalized_create_params

      status = Status.new(
        name: attrs[:name],
        color: attrs[:color],
        position: next_position
      )

      if status.save
        render json: serialize_record(status), status: :created
      else
        render_validation_error(status)
      end
    end

    private

    # POST 用の正規化。名前と色のみを permit する。
    # キー有無の判定は呼び出し側の `params.key?` で済ませているため、
    # ここはシンプルに値を取り出すだけ。
    def normalized_create_params
      raw = params.permit(:name, :color)
      { name: raw[:name], color: raw[:color] }
    end

    # ステータス全体の末尾に追加するため MAX(position) + 1 を採番する。
    # Inquiry と違い status_id でグループ化しないグローバル MAX。
    # シングルユーザー前提のためロックは取らず楽観で済ませる。
    def next_position
      Status.maximum(:position).to_i + 1
    end

    # jsonapi-serializer は { data: [{ id, type, attributes: { ... } }] } 形式で返すが、
    # api-design.md は素朴な `[{ id, name, color, position }]` を要求している。
    # そのためここでフラットな配列に整形して返す。
    def serialize_collection(statuses)
      records = StatusSerializer.new(statuses).serializable_hash[:data]
      records.map { |record| flatten_serialized(record) }
    end

    # 単一レコード版。create のレスポンスで使う。
    def serialize_record(status)
      record = StatusSerializer.new(status).serializable_hash[:data]
      flatten_serialized(record)
    end

    def flatten_serialized(record)
      record[:attributes].merge(id: record[:id].to_i)
    end
  end
end
