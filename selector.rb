
# The Versio
class Version

  attr_accessor :maj, :min, :build
  def initialize (v)
    @maj, @min, @build = v.split('.').map(&:to_i)
  end

  def self.parse (version)
    self.new version.gsub(/[^\d.]/, '')
  end

  def == (v)
    v.maj == maj && v.min == min && v.build == build
  end

  def >= (v)
    [:maj, :min, :build].each do |p|
      v1, v2 = self.send(p), v.send(p)
      return false if v1 < v2
      return true if v1 > v2
    end
    true
  end

  def > (v)
    [:maj, :min].each do |p|
      v1, v2 = self.send(p), v.send(p)
      return false if v1 < v2
      return true if v1 > v2
    end
    build > v.build
  end

  def <= (v)
    [:maj, :min, :build].each do |p|
      v1, v2 = self.send(p), v.send(p)
      return false if v1 > v2
      return true if v1 < v2
    end
    true
  end

  def < (v)
    [:maj, :min].each do |p|
      v1, v2 = self.send(p), v.send(p)
      return false if v1 > v2
      return true if v1 < v2
    end
    build < v.build
  end

  def <=> (v)
    if self > v
      1
    elsif self < v
      -1
    else
      0
    end
  end

  def dup
    self.class.parse self.to_s
  end

  def increment
    [:build, :min, :maj].each do |p|
      v = self.send(p)
      if v
        self.send(:"#{p.to_s}=", v + 1)
        return self
      end
    end
  end

  def decrement
    [:build, :min, :maj].each do |p|
      v = self.send(p)
      if v
        self.send(:"#{p.to_s}=", v - 1)
        return self
      end
    end
  end

  def fill_with_zero
    self.maj = 0 if self.maj.nil?
    self.min = 0 if self.min.nil?
    self.build = 0 if self.build.nil?
    self
  end

  def to_s
    [@maj, @min, @build].compact.join '.'
  end
end

class String
  def to_v
    Version.parse self
  end
end



# Base Class

class VersionDescriptor
  class << self
    attr_accessor :regex, :find
    def when_match (regex, &block)
      self.regex = regex
      self.find = block
      VersionDescriptor.descriptors << self
    end

    def descriptors
      @descriptors ||= []
    end
  end

  def match_signature (version)
    version =~ self.class.regex
  end

  def find_best_version (version, availables, selector)
    self.class.find.call version, availables, selector
  end
end

VERSION_RE = '\\d+\\.\\d+\\.\\d+'
PARTIAL_VERSION_RE = '\\d+(\\.(\\d+|x)(\\.x)*)*'

# Simple formats

class SameVersion < VersionDescriptor
  when_match %r{^#{VERSION_RE}$} do |version, availables, selector|
    availables.select {|v| v.to_v == version.to_v }.last
  end
end

class AnyVersion < VersionDescriptor
  when_match %r{^\*$|^$} do |version, availables, selector|
    availables.last
  end
end

# Operators

# =, >, <, >=, <=

class EqualVersion < VersionDescriptor
  when_match %r{^=#{VERSION_RE}$} do |version, availables, selector|
    availables.select {|v| v.to_v == version.to_v }.last
  end
end

class OperatorDescriptor < VersionDescriptor
  class << self
    def with_operator (op)
      re = %r{^#{op}#{VERSION_RE}$}
      self.when_match re do |version, availables, selector|

        availables.select { |v|
          v.to_v.send(:"#{op}", version.to_v)
        }.last
      end
    end
  end
end

class GreaterVersion < OperatorDescriptor
  with_operator ">"
end

class GreaterOrEqualVersion < OperatorDescriptor
  with_operator ">="
end

class LowerVersion < OperatorDescriptor
  with_operator "<"
end

class LowerOrEqualVersion < OperatorDescriptor
  with_operator "<="
end

# Ranges

class RangeDescriptor < VersionDescriptor
  class << self
    def with_range (regex, &block)
      self.when_match regex do |version, availables, selector|
        m, min, max = self.regex.match(version).to_a
        availables.select {|v| block.call(v, min, max, selector) }.last
      end
    end
  end
end

class SubstractionRange < RangeDescriptor
  re = %r{^(#{VERSION_RE})\s*-\s*(#{VERSION_RE})$}
  with_range re do |v, v1, v2, selector|
    v, v1, v2 = [v, v1, v2].map &:to_v
    v >= v1 && v <= v2
  end
end

class AndRangeVersion < RangeDescriptor
  m1, m2 = [%w{> >=}, %w{< <=}].map do |a|
    a.map {|e| "#{e}#{VERSION_RE}"}.join '|'
  end
  with_range %r{^(#{m1})\s(#{m2})$} do |v, v1, v2, selector|
    op1, op2 = v1.gsub(/#{VERSION_RE}/, ''), v2.gsub(/#{VERSION_RE}/, '')
    v = v.to_v
    v1, v2 = v1.to_v, v2.to_v

    v.send(:"#{op1}", v1) && v.send(:"#{op2}", v2)
  end
end

class TildeRangeVersion < VersionDescriptor
  when_match %r{^~#{PARTIAL_VERSION_RE}$} do |version, availables, selector|
    version_min = ">=#{version.to_v.fill_with_zero}"
    v = version.to_v
    if v.build.nil?
      v.build = nil
      v.min = nil
    else
      v.build = nil
    end
    version_max = "<#{v.increment.fill_with_zero}"
    selector.match "#{version_min} #{version_max}"
  end
end

class OrOperator < VersionDescriptor
  when_match %r{\|\|} do |version, availables, selector|
    version.split('||').map {|e| selector.match e.strip}.compact.first
  end
end

class PartialVersion < VersionDescriptor
  when_match %r{^#{PARTIAL_VERSION_RE}$} do |version, availables, selector|
    version = version.to_v.to_s
    availables.select {|v| v.index(version) == 0}.last
  end
end


# Selector

class VersionSelector
  def initialize (versions)
    @availables = versions.sort do |a, b|
      a,b = a.to_v, b.to_v
      a <=> b
    end
  end

  def descriptors
    @descriptors ||= VersionDescriptor.descriptors.map do |klass|
      klass.new
    end
  end

  def match (version)
    descriptors.each do |descriptor|
      if descriptor.match_signature version
        return descriptor.find_best_version version, @availables, self
      end
    end
    nil
  end
end
