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

        before_validation :simple_slug_generate, if: :should_generate_new_slug?
        validates simple_slug_options[:slug_column],
                  presence: true,
                  exclusion: {in: SimpleSlug.excludes},
                  format: {without: SimpleSlug.exclude_regexp}
        if simple_slug_options[:history]
          after_save :simple_slug_create_history_slug
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
          send(finder_method, simple_slug_options[:slug_column] => id_param) or ::SimpleSlug::HistorySlug.find_by!(slug: id_param).sluggable
        end
      end

      alias_method :friendly_find, :simple_slug_find
    end

    module InstanceMethods
      def to_param
        send(simple_slug_options[:slug_column]).presence || super
      end

      def should_generate_new_slug?
        send(simple_slug_options[:slug_column]).blank? || simple_slug_options[:history]
      end

      def simple_slug_generate
        simple_slug = simple_slug_normalize(simple_slug_base)
        return true if simple_slug == send(simple_slug_options[:slug_column])
        resolved_simple_slug = simple_slug_resolve(simple_slug)
        send "#{simple_slug_options[:slug_column]}=", resolved_simple_slug
      end

      def simple_slug_base
        simple_slug_options[:slug_method].map{|m| send(m).to_s }.reject(&:blank?).join(' ')
      end

      def simple_slug_normalize(base)
        normalized = I18n.transliterate(base).parameterize('-').downcase
        normalized.to_s =~ /\A\d+/ ? "_#{normalized}" : normalized
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
    end

    module InstanceHistoryMethods
      def simple_slug_cleanup_history
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, sluggable_id: id).delete_all
      end

      def simple_slug_create_history_slug
        return true unless slug_changed?
        ::SimpleSlug::HistorySlug.where(sluggable_type: self.class.name, sluggable_id: id, slug: send(simple_slug_options[:slug_column])).first_or_create
      end
    end

  end
end