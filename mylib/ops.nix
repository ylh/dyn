{lib, ...}:
builtins.import (builtins.toFile "garbops.nix" "{${
	builtins.toString ((map (s: "\"${s}\" = x: y: x ${s} y;") [
		"." " " "?" "++" "*" "/" "+" "-"
		"<" "<=" ">" ">=" "==" "!=" "&&" "||" "->"
	]) ++ ["\"!\" = x: ! x;"]) # only a single unique unary :~(
}}")
