SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:
IMAGE = myownvpn
VERSION = latest
SERVERIP = 138.68.177.67
PORT = 3000
USER = laptop

.PHONY: help
help:
	$(info Available make targets:)
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

.PHONY: isync
isync: ## Sync the code to an instance
	$(info *** Sync the code to the instance $(SERVERIP))
	@rsync --rsync-path="mkdir -p ~/docker-openvpn && rsync" -zav --omit-dir-times -e "ssh -i $(HOME)/.ssh/trains" ~/workdir/docker-openvpn/ root@$(SERVERIP):~/docker-openvpn --exclude ".git/*" --exclude "./vpn_data/*"

.PHONY: icon
icon: ## Connect to the instance
	$(info *** Connect to the instance $(SERVERIP))
	@ssh -i $(HOME)/.ssh/trains root@$(SERVERIP)


.PHONY: build
build: ## Build the image
	$(info *** Build the image)
	@docker build \
	-t $(IMAGE):$(VERSION) \
  .

.PHONY: init_certif
init_certif: ## Init the certificates
	$(info *** init certificate)
	@docker run -v $(PWD)/vpn-data:/etc/openvpn --rm myownvpn ovpn_genconfig -u udp://$(SERVERIP):$(PORT)
	@docker run -v $(PWD)/vpn-data:/etc/openvpn --rm -it myownvpn ovpn_initpki

.PHONY: start
start: ## Start the server
	$(info *** start server)
	@docker run -v $(PWD)/vpn-data:/etc/openvpn -d -p $(PORT):1194/udp --cap-add=NET_ADMIN --restart=always --name=openvpn myownvpn

.PHONY: generate
generate: ## Generate new certifcate for a user
	$(info *** generate certificate)
	@docker run -v $(PWD)/vpn-data:/etc/openvpn --rm -it myownvpn easyrsa build-client-full $(USER) nopass
	@docker run -v $(PWD)/vpn-data:/etc/openvpn --rm myownvpn ovpn_getclient $(USER) > $(USER).ovpn
