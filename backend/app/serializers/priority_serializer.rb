class PrioritySerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :priority

  attributes :name, :level, :color, :position
end
