# syshard-lab-protocol

## Usage

There are two ways to compile the document:

### Using Typst directly

1. Install [Typst](https://github.com/typst/typst)
2. Run `typst watch --font-path ./fonts main.typ` to compile the file continuously

or

Alternatively you can use the [Typst web app](https://typst.app/) and import the project directly from the repository and work in the browser.

### Using Mise directly

1. Install [Mise](https://mise.jdx.dev/) which manages the project tooling
2. Run `mise install`
3. You can compile the report via `mise run watch` (this will pass the font's path into it too)