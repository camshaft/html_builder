defmodule HTMLBuilderTest do
  use ExUnit.Case

  cases = %{
    "HTML Entities Escape" => %{
      nodes: "< Hello & Goodbye >",
      out: "&lt; Hello &amp; Goodbye &gt;"
    },
    "Entities" => %{
      nodes: "' \" & < > \0 \t \f \r \n + = ? ! # / . 運動 😀 &lt; &amp;",
      out: "&apos; &quot; &amp; &lt; &gt;        + = ? ! # / . 運動 😀 &amp;lt; &amp;amp;"
    },
    "Quote" => %{
      nodes: {"div", [attr1: "a b", attr2: "a\tb", attr3: "a\rb", attr4: "a\nb", attr5: "a\fb", attr6: "a\0b", attr7: "a\"b", attr8: "a'b", attr9: "a=b", attr10: "a>b", attr11: "a<b", attr12: "a`b"], "<script>"},
      out: "<div attr1=\"a b\" attr2=\"a b\" attr3=ab attr4=\"a b\" attr5=ab attr6=ab attr7=a&quot;b attr8=a&apos;b attr9=\"a=b\" attr10=a&gt;b attr11=a&lt;b attr12=\"a`b\">&lt;script&gt;</div>"
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
      <html>
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
      </html>
      """
    }
  }

  trim_leading = if function_exported?(String, :trim_leading, 1) do
    &String.trim_leading/1
  else
    &String.lstrip/1
  end
  trim_trailing = if function_exported?(String, :trim_trailing, 1) do
    &String.trim_trailing/1
  else
    &String.rstrip/1
  end

  for {name, test} <- cases do
    nodes = test.nodes |> Macro.escape()
    pretty = test.out
    [doctype | strip] = pretty |> String.split("\n") |> Enum.map(trim_leading)
    ugly = "#{doctype}\n#{Enum.join(strip)}" |> trim_trailing.()

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
