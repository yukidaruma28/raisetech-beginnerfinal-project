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

    # PATCH /api/statuses/:id/move
    # body: { position: <1-indexed> }
    # Inquiry#move と同パターン（dense int 再採番、0-indexed で保存）。
    def move
      status = Status.find(params[:id])
      new_position = move_params[:position].to_i

      return render json: { error: "position is required" }, status: :bad_request unless new_position.positive?

      Status.transaction do
        others = Status.ordered.where.not(id: status.id).to_a
        others.insert(new_position - 1, status)
        others.each_with_index do |s, i|
          s.update_columns(position: i)
        end
      end

      render json: serialize_record(status.reload)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Not found" }, status: :not_found
    end

    # DELETE /api/statuses/:id?move_to=<other_status_id>
    # api-design.md の仕様:
    #   - 所属 Inquiry が無ければそのまま 204 で削除
    #   - 所属 Inquiry がある場合は `move_to` で指定した別ステータスへ全件付け替えてから削除
    #     - `move_to` 未指定 → 409 CONFLICT
    #     - `move_to` の status が未存在 → 404 NOT_FOUND（`field: 'moveTo'`）
    #     - `move_to == :id`（自身） → 422
    #   - 付け替え→削除は 1 トランザクションで実行（途中失敗で全 rollback）。
    def destroy
      status = Status.find(params[:id])

      if status.inquiries.exists?
        target = resolve_move_to_target(status)
        return if performed?

        Status.transaction do
          relocate_inquiries!(status, target)
          status.destroy!
        end
      else
        status.destroy!
      end

      head :no_content
    end

    private

    def move_params
      params.permit(:position)
    end

    # `move_to` クエリを検証して移動先 Status を返す。
    # 不正値の場合は適切なエラーレスポンスを返却して nil を返す（呼び出し側で `performed?` を見る）。
    def resolve_move_to_target(status)
      raw = params[:move_to]

      if raw.blank?
        render_conflict(
          message: "所属する問い合わせがあるため、移動先ステータスを指定してください",
          details: [ { field: "moveTo", reason: "required_when_inquiries_exist" } ]
        )
        return nil
      end

      move_to_id = Integer(raw, 10) rescue nil
      if move_to_id.nil?
        render_bad_request(
          message: "move_to は整数で指定してください",
          details: [ { field: "moveTo", reason: "must_be_integer" } ]
        )
        return nil
      end

      if move_to_id == status.id
        render_validation_error_for_self_move
        return nil
      end

      target = Status.find_by(id: move_to_id)
      if target.nil?
        render_not_found(field: "moveTo", message: "移動先のステータスが見つかりません")
        return nil
      end

      target
    end

    # 422 を直接返すケース（model validation ではないので render_validation_error は使えない）。
    def render_validation_error_for_self_move
      render json: {
        error: "UNPROCESSABLE_ENTITY",
        message: "自分自身は移動先に指定できません",
        details: [ { field: "moveTo", reason: "cannot_move_to_self" } ]
      }, status: :unprocessable_entity
    end

    # 削除対象 status の所属 Inquiry を target へ全件付け替えた上で、
    # target 内の position を 1, 2, 3, ... に dense int で再採番する。
    # InquiriesController#move と同じ詰め方ロジックを踏襲。
    def relocate_inquiries!(status, target)
      base_position = Inquiry.where(status_id: target.id).maximum(:position).to_i
      status.inquiries.order(:position, :id).each_with_index do |inquiry, i|
        inquiry.update_columns(status_id: target.id, position: base_position + i + 1)
      end
      siblings = Inquiry.where(status_id: target.id).order(:position, :id).to_a
      renumber!(siblings)
    end

    # 渡された配列の順番で position を 1, 2, 3, ... に詰める。
    # InquiriesController#renumber! と同一ロジック。位置整合のためだけの小さい
    # private メソッドなのでモデルへ切り出さずコントローラ内に同居させる。
    def renumber!(records)
      records.each_with_index do |record, i|
        new_position = i + 1
        record.update_columns(position: new_position) if record.position != new_position
      end
    end

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
