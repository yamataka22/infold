# require '/test/test_helper'
require 'infold/model_config'
require 'hashie'

module Infold
  class ModelConfigTest < ::ActiveSupport::TestCase
    test "model_associations should be return ModelAssociation" do
      yaml = <<-"YAML"
        model:
          association:
            one_details:
              kind: has_many
              dependent: destroy
            two_details:
              kind: has_many
            three_detail:
              kind: has_one
            parent:
              kind: belongs_to
              foreign_key: parent_id
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      model_associations = model_config.model_associations
      assert_equal(4, model_associations.size)
      assert_equal('has_many', model_associations[0].kind)
      assert_equal('one_details', model_associations[0].field)
      assert_equal({ 'dependent' => 'destroy' }, model_associations[0].options)
      assert_equal('two_details', model_associations[1].field)
      assert_equal({}, model_associations[1].options)
      assert_equal('has_one', model_associations[2].kind)
      assert_equal('three_detail', model_associations[2].field)
      assert_equal('belongs_to', model_associations[3].kind)
      assert_equal('parent', model_associations[3].field)
      assert_equal({ 'foreign_key' => 'parent_id' }, model_associations[3].options)
    end

    test "form_associations should be return FormAssociation" do
      yaml = <<-"YAML"
        model:
          association:
            one_details:
              kind: has_many
            two_details:
              kind: has_many
        app:
          form:
            fields:
              - title
              - one_details:
                  fields:
                    - amount:
                        kind: number
                    - unit_price:
                        kind: radio
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      form_associations = model_config.form_associations
      assert_equal(1, form_associations.size)
      assert_equal('one_details', form_associations[0].field)
    end

    test "active_storage should be return ActiveStorage (no thumb)" do
      yaml = <<-"YAML"
        model:
          active_storage:
            image:
              kind: image
            pdf:
              kind: file
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      active_storages = model_config.active_storages
      assert_equal(2, active_storages.size)
      assert_equal('image', active_storages[0].field)
      assert_equal('image', active_storages[0].kind)
      assert_nil(active_storages[0].thumb)
      assert_equal('pdf', active_storages[1].field)
      assert_equal('file', active_storages[1].kind)
      assert_nil(active_storages[1].thumb)
    end

    test "active_storages should be return ActiveStorage with thumb" do
      yaml = <<-"YAML"
        model:
          active_storage:
            image:
              kind: image
              thumb:
                kind: fill
                width: 100
                height: 200
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      active_storages = model_config.active_storages
      assert_equal(1, active_storages.size)
      assert_equal('image', active_storages[0].field, )
      assert_equal({ kind: 'fill', width: 100, height: 200 }, active_storages[0].thumb.to_h)
    end

    test "validates should be return Validate" do
      yaml = <<-"YAML"
        model:
          validate:
            stock: presence
            title:
              - presence
              - uniqueness
            price:
              - presence
              - numericality:
                  greater_than_or_equal_to: 0
                  less_than_or_equal_to: 100
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      validates = model_config.validates
      assert_equal(3, validates.size)
      assert_equal('stock', validates[0].field)
      assert_equal('presence', validates[0].conditions[0].condition)
      assert_equal('title', validates[1].field)
      assert_equal('presence', validates[1].conditions[0].condition)
      assert_equal('uniqueness', validates[1].conditions[1].condition)
      assert_equal('price', validates[2].field)
      assert_equal('presence', validates[2].conditions[0].condition)
      assert_equal('numericality', validates[2].conditions[1].condition)
      assert_equal({ 'greater_than_or_equal_to' => 0, 'less_than_or_equal_to' => 100 },
                   validates[2].conditions[1].options)
    end

    test "enum should be return Enum (has no color)" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
              delivered: 3
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      enum = model_config.enum
      assert_equal(1, enum.size)
      assert_equal('status', enum[0].field)
      assert_equal(3, enum[0].elements.size)
      assert_equal('ordered', enum[0].elements[0].key)
      assert_equal(1, enum[0].elements[0].value)
    end

    test "enum should be return Enum (with color)" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
              delivered: 3
            category:
              kitchen:
                value: 1
                color: red
              dining:
                value: 2
                color: blue
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      enum = model_config.enum
      assert_equal(2, enum.size)
      assert_equal('status', enum[0].field)
      assert_equal(3, enum[0].elements.size)
      assert_equal('category', enum[1].field)
      assert_equal(2, enum[1].elements.size)
      assert_equal(1, enum[1].elements[0].value)
      assert_equal('red', enum[1].elements[0].color)
      assert_equal(2, enum[1].elements[1].value)
      assert_equal('blue', enum[1].elements[1].color)
    end

    test "decorator should be return Decorator" do
      yaml = <<-"YAML"
        model:
          decorate:
            price:
              append: "円"
              digit: true
            stock:
              prepend: "在庫:"
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      decorator = model_config.decorator
      assert_equal(2, decorator.size)
      assert_equal('price', decorator[0].field)
      assert_equal('円', decorator[0].append)
      assert_nil(decorator[0].prepend)
      assert(decorator[0].digit)
      assert_equal('stock', decorator[1].field)
      assert_equal('在庫:', decorator[1].prepend)
    end
  end
end