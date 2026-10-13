def resolve($root):
    if type == "object" and has("$ref") then
        .["$ref"] as $ref | $root | getpath($ref | ltrimstr("#/") | split("/"))
    else . end;

def errors($root; $path):
    . as [$schema, $value]
    | ($schema | resolve($root)) as $s
    | if $s == true then empty
      else
        (if $s.type == null then empty
         elif ($s.type == "object" and ($value | type) != "object")
            or ($s.type == "array" and ($value | type) != "array")
            or ($s.type == "string" and ($value | type) != "string")
            or ($s.type == "boolean" and ($value | type) != "boolean")
         then "\($path): expected \($s.type)"
         else empty end),
        (($s.allOf // [])[] | [., $value] | errors($root; $path)),
        (if ($value | type) == "object" then
            (($s.required // [])[] as $r | select($value | has($r) | not) | "\($path): missing \($r)"),
            ($value | keys[] | . as $k
                | if ($s.properties // {}) | has($k) then
                    [$s.properties[$k], $value[$k]] | errors($root; "\($path).\($k)")
                  elif $s.additionalProperties == false then "\($path): unknown key \($k)"
                  else empty end)
         else empty end),
        (if ($value | type) == "array" and $s.items != null then
            (if $s.minItems != null and ($value | length) < $s.minItems then "\($path): too few items" else empty end),
            ($value | to_entries[] | . as $e | [$s.items, $e.value] | errors($root; "\($path)[\($e.key)]"))
         else empty end)
      end;

. as [$root, $value] | [$root, $value] | errors($root; "$")
