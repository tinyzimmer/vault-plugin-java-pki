.PHONY: test_vault

EXECUTABLES = jq keytool uname go docker-compose curl
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
BASE64_DECODE := -D
else
BASE64_DECODE := -d
endif

build_plugin:
	go get -d ./...
	cd cmd/vault-plugin-java-pki && CGO_ENABLED=0 GOOS=linux go build -o ../../bin/vault-plugin-java-pki .

clean: clean_test_vault
	rm -rf bin
	rm -rf out

test_vault:
	cd test_vault && docker-compose up -d
	@echo "Started Vault Dev Server"

clean_test_vault:
	cd test_vault && docker-compose down

testacc: test_vault build_plugin
	docker cp test_vault/vault-init-pki.sh test_vault_vault_1:/tmp/vault-init-pki.sh
	docker exec -it test_vault_vault_1 mkdir -p /vault/plugins
	docker cp bin/vault-plugin-java-pki test_vault_vault_1:/vault/plugins/vault-plugin-java-pki
	docker exec -it test_vault_vault_1 apk --update add bash curl jq
	docker exec -it test_vault_vault_1 /tmp/vault-init-pki.sh
	mkdir -p out
	curl -X "POST" -H "X-Vault-Token: devroottoken" \
		-d '{"common_name": "test-chain", "format": "jks", "password": "testpassword"}' \
		http://localhost:8200/v1/pki_java/issue/test \
		| jq -r '.data.jks_encoded' | base64 ${BASE64_DECODE} > out/test-chain.jks
	keytool -list -keystore out/test-chain.jks -storepass testpassword
