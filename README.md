# syshard-lab-protocol

## Usage

First make sure the `.vault_pass` exists under the `ansible` folder and contains the decrypt the vault.
To run the playbook:
```
ansible-galaxy install -r requirements.yml # Install needed requirements
ansible-playbook playbook.yml --vault-password-file .vault_pass -i inventory/hosts.ini # Run playbook
```

To compile the document:

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

#### Create SSH key pair

To have Ansible be able connecting to the target we create a key pair and transfer it:
```shell
ssh-keygen -t ed25519
ssh-copy-id -i <path-to-key>/<key-name> <user>@<host>
```


In order for Ansible to be able to connect to the right host it is a good idea to have the domain `syshard.lan` resolve to that host (as defined in the [inventory](./ansible/inventory.yml)).
