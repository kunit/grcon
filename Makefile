PKG = github.com/kunit/grcon
COMMIT = $$(git describe --tags --always)

GO ?= GO111MODULE=on go

BUILD_LDFLAGS = -X $(PKG).commit=$(COMMIT)
RELEASE_BUILD_LDFLAGS = -s -w $(BUILD_LDFLAGS)

default: build
ci: depsdev test

depsdev:
	GO111MODULE=off go get golang.org/x/tools/cmd/cover
	GO111MODULE=off go get golang.org/x/lint/golint
	GO111MODULE=off go get github.com/motemen/gobump/cmd/gobump
	GO111MODULE=off go get github.com/tcnksm/ghr
	GO111MODULE=off go get github.com/Songmu/ghch
	GO111MODULE=off go get github.com/hairyhenderson/gomplate/cmd/gomplate

lint:
	golint $(shell go list ./... | grep -v misc)
	$(GO) vet $(shell go list ./... | grep -v misc)
	$(GO) fmt $(shell go list ./... | grep -v misc)

test:
	$(GO) test -v $(shell go list ./... | grep -v misc) -coverprofile=coverage.txt -covermode=count

build:
	docker-compose up

build_in_docker:
	$(eval ver = v$(shell gobump show -r version/))
	$(eval pkg = grcon_v$(shell gobump show -r version/)_linux_amd64)
	$(GO) build -a -tags netgo -installsuffix netgo -ldflags="$(RELEASE_BUILD_LDFLAGS) -X $(PKG).version=$(ver) -linkmode external -extldflags -static"
	[ -d ./dist/$(ver) ] || mkdir -p ./dist/$(ver)
	tar -zcvf ./dist/$(ver)/$(pkg).tar.gz grcon
	rm -rf grcon

prerelease:
	$(eval ver = v$(shell gobump show -r version/))
	ghch -w -N ${ver}

release:
	$(eval ver = v$(shell gobump show -r version/))
	ghr -username kunit -replace ${ver} dist/${ver}

docker:
	docker build -t grcon_develop -f Dockerfile .
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" -v $(GOPATH):/go/ -v $(GOPATH)/pkg/mod/cache:/go/pkg/mod/cache -w /go/src/github.com/kunit/grcon -it grcon_develop /bin/bash

.PHONY: default test
