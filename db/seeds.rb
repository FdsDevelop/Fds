# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "====================="
puts "create default data"
puts "====================="

unless FdsNode.find_by(parent_node_id: nil, name: "root", node_type: FdsNode.DIR_TYPE)
  root_node = FdsNode.new(parent_node_id: nil, node_type: FdsNode.DIR_TYPE, name: "root", size: 0)
  root_node.save(validate: false)
end
