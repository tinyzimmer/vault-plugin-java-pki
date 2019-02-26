# JKS Extended Vault PKI Plugin

[![Build Status](https://travis-ci.org/tinyzimmer/vault-plugin-java-pki.svg?branch=master)](https://travis-ci.org/tinyzimmer/vault-plugin-java-pki)

This plugin is mostly a fork of the builtin [Vault PKI plugin](https://github.com/hashicorp/vault/tree/master/builtin/logical/pki).
It provides additional `format` options when attempting to issue a certificate.

## Additional Issue Arguments

|Argument|Value|
|:------:|:----:|
|`format`| In addition to the builtin formats, provides a `jks` option|
|`password`| When requesting a `jks` keystore, the password to encrypt the private key with|

When creating a role for issuing certificates, the backend will allow `key_bits=1024`.
Vault itself prohibits this for good reason, however there are use cases for embedded devices that further encrypt their traffic via other means.

## Installation

Ensure `go` on your system, then retrieve the source:

```bash
$> go get github.com/tinyzimmer/vault-plugin-java-pki
```

First configure a `plugin_directory` in vault:

```hcl
# config.hcl

plugin_directory = "/tmp/vault-plugins"
```

Once vault is started with the above configuration, you can proceed to build and register the plugin. If you use the `Makefile`, ensure the requirements found below.
The `Makefile` is not required, and you can run the steps in the build target manually with any other arguments you need.

If you are running vault on Linux:

```bash
$> cd "$GOPATH/src/github.com/tinyzimmer/vault-plugin-java-pki"
$> make build_plugin
$> cp bin/vault-plugin-java-pki /tmp/vault-plugins/
$> SHASUM=$(shasum -a 256 /tmp/vault-plugins/vault-plugin-java-pki | cut -d ' ' -f1)
$> vault write sys/plugins/catalog/java-pki \
    sha_256="${SHASUM}" \
    command=vault-plugin-java-pki
```

If you are running vault on macOS or Windows, you will need to compile the plugin for those platforms instead. The `Makefile` assumes you are compiling for Linux.

Finally enable the plugin with:

```bash
$> vault secrets enable -path=pki_java java-pki
```

## Local Testing and Development

### Requirements

 - `jq`
 - `keytool`
 - `go`
 - `docker-compose`

### Usage

The helper scripts in the `Makefile` and `test_vault` automate the compilation, loading of the plugin, and PKI initialization against a local vault server running in `docker`.

To *only* start the vault server:

```bash
$> make test_vault
```

To compile the plugin, load it into vault, and test a full PKI chain:

```bash
$> make testacc
```
