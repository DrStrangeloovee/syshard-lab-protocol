# syshard-lab-protocol

## Usage

There are two ways to compile the document:

### Using Typst directly

1. Install [Typst](https://github.com/typst/typst)
2. Run `typst watch --font-path ./fonts main.typ` to compile the file continuously

or

Alternatively you can use the [Typst web app](https://typst.app/) and import the project directly from the repository and work in the browser.

### Using Mise

1. Install [Mise](https://mise.jdx.dev/) which manages the project tooling
2. Run `mise install`
3. You can watch the report via `mise wr` (this will pass the font's path into it too)

### Ansible host

In order for Ansible to be able to connect to the right host it is a good idea to have the domain `syshard.lan` resolve to that host (as defined in the [inventory](./ansible/inventory.yml).
