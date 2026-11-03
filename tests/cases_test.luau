--!nonstrict
-- Unit tests for the pure conversion logic. Run without installing anything:
--
--   nix run nixpkgs#luau -- tests/cases_test.luau
--
-- (from the repository root). Exits non-zero on the first failing expectation.

local cases = require("../case-convert/cases")

local failures = 0
local checks = 0

local function convert(text: string, preserve: boolean)
	local byName = {}
	for _, result in cases.convertAll(text, preserve) do
		byName[result.name] = result.value
	end
	return byName
end

local function expect(label: string, actual: string?, wanted: string)
	checks += 1
	if actual ~= wanted then
		failures += 1
		print(`FAIL {label}\n  wanted: {wanted}\n  actual: {tostring(actual)}`)
	end
end

-- The Raycast change-case reference input, all conversions at once.
do
	local got = convert("this is an example", true)
	local wanted = {
		["camelCase"] = "thisIsAnExample",
		["PascalCase"] = "ThisIsAnExample",
		["kebab-case"] = "this-is-an-example",
		["snake_case"] = "this_is_an_example",
		["CONSTANT_CASE"] = "THIS_IS_AN_EXAMPLE",
		["dot.case"] = "this.is.an.example",
		["path/case"] = "this/is/an/example",
		["Pascal_Snake_Case"] = "This_Is_An_Example",
		["KEBAB-UPPER-CASE"] = "THIS-IS-AN-EXAMPLE",
		["Header-Case"] = "This-Is-An-Example",
		-- Title Case lowercases small words that are neither first nor last;
		-- Capital Case capitalizes every word. That is the whole difference.
		["Title Case"] = "This Is an Example",
		["Capital Case"] = "This Is An Example",
		["Sentence case"] = "This is an example",
		["no case"] = "this is an example",
		["lower case"] = "this is an example",
		["UPPER CASE"] = "THIS IS AN EXAMPLE",
		["sWAP cASE"] = "THIS IS AN EXAMPLE",
		["AlTeRnAtInG cAsE"] = "ThIs Is An ExAmPlE",
	}
	for name, value in wanted do
		expect(`reference/{name}`, got[name], value)
	end
	expect("reference/conversion count", tostring(#cases.convertAll("this is an example", true)), "18")
end

-- Tokenizer: every spelling of the same words tokenizes identically.
do
	local variants = {
		"parse HTTP response",
		"parse-http-response",
		"parse_http_response",
		"parse.http.response",
		"parseHttpResponse",
		"ParseHttpResponse",
		"parse/http/response",
	}
	for _, variant in variants do
		expect(`tokenize/{variant}`, convert(variant, false)["kebab-case"], "parse-http-response")
	end

	-- Acronym boundary: the trailing capital run splits before the next word.
	local tokens = cases.tokenize("HTTPServerURL")
	expect("tokenize/acronym count", tostring(#tokens), "3")
	expect("tokenize/acronym join", table.concat(tokens, "|"), "HTTP|Server|URL")
end

-- Preserve casing on vs off.
do
	local on = convert("NASA rocks", true)
	local off = convert("NASA rocks", false)
	expect("preserve/on Pascal_Snake_Case", on["Pascal_Snake_Case"], "NASA_Rocks")
	expect("preserve/off Pascal_Snake_Case", off["Pascal_Snake_Case"], "Nasa_Rocks")
	expect("preserve/on Title Case", on["Title Case"], "NASA Rocks")
	expect("preserve/off Title Case", off["Title Case"], "Nasa Rocks")
	-- Lowercase-only conventions ignore the setting entirely.
	expect("preserve/on kebab-case", on["kebab-case"], "nasa-rocks")
	expect("preserve/off kebab-case", off["kebab-case"], "nasa-rocks")
end

-- Character-based conversions keep punctuation; word-based ones drop separators.
do
	local got = convert("Hello, world! Nice day.", true)
	expect("punctuation/UPPER CASE", got["UPPER CASE"], "HELLO, WORLD! NICE DAY.")
	expect("punctuation/kebab-case", got["kebab-case"], "hello-world!-nice-day")
	expect("punctuation/camelCase", got["camelCase"], "helloWorld!NiceDay")
end

-- Text conversions keep prose punctuation and decimals (issue #1); identifier
-- separators still split.
do
	local got = convert("hello, the user's guide to a galaxy (version 2.5)", true)
	expect("prose/Title Case", got["Title Case"], "Hello, the User's Guide to a Galaxy (version 2.5)")
	expect("prose/Capital Case", got["Capital Case"], "Hello, The User's Guide To A Galaxy (version 2.5)")
	expect("prose/Sentence case", got["Sentence case"], "Hello, the user's guide to a galaxy (version 2.5)")
	expect("prose/no case", got["no case"], "hello, the user's guide to a galaxy (version 2.5)")
	expect("prose/kebab-case", got["kebab-case"], "hello-the-user's-guide-to-a-galaxy-(version-2-5)")

	expect("prose/colon and version", convert("Note: see v1.2.3, then quit.", true)["Title Case"], "Note: See V1.2.3, Then Quit.")
	expect("prose/thousands", convert("1,000 items", true)["Title Case"], "1,000 Items")
	expect("prose/small word before comma", convert("bread, and, butter", true)["Title Case"], "Bread, and, Butter")
	expect("prose/kebab input", convert("release-notes-2.5", true)["Title Case"], "Release Notes 2.5")
	expect("prose/dot input", convert("dot.case.input", true)["Title Case"], "Dot Case Input")
	expect("prose/no space", convert("hello,world", true)["Title Case"], "Hello World")
end

-- Non-ASCII: bytes must survive untouched, never be torn apart. Latin-1
-- accents are cased; anything past that block is copied verbatim.
do
	local got = convert("café-au-lait", true)
	expect("utf8/kebab-case", got["kebab-case"], "café-au-lait")
	expect("utf8/CONSTANT_CASE", got["CONSTANT_CASE"], "CAFÉ_AU_LAIT")
	expect("utf8/camelCase", got["camelCase"], "caféAuLait")

	expect("utf8/lower Latin-1", cases.lower("ÉÜÇ ÀÖ"), "éüç àö")
	expect("utf8/upper Latin-1", cases.upper("éüç àö"), "ÉÜÇ ÀÖ")
	-- ß has no single-character uppercase, and × ÷ are symbols, not letters.
	expect("utf8/eszett", cases.upper("straße"), "STRAßE")
	expect("utf8/maths symbols", cases.upper("a × b ÷ c"), "A × B ÷ C")
	-- Known limitation: Latin Extended-A and beyond are left as-is.
	expect("utf8/beyond latin-1", cases.lower("ŁÓDŹ"), "ŁódŹ")

	-- Leading accent: upperFirst must case the whole code point.
	expect("utf8/upperFirst", convert("école libre", true)["PascalCase"], "ÉcoleLibre")
end

-- Multi-line input: newlines are separators for word-based conversions.
do
	local got = convert("first line\nsecond line", true)
	expect("multiline/kebab-case", got["kebab-case"], "first-line-second-line")
end

-- Degenerate inputs.
do
	expect("empty/count", tostring(#cases.convertAll("", true)), "0")
	expect("separators only/count", tostring(#cases.convertAll("---___", true)), "4")
	local single = convert("word", true)
	expect("single/camelCase", single["camelCase"], "word")
	expect("single/PascalCase", single["PascalCase"], "Word")
	expect("trim/kebab-case", convert("   spaced   out   ", true)["kebab-case"], "spaced-out")
end

print(`{checks - failures}/{checks} checks passed`)
if failures > 0 then
	-- The luau CLI has no os.exit; a bare error still exits non-zero.
	error(`{failures} of {checks} checks failed`, 0)
end
