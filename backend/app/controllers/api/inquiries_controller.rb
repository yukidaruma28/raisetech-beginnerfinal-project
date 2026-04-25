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
      attrs = normalized_params

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

    # PATCH /api/inquiries/:id
    # 部分更新。送信されたフィールドだけを update する（送られていないフィールドは触らない）。
    # status_id 変更時の position 再計算は UC-05（DnD 移動）で行う。ここでは position 据え置き。
    def update
      inquiry = Inquiry.find(params[:id])
      attrs = normalized_params

      # 存在しない status_id / priority_id を指定された場合は 404 で先に弾く。
      # （Inquiry#update が belongs_to required で 422 を返すケースもあるが、
      #  「対象リソースが見つからない」ほうが意味的に近いため 404 とする）
      Status.find(attrs[:status_id])     if attrs[:status_id].present?
      Priority.find(attrs[:priority_id]) if attrs[:priority_id].present?

      if inquiry.update(attrs)
        render json: serialize_record(inquiry)
      else
        render_validation_error(inquiry)
      end
    end

    # DELETE /api/inquiries/:id
    # 物理削除。シングルユーザー前提のためソフトデリートは導入しない。
    # 未存在 id は ActiveRecord::RecordNotFound 経由で 404（BaseController で整形）。
    # 成功時は 204 No Content（body なし）。
    def destroy
      inquiry = Inquiry.find(params[:id])
      inquiry.destroy!
      head :no_content
    end

    # PATCH /api/inquiries/:id/move
    # DnD 用エンドポイント。statusId（移動先）と position（1-indexed）を受け取り、
    # トランザクション内で影響を受ける status の inquiries を dense int で再採番する。
    # 列をまたぐ移動の場合は元 status / 新 status の双方を 1, 2, 3, ... に詰める。
    def move
      inquiry = Inquiry.find(params[:id])
      attrs = move_params

      return render_bad_request(
        message: "statusId は必須です",
        details: [ { field: "statusId", reason: "required" } ]
      ) if attrs[:status_id].blank?

      return render_bad_request(
        message: "position は必須です",
        details: [ { field: "position", reason: "required" } ]
      ) if attrs[:position].blank?

      target_position = attrs[:position].to_i
      return render_bad_request(
        message: "position は 1 以上で指定してください",
        details: [ { field: "position", reason: "must_be_positive" } ]
      ) if target_position < 1

      target_status = Status.find(attrs[:status_id])

      Inquiry.transaction do
        old_status_id = inquiry.status_id

        if old_status_id != target_status.id
          inquiry.update!(status_id: target_status.id)
        end

        # 移動先 status の siblings（自分以外）を position 順で取得し、
        # target_position の位置に挿入してから dense int で 1 から再採番する。
        siblings = Inquiry
          .where(status_id: target_status.id)
          .where.not(id: inquiry.id)
          .order(:position, :id)
          .to_a
        insert_index = [ target_position - 1, siblings.size ].min
        siblings.insert(insert_index, inquiry)
        renumber!(siblings)

        # 列をまたいだ場合、元 status の残りも詰めて再採番する。
        if old_status_id != target_status.id
          old_siblings = Inquiry
            .where(status_id: old_status_id)
            .order(:position, :id)
            .to_a
          renumber!(old_siblings)
        end
      end

      render json: serialize_record(inquiry.reload)
    end

    private

    # フロントは camelCase で送る（statusId / priorityId）ため、permit 後に
    # snake_case にして扱う。両形式（snake/camel）を許容してテスト容易性も担保。
    # update では「キー自体が未送信なら更新しない」を区別したいので、
    # 元の params に key が無い場合は結果の hash にも入れない。
    def normalized_params
      raw = params.permit(:title, :description, :statusId, :priorityId, :status_id, :priority_id)
      result = {}
      result[:title] = raw[:title] if raw.key?(:title)
      result[:description] = raw[:description] if raw.key?(:description)
      if raw.key?(:status_id) || raw.key?(:statusId)
        result[:status_id] = raw[:status_id].presence || raw[:statusId].presence
      end
      if raw.key?(:priority_id) || raw.key?(:priorityId)
        result[:priority_id] = raw[:priority_id].presence || raw[:priorityId].presence
      end
      result
    end

    # move 用の小さい正規化。statusId / position を受け取る。
    # 他のアクションは normalized_params を使うが、move は title/description を見ない。
    def move_params
      raw = params.permit(:statusId, :status_id, :position)
      {
        status_id: raw[:status_id].presence || raw[:statusId].presence,
        position: raw[:position]
      }
    end

    # 渡された配列の順番で position を 1, 2, 3, ... に詰める。
    # update_columns で callback / updated_at / バリデーションを skip し、再採番のたびに
    # timestamp を進めて UI の安定ソートを乱さない。position カラムには CHECK 制約しか
    # 無いため validation skip でも安全。
    def renumber!(records)
      records.each_with_index do |record, i|
        new_position = i + 1
        record.update_columns(position: new_position) if record.position != new_position
      end
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

    # 単一レコード版。create / update のレスポンスで使う。
    def serialize_record(inquiry)
      record = InquirySerializer.new(inquiry).serializable_hash[:data]
      flatten_serialized(record)
    end

    def flatten_serialized(record)
      record[:attributes].merge(id: record[:id].to_i)
    end
  end
end
