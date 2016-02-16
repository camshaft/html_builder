defmodule HTMLBuilderTest do
  use ExUnit.Case

  cases = %{
    "HTML Entities Escape" => %{
      nodes: "< Hello & Goodbye >",
      out: "&lt; Hello &amp; Goodbye &gt;"
    },
    "Full" => %{
      nodes: {:html, [
        {:__comment__, "This is a test"},
        {"head", nil, [
          {"title", nil, "Hello!"},
          {"meta", name: :description, content: "Hello!"}
        ]},
        {"body", nil, [
          {"span", [class: "this-is-a-class\" other classes go here"], "This is a test"},
          {"span", class: "attribute-with-¨˜ˆçø"},
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
      ]},
      out: """
      <!DOCTYPE html>
      <!-- This is a test -->
      <head>
        <title>Hello!</title>
        <meta name=description content=Hello!>
      </head>
      <body>
        <span class="this-is-a-class&quot; other classes go here">This is a test</span>
        <span class=attribute-with-¨˜ˆçø></span>
        <span>
          Hello,
          World
          <ul>
            <li>
              <span>1</span>
              :
              <span>1</span>
            </li>
            <li>
              <span>2</span>
              :
              <span>4</span>
            </li>
            <li>
              <span>3</span>
              :
              <span>9</span>
            </li>
          </ul>
        </span>
      </body>
      """
    }
  }

  for {name, test} <- cases do
    nodes = test.nodes |> Macro.escape()
    pretty = test.out
    ugly = pretty |> String.split("\n") |> Enum.map(&String.lstrip/1) |> Enum.join()

    test "#{name} ugly" do
      actual = unquote(nodes) |> HTMLBuilder.encode!()
      assert actual == unquote(ugly)
    end

    test "#{name} pretty" do
      actual = unquote(nodes) |> HTMLBuilder.encode!(pretty: true)
      assert actual == unquote(pretty)
    end
  end
end
