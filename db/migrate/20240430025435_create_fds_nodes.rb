class CreateFdsNodes < ActiveRecord::Migration[7.1]
  def change
    create_table :fds_nodes do |t|
      t.bigint :parent_node_id
      t.bigint :sub_node_id
      t.integer :node_type
      t.string :name
      t.bigint :size
      t.string :md5

      t.timestamps
    end
  end
end
