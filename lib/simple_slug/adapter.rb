module SimpleSlug
  class Adapter
    attr_reader :model, :options, :locales
    attr_accessor :current_locale

    def initialize(model)
      @model = model
      @options = model.simple_slug_options
      @locales = Array(@options[:locales] || [nil])
    end

    def finder_method
      options[:history] ? :find_by : :find_by!
    end

    def valid_locale?(locale)
      locales.include?(locale)
    end

    def current_locale
      valid_locale?(I18n.locale) ? I18n.locale : nil
    end

    def column_names
      locales.map{|l| column_name(l) }
    end

    def column_name(locale=I18n.locale)
      [options[:slug_column], (locale if valid_locale?(locale))].compact.join('_')
    end

    def get(record)
      record.send(column_name)
    end

    def get_prev(record)
      record.send("#{column_name}_was")
    end

    def set(record, value)
      record.send("#{column_name}=", value)
    end

    def each_locale
      locales.each do |l|
        with_locale(l || I18n.default_locale) { yield }
      end
    end

    def reset(record)
      each_locale{ set record, get_prev(record) }
    end

    def save_history(record)
      each_locale do
        slug_was = record.saved_change_to_attribute(column_name).try!(:first)
        next if slug_was.blank?
        ::SimpleSlug::HistorySlug.where(sluggable_type: record.class.name, slug: slug_was, locale: current_locale).first_or_initialize.update(sluggable_id: record.id)
      end
    end

    def generate(record, force: false)
      each_locale do
        next unless force || record.should_generate_new_slug?
        simple_slug = normalize(slug_base(record))
        simple_slug = "__#{record.id || rand(9999)}" if simple_slug.blank? && options[:fallback_on_blank]
        return if simple_slug == get(record).to_s.sub(SimpleSlug::RESOLVE_SUFFIX_REGEXP, '')
        set(record, resolve(record, simple_slug))
      end
    end

    def normalize(base)
      parameterize_args = ActiveSupport::VERSION::MAJOR > 4 ? {separator: '-'} : '-'
      normalized = I18n.transliterate(base).parameterize(parameterize_args).downcase
      normalized = "_#{normalized}" if normalized =~ SimpleSlug::STARTS_WITH_NUMBER_REGEXP
      normalized = normalized.first(options[:max_length]) if options[:max_length]
      normalized
    end

    def add_suffix(slug_value)
      "#{slug_value}--#{rand(99999)}"
    end

    def slug_base(record)
      options[:slug_method].map{|m| record.send(m).to_s }.reject(&:blank?).join(' ')
    end

    def resolve(record, slug_value)
      return slug_value unless slug_exists?(record, slug_value)
      loop do
        slug_with_suffix = add_suffix(slug_value)
        break slug_with_suffix unless slug_exists?(record, slug_with_suffix)
      end
    end

    def slug_exists?(record, slug_value)
      model_slug_exists?(record, slug_value) || history_slug_exists?(record, slug_value)
    end

    def model_slug_exists?(record, slug_value)
      base_scope = record.class.unscoped.where(column_name => slug_value)
      base_scope = base_scope.where('id != ?', record.id) if record.persisted?
      base_scope.exists?
    end

    def history_slug_exists?(record, slug_value)
      return false unless options[:history]
      base_scope = SimpleSlug::HistorySlug.where(sluggable_type: record.class.name, slug: slug_value)
      base_scope = base_scope.where('sluggable_id != ?', record.id) if record.persisted?
      base_scope.exists?
    end

    def with_locale(locale)
      if defined? Globalize
        Globalize.with_locale(locale) do
          I18n.with_locale(locale) { yield }
        end
      else
        I18n.with_locale(locale) { yield }
      end
    end
  end
end
