class BlankManifest < ShadowPuppet::Manifest
end

class SuccessfulManifest < ShadowPuppet::Manifest
  recipe :foo

  def foo
    exec('foo', :command => 'true')
  end
end

class FailureManifest < SuccessfulManifest
  recipe :bar

  def bar
    exec('bar', :command => 'false')
  end
end

#this does nothing
class NoOpManifest < ShadowPuppet::Manifest
  def foo
    exec('foo', :command => 'true')
  end

  def bar
    exec('bar', :command => 'true')
  end
end

#demonstrate the default method of satifying requirements: instance methods
class RequiresMetViaMethods < ShadowPuppet::Manifest
  recipe :foo, :bar

  configure({ :foo => :bar , :nested_hash => { :nested_foo => :bar }, 'string' => 'value' })

  def foo
    exec('foo', :command => 'true')
  end

  def bar
    exec('bar', :command => 'true')
  end
end

class RequiresMetViaMethodsSubclass < RequiresMetViaMethods
  recipe :baz

  configure({ :baz => :bar, :nested_hash => { :nested_baz => :bar } })

  def baz
    exec('baz', :command => 'true')
  end
end

# Requirements can be handled by other recipes in the class
class RequiresMetViaRecipeFromClassOfInstance < ShadowPuppet::Manifest
  def bar
    # other recipe stuff
  end

  def foo
    recipe :bar
  end
  recipe :foo
end

#requirements can also be handled by functions in external modules
class ProvidedViaModules < ShadowPuppet::Manifest
  module FooRecipe
    def foo
      file('/tmp/moonshine_foo', :ensure => 'present', :content => 'foo')
    end
  end

  module BarRecipe
    def bar
      file('/tmp/moonshine_bar', :ensure => 'absent')
    end
  end
  include FooRecipe
  include BarRecipe
  recipe :foo, :bar
end

#requirements can also be handled by functions in external modules
class PassingArguments < ShadowPuppet::Manifest
  def foo(options = {})
    file(options[:name], :ensure => 'present', :content => 'foo')
  end
  recipe :foo, :name => '/tmp/moonshine_foo'
end

# since self.respond_to?(:foo) == false, this raises an error when run
class RequirementsNotMet < ShadowPuppet::Manifest
  recipe :foo, :bar

  # def foo
  # end

  def bar
    #this is okay
  end
end

class ConfigurationWithConvention  < ShadowPuppet::Manifest
  configure(:foo => :bar)
  def foo(string)
    file('/tmp/moonshine_foo', :ensure => 'present', :content => string.to_s)
  end
  recipe :foo
end

# Test MoonshienSetupManifest
class MoonshineSetupManifest < ShadowPuppet::Manifest

  configure(
    :deploy_to => "#{ENV['PWD']}/.shadow_puppet_test",
    :user => ENV['USER'],
    :group => (`uname -a`.match(/Darwin/) ? 'everyone' : ENV['USER'])
  )

  def directories
    deploy_to_array = configuration[:deploy_to].split('/')
    deploy_to_array.each_with_index do |dir, index|
      next if index == 0 || index >= (deploy_to_array.size-1)
      file '/'+deploy_to_array[1..index].join('/'), :ensure => :directory
    end

    dirs = [
      "#{configuration[:deploy_to]}",
      "#{configuration[:deploy_to]}/shared",
      "#{configuration[:deploy_to]}/shared/config",
      "#{configuration[:deploy_to]}/releases"
    ]

    dirs.each do |dir|
      file dir,
      :ensure => :directory,
      :owner => configuration[:user],
      :group => configuration[:group] || configuration[:user],
      :mode => '775'
    end
  end
  recipe :directories
end

# setting up a few different resource types to test the test helpers
class TestHelpers < ShadowPuppet::Manifest

  def foo
    exec('foo', :command => 'true',:onlyif => 'test `hostname` == "foo"')
    package('bar',:ensure => :installed)
    file('/tmp/baz', :content => 'bar',:mode => '644',:owner => 'rails', :before => package('bar'))
  end

end

class DependencyTestManifest < ShadowPuppet::Manifest
  def test
    exec('foobar', :command => 'true', :before => exec('barbaz'))
    exec('trololol', :command => 'true', :alias => "winning")
    exec('barbaz', :command => 'true', :require => [exec('foobar'), exec('winning')])

  end
  recipe :test
end

class StupidTestManifest < ShadowPuppet::Manifest
  def my_recipe
    exec 'my_command',
      :command => 'true',
      :require => [ file('/tmp/foo'), exec('jk') ]
    file '/tmp/foo',
      :content => 'true'
    exec 'jk',
      :command => 'true'
  end
  recipe :my_recipe
end

class CwdCoercionTest < ShadowPuppet::Manifest
  def test
    tmp = Pathname.new('/tmp')
    exec 'true',
      :cwd => tmp
    file tmp.join('foo'),
      :ensure => :present
  end
  recipe :test
end

class DuplicateResourceTest < ShadowPuppet::Manifest
  def first_resource
    exec 'true',
      :cwd => Pathname.new('/tmp')
  end

  def second_resource
    exec 'true',
      :cwd => Pathname.new('/tmp'),
      :logoutput => true
  end
end

class MultipleRecipeConfigurationTest < ShadowPuppet::Manifest
  configure({
    :foo => {:man => 'chu'},
    :bar => {:food => 'yummy'}
  })
  recipe :foo, :bar

  def foo(options = {})
    exec 'foo', :command => 'true'
  end

  def bar(options = {})
    exec 'bar', :command => 'true'
  end
end
