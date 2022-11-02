require 'test_helper'
require 'infold/writers/controller_writer'
require 'infold/resource'
require 'infold/db_schema'

module Infold
  class ControllerWriterTest < ::ActiveSupport::TestCase

    setup do
      @resource = Resource.new("product", {})
    end

    test "build_new_association_code should generate association build code" do
      yaml = <<-"YAML"
        model:
          association:
            details:
              kind: has_many
            member:
              kind: has_one
        app:
          form:
            fields:
              - name
              - details:
                  kind: association
              - member:
                  kind: association
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ControllerWriter.new(resource)
      code = writer.build_new_association_code
      assert_match(/@product.details.build$/, code.gsub(/^\s+/, ''))
      assert_match(/@product.build_member$/, code.gsub(/^\s+/, ''))
    end

    test "build_new_association_code(if_blank: true) should generate association build code append 'if blank'" do
      yaml = <<-"YAML"
        model:
          association:
            details:
              kind: has_many
        app:
          form:
            fields:
              - details:
                  kind: association
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ControllerWriter.new(resource)
      code = writer.build_new_association_code(if_blank: true)
      assert_match("@product.details.build if @product.details.blank?", code.gsub(/^\s+/, ''))
    end

    test "search_params_code should generate search conditions params" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id: eq
              - name: full_like
              - status: any
          association_search:
            conditions:
              - id: eq
              - price: gteq
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ControllerWriter.new(resource)
      code = writer.search_params_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        params[:search]&.permit(
          :id,
          :name,
          :price,
          :sort_field,
          :sort_kind,
          statuses: []
        )
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, '') + "\n")
    end

    test "post_params_code should generate post params" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.integer "price"
          t.datetime "published_at"
          t.string "description"
        end

        create_table "one_details" do |t|
          t.string "title"
          t.string "stock"
        end

        create_table "two_detail_tables" do |t|
          t.string "birthday"
          t.string "address"
        end

        create_table "three_details" do |t|
          t.string "name"
          t.datetime "removed_at"
        end
      RUBY
      yaml = <<-"YAML"
        model:
          association:
            one_details:
              kind: has_many
            two_details:
              kind: has_many
              class_name: TwoDetailTable
            three_detail:
              kind: has_one
          active_storage:
            image:
              kind: image
        app:
          form:
            fields:
              - name
              - price:
                  kind: number
              - published_at
              - one_details:
                  kind: association
                  fields:
                    - title
                    - stock
              - image:
                  kind: file
              - description:
                  kind: textarea
              - two_details:
                  kind: association
                  fields:
                    - birthday
                    - address:
                        kind: textarea
              - three_detail:
                  kind: association
                  fields:
                    - name
                    - pdf:
                        kind: file
                    - removed_at
      YAML
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = ControllerWriter.new(resource)
      code = writer.post_params_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        params.require(:admin_product).permit(
          :name,
          :price,
          :published_at_date,
          :published_at_time,
          :image,
          :remove_image,
          :description,
          one_details_attributes: [
            :title,
            :stock
          ],
          two_details_attributes: [
            :birthday,
            :address
          ],
          three_detail_attributes: [
            :name,
            :pdf,
            :remove_pdf,
            :removed_at_date,
            :removed_at_time
          ]
        )
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, '') + "\n")
    end
  end
end