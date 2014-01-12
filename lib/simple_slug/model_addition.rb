module SimpleSlug
  module ModelAddition
    def self.included(base)
      base.send :extend, SingletonMethods
    end

    module SingletonMethods
      def simple_slug(*args)
        class_attribute :simple_slug_options, instance_writer: false
        options = args.extract_options!
        self.simple_slug_options = options.reverse_merge(slug_column: SimpleSlug.slug_column, slug_method: args)

        include InstanceMethods
        extend ClassMethods

        after_validation :simple_slug_generate
        if simple_slug_options[:history]
          after_save :simple_slug_create_history_slug
          after_destroy :simple_slug_cleanup_history
        end
      end
    end

    module ClassMethods

    end

    module InstanceMethods
      def to_param
        send(simple_slug_options[:slug_column]).presence || super
      end

      def simple_slug_generate
        send "#{simple_slug_options[:slug_column]}=", simple_slug_slugify(simple_slug_base)
      end

      def simple_slug_base
        simple_slug_options[:slug_method].map{|m| send(m).to_s }.reject(&:blank?).join(' ')
      end

      def simple_slug_slugify(base)
        I18n.transliterate(base).parameterize('-').downcase
      end

      def simple_slug_cleanup_history
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, sluggable_id: id).delete_all
      end

      def simple_slug_create_history_slug
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, sluggable_id: id).first_or_create { |r| r.slug = slug }
      end
    end

  end
end