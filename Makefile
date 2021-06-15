SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:
IMAGE = myvpn
VERSION = latest
SERVERIP = 91.167.199.220
PORT = 3000
USER = laptop

.PHONY: help
help:
	$(info Available make targets:)
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

.PHONY: build
build: ## Build the image
	$(info *** Build the image)
	@docker build \
	-t $(IMAGE):$(VERSION) \
  .

.PHONY: init_certif
init_certif: ## Init the certificates
	$(info *** init certificate)
	@docker-compose run --rm openvpn ovpn_genconfig -u udp://$(SERVERIP):$(PORT)
	@docker-compose run --rm openvpn ovpn_initpki
	@sudo chown -R $(whoami): ./openvpn-data

.PHONY: start
start: ## Start the server
	$(info *** start server)
	@docker-compose up -d openvpn

.PHONY: generate
generate: ## Generate new certifcate for a user
	$(info *** generate certificate)
	@docker-compose run --rm openvpn easyrsa build-client-full $(USER) nopass
	@docker-compose run --rm openvpn ovpn_getclient $(USER) > $(USER).ovpn

.PHONY: revoke
revoke: ## Revoke certificate for a specific user
	$(info *** revoke certificate)
	@docker-compose run --rm openvpn ovpn_revokeclient $(USER)
	@docker-compose run --rm openvpn ovpn_revokeclient $(USER) remove
