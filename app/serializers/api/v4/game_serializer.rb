class Api::V4::GameSerializer < Api::V4::ApplicationSerializer
  has_many :categories, serializer: Api::V4::CategorySerializer

  attributes :id, :name, :shortname, :created_at, :updated_at
end
