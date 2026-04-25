class InquirySerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :inquiry

  # priority_id / category / assignee は次スライスで追加するため今回は未対応。
  # status は status_id があれば Vue 側で紐付けできるので nested では返さない。
  attributes :title, :description, :position, :created_at, :updated_at

  attribute :status_id do |object|
    object.status_id
  end
end
