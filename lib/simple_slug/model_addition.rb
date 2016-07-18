module SimpleSlug
  module ModelAddition
    def self.included(base)
      base.send :extend, SingletonMethods
    end

    module SingletonMethods
      def simple_slug(*args)
        class_attribute :simple_slug_options, instance_writer: false
        options = args.extract_options!
        self.simple_slug_options = options.reverse_merge(
            slug_column: SimpleSlug.slug_column,
            slug_method: args,
            max_length: SimpleSlug.max_length,
            callback_type: SimpleSlug.callback_type,
            add_validation: SimpleSlug.add_validation
        )

        include InstanceMethods
        extend ClassMethods

        send(simple_slug_options[:callback_type], :simple_slug_generate, if: :should_generate_new_slug?) if simple_slug_options[:callback_type]

        if simple_slug_options[:add_validation]
          validates simple_slug_options[:slug_column],
                    presence: true,
                    exclusion: {in: SimpleSlug.excludes},
                    format: {without: SimpleSlug.exclude_regexp}
        end

        if simple_slug_options[:history]
          after_save :simple_slug_reset_unsaved_slug, :simple_slug_create_history_slug
          after_destroy :simple_slug_cleanup_history
          include InstanceHistoryMethods
        end
      end
    end

    module ClassMethods
      def simple_slug_find(id_param)
        return unless id_param
        if id_param.is_a?(Integer) || id_param =~ /\A\d+\z/
          find(id_param)
        else
          finder_method = simple_slug_options[:history] ? :find_by : :find_by!
          send(finder_method, simple_slug_options[:slug_column] => id_param) or find(::SimpleSlug::HistorySlug.find_by!(slug: id_param).sluggable_id)
        end
      end

      alias_method :friendly_find, :simple_slug_find
    end

    module InstanceMethods
      def to_param
        simple_slug_stored_slug.presence || super
      end

      def should_generate_new_slug?
        simple_slug_get.blank? || simple_slug_options[:history]
      end

      def simple_slug_generate(force=false)
        simple_slug = simple_slug_normalize(simple_slug_base)
        simple_slug = simple_slug.first(simple_slug_options[:max_length]) if simple_slug_options[:max_length]
        return true if !force && simple_slug == send(simple_slug_options[:slug_column]).to_s.sub(/--\d+\z/, '')
        resolved_simple_slug = simple_slug_resolve(simple_slug)
        send "#{simple_slug_options[:slug_column]}=", resolved_simple_slug
      end

      def simple_slug_base
        simple_slug_options[:slug_method].map{|m| send(m).to_s }.reject(&:blank?).join(' ')
      end

      def simple_slug_normalize(base)
        normalized = I18n.transliterate(base).parameterize(separator: '-').downcase
        normalized.to_s =~ SimpleSlug::STARTS_WITH_NUMBER_REGEXP ? "_#{normalized}" : normalized
      end

      def simple_slug_resolve(slug_value)
        if simple_slug_exists?(slug_value)
          loop do
            slug_value_with_suffix = simple_slug_next(slug_value)
            break slug_value_with_suffix unless simple_slug_exists?(slug_value_with_suffix)
          end
        else
          slug_value
        end
      end

      def simple_slug_next(slug_value)
        "#{slug_value}--#{rand(99999)}"
      end

      def simple_slug_exists?(slug_value)
        simple_slug_base_exists?(slug_value) || simple_slug_history_exists?(slug_value)
      end

      def simple_slug_base_exists?(slug_value)
        base_scope = self.class.unscoped.where(simple_slug_options[:slug_column] => slug_value)
        base_scope = base_scope.where('id != ?', id) if persisted?
        base_scope.exists?
      end

      def simple_slug_history_exists?(slug_value)
        return false unless simple_slug_options[:history]
        base_scope = ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, slug: slug_value)
        base_scope = base_scope.where('sluggable_id != ?', id) if persisted?
        base_scope.exists?
      end

      def simple_slug_set(value)
        send "#{simple_slug_options[:slug_column]}=", value
      end

      def simple_slug_get
        send simple_slug_options[:slug_column]
      end

      def simple_slug_stored_slug
        send("#{simple_slug_options[:slug_column]}_was")
      end
    end

    module InstanceHistoryMethods
      def simple_slug_reset_unsaved_slug
        return true if errors.blank?
        simple_slug_set simple_slug_stored_slug
      end

      def simple_slug_cleanup_history
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, sluggable_id: id).delete_all
      end

      def simple_slug_create_history_slug
        return true unless slug_changed?
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, sluggable_id: id, slug: simple_slug_get).first_or_create
      end
    end

  end
end