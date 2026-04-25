class StatusSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :status

  attributes :name, :color, :position
end
