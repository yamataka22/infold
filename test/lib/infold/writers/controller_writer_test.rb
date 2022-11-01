require 'test_helper'
require 'infold/writers/controller_writer'
require 'infold/model_config'
require 'infold/app_config'
require 'infold/db_schema'

module Infold
  class ControllerWriterTest < ::ActiveSupport::TestCase

    setup do
      @model_config = ModelConfig.new("products", {})
      @app_config = AppConfig.new("products", {})
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      app_config = AppConfig.new('product', YAML.load(yaml))
      writer = ControllerWriter.new(model_config, app_config, @db_schema)
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      app_config = AppConfig.new('product', YAML.load(yaml))
      writer = ControllerWriter.new(model_config, app_config, @db_schema)
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
      app_config = AppConfig.new('product', YAML.load(yaml))
      writer = ControllerWriter.new(@model_config, app_config, @db_schema)
      code = writer.search_params_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        params[:search]&.permit(
        [TAB]:id,
        [TAB]:name,
        [TAB]:price,
        [TAB]:sort_field,
        [TAB]:sort_kind,
        [TAB]status: []
        )
      CODE
      assert_match(expect_code.gsub(/^\s+/, ''), code.gsub(/^\s+/, '') + "\n")
    end

    test "post_params_code should generate post params" do
      db_schema_content = <<-"SCHEMA"
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
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      app_config = AppConfig.new('product', YAML.load(yaml))
      writer = ControllerWriter.new(model_config, app_config, db_schema)
      code = writer.post_params_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        params.require(:admin_product).permit(
        [TAB]:name,
        [TAB]:price,
        [TAB]:published_at_date,
        [TAB]:published_at_time,
        [TAB]:image,
        [TAB]:remove_image,
        [TAB]:description,
        [TAB]one_details_attributes: [
        [TAB][TAB]:title,
        [TAB][TAB]:stock
        [TAB]],
        [TAB]two_details_attributes: [
        [TAB][TAB]:birthday,
        [TAB][TAB]:address
        [TAB]],
        [TAB]three_detail_attributes: [
        [TAB][TAB]:name,
        [TAB][TAB]:pdf,
        [TAB][TAB]:remove_pdf,
        [TAB][TAB]:removed_at_date,
        [TAB][TAB]:removed_at_time
        [TAB]]
        )
      CODE
      assert_match(expect_code.gsub(/^\s+/, ''), code.gsub(/^\s+/, '') + "\n")
    end
  end
end