module Api
  class BaseController < ApplicationController
    # API 全体で共通のレスポンス整形・例外ハンドリング。
    # 後続 UC（編集・削除・移動）でも再利用するため、エラー応答の構造を
    # docs/api-design.md に揃えた形でここに集約する。

    # ActiveRecord::RecordNotFound を 404 に変換。
    # find_by! や find などレコード未存在を起点とする例外を一括で拾う。
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

    private

    # 422: バリデーション違反。jsonapi 規約に寄せず docs/api-design.md の
    # `{ error, message, details: [{ field, reason }] }` 形式で返す。
    # field は フロントの camelCase 仕様に合わせて変換する。
    def render_validation_error(record, message: "入力内容に誤りがあります")
      render json: {
        error: "UNPROCESSABLE_ENTITY",
        message: message,
        details: build_validation_details(record)
      }, status: :unprocessable_entity
    end

    # 404: 単独のリソース未存在。field 引数で「どのフィールドが未存在か」を示す。
    def render_not_found(field: nil, message: "対象が見つかりません")
      details = field ? [ { field: field, reason: "not_found" } ] : []
      render json: {
        error: "NOT_FOUND",
        message: message,
        details: details
      }, status: :not_found
    end

    # 400: 必須キーが欠落しているなど構文・パラメータレベルの問題。
    def render_bad_request(message: "リクエストが不正です", details: [])
      render json: {
        error: "BAD_REQUEST",
        message: message,
        details: details
      }, status: :bad_request
    end

    def handle_record_not_found(_exception)
      render_not_found
    end

    def build_validation_details(record)
      record.errors.details.flat_map do |field, error_list|
        error_list.map do |error|
          { field: camelize_field(field), reason: error[:error].to_s }
        end
      end
    end

    # snake_case の attribute 名を camelCase へ変換（status_id → statusId）。
    # JSON のキー方針と揃えるため details の field でも camelCase に統一する。
    def camelize_field(field)
      field.to_s.camelize(:lower)
    end
  end
end
