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
            slug_regexp: SimpleSlug.slug_regexp,
            max_length: SimpleSlug.max_length,
            callback_type: SimpleSlug.callback_type,
            add_validation: SimpleSlug.add_validation
        )

        include InstanceMethods
        extend ClassMethods

        send(simple_slug_options[:callback_type], :simple_slug_generate, if: :should_generate_new_slug?) if simple_slug_options[:callback_type]

        if simple_slug_options[:add_validation]
          simple_slug_locales.each do |locale|
            validates simple_slug_column(locale),
                      presence: true,
                      exclusion: {in: SimpleSlug.excludes},
                      format: {with: simple_slug_options[:slug_regexp]}
          end
        end

        if simple_slug_options[:history]
          after_save :simple_slug_reset_unsaved_slug, :simple_slug_create_history_slug
          after_destroy :simple_slug_cleanup_history
          include InstanceHistoryMethods
        end

        if simple_slug_options[:locales]
          attr_accessor :should_generate_new_slug_for_locales
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
          send(finder_method, simple_slug_column => id_param) or find(::SimpleSlug::HistorySlug.find_by!(slug: id_param).sluggable_id)
        end
      end

      alias_method :friendly_find, :simple_slug_find

      def simple_slug_column(locale=I18n.locale)
        if simple_slug_localized?(locale)
          [simple_slug_options[:slug_column], locale].compact.join('_')
        else
          simple_slug_options[:slug_column]
        end
      end

      def simple_slug_columns
        simple_slug_locales.map{|locale| simple_slug_column(locale) }
      end

      def simple_slug_locales
        Array(simple_slug_options[:locales] || [nil])
      end

      def simple_slug_localized?(locale=I18n.locale)
        return unless locale
        simple_slug_locales.include?(locale.to_sym)
      end
    end

    module InstanceMethods
      def to_param
        simple_slug_stored_slug.presence || super
      end

      def should_generate_new_slug?
        return true if simple_slug_options[:history]
        if simple_slug_options[:locales]
          self.should_generate_new_slug_for_locales = simple_slug_options[:locales].find_all {|locale| simple_slug_get(locale).blank?}
          should_generate_new_slug_for_locales.present?
        else
          simple_slug_get.blank?
        end
      end

      def simple_slug_generate(force=false)
        locales = simple_slug_options[:locales] ? (should_generate_new_slug_for_locales || simple_slug_options[:locales]) : [nil]
        locales.each do |locale|
          simple_slug_generate_for_locale(locale, force)
        end
      end

      def simple_slug_generate_for_locale(locale=I18n.locale, force=false)
        simple_slug_with_locale(locale) do
          simple_slug = simple_slug_normalize(simple_slug_base)
          simple_slug = simple_slug.first(simple_slug_options[:max_length]) if simple_slug_options[:max_length]
          simple_slug = "__#{id}" if simple_slug.blank? && simple_slug_options[:fallback_on_blank]
          return if !force && simple_slug == simple_slug_get(locale).to_s.sub(/--\d+\z/, '')
          resolved_simple_slug = simple_slug_resolve(simple_slug, locale)
          simple_slug_set(resolved_simple_slug, locale)
        end
      end

      def simple_slug_with_locale(locale)
        if defined? Globalize
          Globalize.with_locale(locale) do
            I18n.with_locale(locale) { yield }
          end
        else
          I18n.with_locale(locale) { yield }
        end
      end

      def simple_slug_base
        simple_slug_options[:slug_method].map{|m| send(m).to_s }.reject(&:blank?).join(' ')
      end

      def simple_slug_normalize(base)
        base = SimpleSlug.normalize_cyrillic(base) unless SimpleSlug::CYRILLIC_LOCALES.include?(I18n.locale)
        parameterize_args = ActiveSupport::VERSION::MAJOR > 4 ? {separator: '-'} : '-'
        normalized = I18n.transliterate(base).parameterize(parameterize_args).downcase
        normalized.to_s =~ SimpleSlug::STARTS_WITH_NUMBER_REGEXP ? "_#{normalized}" : normalized
      end

      def simple_slug_resolve(slug_value, locale=I18n.locale)
        if simple_slug_exists?(slug_value, locale)
          loop do
            slug_value_with_suffix = simple_slug_next(slug_value)
            break slug_value_with_suffix unless simple_slug_exists?(slug_value_with_suffix, locale)
          end
        else
          slug_value
        end
      end

      def simple_slug_next(slug_value)
        "#{slug_value}--#{rand(99999)}"
      end

      def simple_slug_exists?(slug_value, locale=I18n.locale)
        simple_slug_base_exists?(slug_value, locale) || simple_slug_history_exists?(slug_value)
      end

      def simple_slug_base_exists?(slug_value, locale=I18n.locale)
        base_scope = self.class.unscoped.where(self.class.simple_slug_column(locale) => slug_value)
        base_scope = base_scope.where('id != ?', id) if persisted?
        base_scope.exists?
      end

      def simple_slug_history_exists?(slug_value)
        return false unless simple_slug_options[:history]
        base_scope = ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, slug: slug_value)
        base_scope = base_scope.where('sluggable_id != ?', id) if persisted?
        base_scope.exists?
      end

      def simple_slug_set(value, locale=I18n.locale)
        send "#{self.class.simple_slug_column(locale)}=", value
      end

      def simple_slug_get(locale=I18n.locale)
        send self.class.simple_slug_column(locale)
      end

      def simple_slug_stored_slug(locale=I18n.locale)
        send("#{self.class.simple_slug_column(locale)}_was")
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
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, slug: simple_slug_get).first_or_create{|hs| hs.sluggable_id = id }
      end
    end
  end
end