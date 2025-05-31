module AliasAttributesInJson

  def as_json(options = nil)
    options = options.dup
    options[:methods]||= []
    options[:methods] += self.class.attribute_aliases.keys
    options[:except]||= []
    options[:except] += self.class.attribute_aliases.values
    super(options)
  end

end