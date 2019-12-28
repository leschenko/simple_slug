module SimpleSlug
  module ModelAddition
    def self.included(base)
      base.send :extend, SingletonMethods
    end

    module SingletonMethods
      def simple_slug(*args)
        class_attribute :simple_slug_options, :simple_slug_adapter, instance_writer: false
        options = args.extract_options!
        self.simple_slug_options = options.reverse_merge(
            slug_column: SimpleSlug.slug_column,
            slug_method: args,
            slug_regexp: SimpleSlug.slug_regexp,
            min_length: SimpleSlug.min_length,
            max_length: SimpleSlug.max_length,
            callback_type: SimpleSlug.callback_type,
            validation: SimpleSlug.validation
        )
        self.simple_slug_adapter = SimpleSlug::Adapter.new(self)

        include InstanceMethods
        extend ClassMethods

        send(simple_slug_options[:callback_type], :simple_slug_generate, if: :should_generate_new_slug?) if simple_slug_options[:callback_type]

        if simple_slug_options[:validation]
          validates *simple_slug_adapter.column_names,
                    presence: true,
                    uniqueness: {case_sensitive: true},
                    exclusion: {in: SimpleSlug.excludes},
                    format: {with: simple_slug_options[:slug_regexp]},
                    length: {minimum: simple_slug_options[:min_length], maximum: simple_slug_options[:max_length]}.reject{|_, v| v.blank? }
        end

        if simple_slug_options[:history]
          after_save :simple_slug_reset, :simple_slug_save_history
          after_destroy :simple_slug_cleanup_history
          include InstanceHistoryMethods
        end
      end
    end

    module ClassMethods
      def simple_slug_find(id_param)
        return unless id_param
        if id_param.is_a?(Integer) || id_param =~ SimpleSlug::NUMBER_REGEXP
          find(id_param)
        else
          send(simple_slug_adapter.finder_method, simple_slug_adapter.column_name => id_param) or simple_slug_history_find(id_param)
        end
      end

      def simple_slug_history_find(slug, locale=I18n.locale)
        find(SimpleSlug::HistorySlug.find_by!(locale: (locale if simple_slug_adapter.valid_locale?(locale)), slug: slug).sluggable_id)
      end

      alias_method :friendly_find, :simple_slug_find
    end

    module InstanceMethods
      def to_param
        simple_slug_adapter.get_prev(self).presence || super
      end

      def should_generate_new_slug?
        simple_slug_adapter.column_names.any?{|cn| send(cn).blank? }
      end

      def simple_slug_generate(force=false)
        simple_slug_adapter.generate(self, force: force)
      end
    end

    module InstanceHistoryMethods
      def simple_slug_reset
        errors.blank? || simple_slug_adapter.reset(self)
      end

      def simple_slug_cleanup_history
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, sluggable_id: id).delete_all
      end

      def simple_slug_save_history
        simple_slug_adapter.save_history(self)
      end
    end
  end
end