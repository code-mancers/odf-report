module ODFReport

class Report
  include Fields, Images

  PLACEHOLDERS_REGEX = /\[\w+\]/

  attr_accessor :fields, :tables, :images, :sections, :file

  def initialize(template_name, &block)

    @file = ODFReport::File.new(template_name)

    @fields = []
    @tables = []
    @images = {}
    @image_names_replacements = {}
    @sections = []

    yield(self)

  end

  def add_field(field_tag, value='', &block)
    opts = {:name => field_tag, :value => value}
    field = Field.new(opts, &block)
    @fields << field

  end

  def add_table(table_name, collection, opts={}, &block)
    opts.merge!(:name => table_name, :collection => collection)
    tab = Table.new(opts)
    @tables << tab

    yield(tab)
  end

  def add_section(section_name, collection, opts={}, &block)
    opts.merge!(:name => section_name, :collection => collection)
    sec = Section.new(opts)
    @sections << sec

    yield(sec)
  end

  def add_image(name, path)
    @images[name] = path
  end

  def generate(dest = nil)

    @file.create(dest)

    @file.update('content.xml', 'styles.xml') do |txt|

      parse_document(txt) do |doc|

        replace_fields!(doc)
        replace_sections!(doc)
        replace_tables!(doc)

        find_image_name_matches(doc)

      end

    end

    replace_images(@file)

    @file.path

  end

  def placeholders
    @file.create(nil)
    @file.update('content.xml') do |txt|
      parse_document(txt) do |doc|
        @placeholders = doc.text.scan(PLACEHOLDERS_REGEX)
      end
    end

    @placeholders
  end

private

  def parse_document(txt)
    doc = Nokogiri::XML(txt)

    yield doc
    txt.replace(doc.to_s)
  end

  def replace_fields!(content)
    field_replace!(content)
  end

  def replace_tables!(content)
    @tables.each do |table|
      table.replace!(content)
    end
  end

  def replace_sections!(content)
    @sections.each do |section|
      section.replace!(content)
    end
  end

end

end
