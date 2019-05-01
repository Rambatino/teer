# Templater

Picture the scene. You have a lot of data and you want to present the results of that data on a chart or a web page. How would you go about turning variable data into a human readable format - let's say you wanted to summarise a chart?

This small library aims to solve that problem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'templater', git: 'git@github.com:Rambatino/templater.git', tag: 'v0.0.1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install templater

## Usage

### Simple Use-Case

Given a table and the dream of translating it into human readable format:

|             | count |
| ----------- | ----- |
| <b>name</b> |       |
| Bob         | 4     |
| Alan        | 14    |
| Jeff        | 2     |

You can pass it in with a template yaml/hash with the format:

```yaml
names: # only run if names is a variable in the template scope
  worst_name: "names.sort[-1].key"
  worst_value: "names.sort[-1].value"
  text:
    GB_en: "{{ worst_name }} has the least apples, having only {{ worst_value }}"
    FR: "{{ worst_name }} a le moins de pommes, n'en ayant que {{ worst_value }}"
```

(under the hood the yaml gets converted into a hash anyway)

and by running:

```ruby
templater = Templater::Template.create([
  { 'name' => 'Bob', 'count' => 4 },
  { 'name' => 'Alan', 'count' => 14 },
  { 'name' => 'Jeff', 'count' => 2 }
], 'count', template).finding
```

It parses the template and substitutes the values into the text:

```ruby
=> "Jeff has the least apples, having only 2"
```

#### Key Principles to the example

As the templater parses the data, it takes a mandatory argument "name", in this case `count` which is what the data is indexed against. The templater takes each index (there could be many) and defines new variables by pluralising the index. In this example, `names` becomes a variable (as it's one of the indexes) that we can apply methods to.

The template passed in has a first key (`names`) which checks for the presence of that variable (it's actually optional to do that check).

Variables can also be defined in the template itself, and substituted into the output text. In the example above, `worst_name` is defined as variable, defined by: `names.sort[-1].key` which means take each row, and sort (ascending is false) the `names` by `count` and take the last row and the `key` is the row member of name and the `value` is the `count` associated with that name.

We can inspect the `names` variable, as it elucidates how these methods interact with it:

```ruby
templater.data.names # templater is defined above
=> <DataStore:0x007f83bd3e1398 @data=[["Bob", 4], ["Alan", 14], ["Jeff", 2]], @locale=:GB_en>
# it's useful to try methods here before adding them to the template:
templater.data.names.keys
=> <Templater::VectorStore:0x00007fbaa7373200 @data=["Bob", "Alan", "Jeff"], @locale=:GB_en>

templater.data.names.values
=> <Templater::VectorStore:0x00007fbaa739a378 @data=[4, 14, 2], @locale=:GB_en>

templater.data.names.max.key
=> "Alan"

templater.data.names.min.value
=> 2

templater.data.names.slice("Jeff")
=> <Templater::DataStore:0x00007fbaa8a02188 @data=[["Jeff", 2]], @locale=:GB_en>
```

Here each index row is associated with the value of the data and methods can be applied to that (defined in `lib/templater/data_store.rb`) such as `min`, `count`, `[]`, `sort` and also conditionals (such as `gt`, `lt`, `ne`, `eq`) which are able to create rich verbatims from the underlying data.

#### Multiple Language Support

If you notice, the key inside `text` is `GB_en` this is the default. However, other languages and keys are supported and can be used like:

```ruby
templater = Templater::Template.create([
  { 'name' => 'Bob', 'count' => 4 },
  { 'name' => 'Alan', 'count' => 14 },
  { 'name' => 'Jeff', 'count' => 2 }
], 'count', template, {}, :FR).finding

=> "Jeff a le moins de pommes, n'en ayant que 2"
```

#### Conditional Switch Statements

To expand on the previous example:

```yaml
names:
  best_name: names.max.key
  best_value: names.max.value
  text:
    GB_en: "{{ best_name }} has the most apples."

  second_best_value: "names.sort.second.value"
  much_larger: best_value > second_best_value + 5
  much_larger:
    second_best_name: names.sort.second.key
    text:
      GB_en: "It's a lot more than {{ second_best_name }} who came in second place."
  not much_larger:
    text:
      GB_en: "However, {{ second_best_name }}'s {{ second_best_value }} was close behind."
```

With this template, the results concatenate (in a top down fashion) and it results in:

```ruby
=> "Alan has the most apples. It's a lot more than Bob who came in second place."
```

You can also collect them all separately (using the method `findings`) so as to join them anyway you like:

```ruby
Templater::Template.create([
  { 'name' => 'Bob', 'count' => 4 },
  { 'name' => 'Alan', 'count' => 14 },
  { 'name' => 'Jeff', 'count' => 2 }
], 'count', template, {}, :FR).findings.join("\n")

=> "Alan has the most apples.\nIt's a lot more than Bob who came in second place."
```

#### Passing in extra Variables

```ruby
templater = Templater::Template.create([
  { 'name' => 'Bob', 'count' => 4 },
  { 'name' => 'Alan', 'count' => 14 },
  { 'name' => 'Jeff', 'count' => 2 }
], 'count', template, {'some_other_var' => 'my special variable'}).finding
```

`{{ some_other_var }}` will yield 'my special variable' when placed inside the template

#### A more complex example

See `templater_spec.rb`. Markdown can be written, returning a result such as:

Behaviour change was worst for respondents who selected:

- `West` for `regUS`
- `Female` for `gender`

for `Would you change your response to Apple?`

#### Helpers | Formatters

To format variables as the template is interpolated, helpers are used to do things such as round numbers of format time. They take the form of `{{METHOD VARIABLE}}`

Examples below:

``` ruby
horrible_floats_and_time = [
  { 'time' => Time.new(1993, 02, 24, 12, 0, 0, "+09:00"), 'name' => 'Bob', 'count' => 4.213432 },
  { 'time' => Time.new(1993, 02, 24, 12, 0, 0, "+09:00"), 'name' => 'Alan', 'count' => 14.35 },
  { 'time' => Time.new(1993, 02, 24, 12, 0, 0, "+09:00"), 'name' => 'Jeff', 'count' => 2.1 }
]

text = '{{round best_value }}'
template = { 'best_value' => 'names.sort[0].value', 'text' => { 'GB_en' => text } }
Templater::Template.create(horrible_floats_and_time, 'count', template).finding
=> "14.4"

text = '{{month month_key }}'
template = { 'month_key' => 'times.sort[0].key', 'text' => { 'GB_en' => text } }
Templater::Template.create(horrible_floats_and_time, 'count', template).finding
=> "February"
```

Although only those two currently come out of the box, it's easy to add more when your app initialises:

``` ruby
Templater::Template.handlebars.register_helper(:year) do |_context, condition, _block|
  Time.at(condition).strftime('%Y')
end
```

See [here](https://github.com/cowboyd/handlebars.rb) for more advanced usage. If you feel the helper will benefit all, please submit a PR!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Rambatino/templater. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Templater project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Rambatino/templater/blob/master/CODE_OF_CONDUCT.md).
