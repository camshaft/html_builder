# html_builder

generate html in elixir with simple data structures

## Installation

Firs, add HTMLBuilder to your `mix.exs` dependencies:

```elixir
def deps do
  [{:html_builder, "~> 0.1"}]
end
```

Then, update your dependencies:

```shell
$ mix deps.get
```

## Usage

```elixir
{:html, [
  {:__comment__, "This is a test"},
  {"head", nil, [
    {"title", nil, "Hello!"},
    {"meta", name: :description, content: "Hello!"}
  ]},
  {"body", nil, [
    {"span", [class: "this-is-a-class\" other classes go here"], "This is a test"},
    {"span", class: "attribute-with-¨˜ˆçø"},
    {"span", data: "This is a test."},
    {"span", data: [foo: 1, bar: "This is a test."]},
    {"span", nil, [
      "Hello,",
      "World",
      {"ul", nil, for n <- 1..3 do
        {"li", nil, [
          {"span", nil, n},
          ":",
          {"span", nil, n * n}
        ]}
      end}
    ]}
  ]}
]} |> HTMLBuilder.encode!(pretty: true) |> IO.puts

# <!DOCTYPE html>
# <html>
# <!-- This is a test -->
# <head>
#   <title>Hello!</title>
#   <meta name=description content=Hello!>
# </head>
# <body>
#   <span class="this-is-a-class&quot; other classes go here">This is a test</span>
#   <span class=attribute-with-¨˜ˆçø></span>
#   <span data="This is a test."></span>
#   <span data-foo=1 data-bar="This is a test."></span>
#   <span>
#     Hello,
#     World
#     <ul>
#       <li>
#         <span>1</span>
#         :
#         <span>1</span>
#       </li>
#       <li>
#         <span>2</span>
#         :
#         <span>4</span>
#       </li>
#       <li>
#         <span>3</span>
#         :
#         <span>9</span>
#       </li>
#     </ul>
#   </span>
# </body>
# </html>
```
