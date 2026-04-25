class InquirySerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :inquiry

  # category / assignee は MVP スコープ外（docs/tech-stack.md 参照）。
  # status / priority は id があれば Vue 側で紐付けできるので nested では返さない。
  attributes :title, :description, :position, :created_at, :updated_at

  attribute :status_id do |object|
    object.status_id
  end

  attribute :priority_id do |object|
    object.priority_id
  end
end
