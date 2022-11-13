module Admin
  module DatetimeFieldConcern
    extend ActiveSupport::Concern

    included do
      extend(ClassMethods)
    end

    module ClassMethods
      def datetime_field(field_name)
        attr_reader "#{field_name}_date", "#{field_name}_time"

        define_method("#{field_name}_date=") do |val|
          instance_variable_set("@#{field_name}_date", convert_date(val))
          send("set_#{field_name}")
        end

        define_method("#{field_name}_time=") do |val|
          instance_variable_set("@#{field_name}_time", convert_time(val))
          send("set_#{field_name}")
        end

        define_method("set_#{field_name}") do
          send("#{field_name}=", convert_datetime(instance_variable_get("@#{field_name}_date"), instance_variable_get("@#{field_name}_time")))
        end

        define_method("#{field_name}_date") do
          instance_variable_get("@#{field_name}_date") || (send(field_name) ? I18n.l(send(field_name).to_date) : nil)
        end

        define_method("#{field_name}_time") do
          instance_variable_get("@#{field_name}_time") || send(field_name)&.strftime('%R')
        end

        validates "#{field_name}_date", presence: true, if: -> { send("#{field_name}_time").present? }
        validates "#{field_name}_time", presence: true, if: -> { send("#{field_name}_date").present? }
      end
    end

    private

    def convert_date(str)
      str.presence && (Date.parse(str) rescue nil)
    end

    def convert_time(str)
      str.presence && (Time.zone.parse("#{Time.zone.today.strftime('%F')} #{str}").strftime('%H:%M') rescue nil)
    end

    def convert_datetime(date, time)
      return nil if date.blank? || time.blank?
      datetime = Time.zone.local(Time.zone.today.year, Time.zone.today.month, Time.zone.today.day, 0)
      datetime = datetime.change(year: date.year, month: date.month, day: date.day)
      datetime.change(hour: time.split(':')[0].to_i, min: time.split(':')[1].to_i, sec: time.split(':')[2].to_i)
    end
  end
end