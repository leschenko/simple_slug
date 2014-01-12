module SimpleSlug
  module ModelAddition
    def self.included(base)
      base.send :extend, SingletonMethods
    end

    module SingletonMethods
      def simple_slug(*args)
        class_attribute :simple_slug_options, instance_writer: false
        options = args.extract_options!
        self.simple_slug_options = options.reverse_merge(slug_column: 'slug', slug_method: args.first || :title)

        include InstanceMethods
        extend ClassMethods

        after_validation :simple_slug_generate
        after_destroy :simple_slug_cleanup_history if simple_slug_options[:history]
      end
    end

    module ClassMethods

    end

    module InstanceMethods
      def simple_slug_generate
        slug_base = send(simple_slug_options[:slug_method])
        send("#{simple_slug_options[:slug_column]}=", I18n.transliterate(slug_base).parameterize('-').downcase)
      end

      def simple_slug_cleanup_history

      end
    end

  end
end