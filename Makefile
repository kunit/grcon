PKG = github.com/kunit/grcon
COMMIT = $$(git describe --tags --always)

GO ?= GO111MODULE=on go

BUILD_LDFLAGS = -X $(PKG).commit=$(COMMIT)
RELEASE_BUILD_LDFLAGS = -s -w $(BUILD_LDFLAGS)

BINDIR=/usr/local/bin
SOURCES=Makefile CHANGELOG.md README.md LICENSE go.mod go.sum main.go

DISTS=centos7 centos6 ubuntu16

default: build
ci: depsdev test

lint:
	golint $(shell go list ./... | grep -v misc)
	$(GO) vet $(shell go list ./... | grep -v misc)
	$(GO) fmt $(shell go list ./... | grep -v misc)

test:
	$(GO) test -v $(shell go list ./... | grep -v misc) -coverprofile=coverage.txt -covermode=count

mod_init:
	$(GO) mod init

mod_download:
	$(GO) mod download

build:
	$(GO) build -ldflags="$(BUILD_LDFLAGS)"

install:
	cp grcon $(BINDIR)/grcon

build_in_docker:
	$(eval ver = v$(shell gobump show -r version/))
	$(eval pkg = grcon_v$(shell gobump show -r version/)_linux_amd64.$(DIST))
	$(GO) build -ldflags="$(RELEASE_BUILD_LDFLAGS) -X $(PKG).version=$(ver)"
	[ -d ./dist/$(ver) ] || mkdir -p ./dist/$(ver)
	mkdir -p $(pkg)
	mv grcon ./$(pkg)/grcon
	cp CHANGELOG.md README.md LICENSE ./$(pkg)
	tar -zcvf ./dist/$(ver)/$(pkg).tar.gz ./$(pkg)
	rm -rf ./$(pkg)

build_static_in_docker:
	$(eval ver = v$(shell gobump show -r version/))
	$(eval pkg = grcon_v$(shell gobump show -r version/)_linux_amd64_static.$(DIST))
	$(GO) build -a -tags netgo -installsuffix netgo -ldflags="$(RELEASE_BUILD_LDFLAGS) -X $(PKG).version=$(ver) -linkmode external -extldflags -static"
	[ -d ./dist/$(ver) ] || mkdir -p ./dist/$(ver)
	mkdir -p $(pkg)
	mv grcon ./$(pkg)/grcon
	cp CHANGELOG.md README.md LICENSE ./$(pkg)
	tar -zcvf ./dist/$(ver)/$(pkg).tar.gz ./$(pkg)
	rm -rf ./$(pkg)

build_rpm:
	$(eval ver = v$(shell gobump show -r version/))
	$(eval no_v_ver = $(shell gobump show -r version/))
	$(eval pkg = grcon-$(shell gobump show -r version/))
	$(GO) build -ldflags="$(RELEASE_BUILD_LDFLAGS) -X $(PKG).version=$(ver)"
	cat ./template/grcon.spec.template | VERSION=$(no_v_ver) gomplate > grcon.spec
	rm -rf /root/rpmbuild/
	rpmdev-setuptree
	yum-builddep grcon.spec
	mkdir -p $(pkg)
	cp -r $(SOURCES) $(pkg)
	tar -zcvf $(pkg).tar.gz ./$(pkg)
	rm -rf $(pkg)
	mv $(pkg).tar.gz /root/rpmbuild/SOURCES
	spectool -g -R grcon.spec
	rpmbuild -ba grcon.spec
	mv /root/rpmbuild/RPMS/*/*.rpm /go/src/github.com/kunit/grcon/dist/$(ver)
	rm grcon grcon.spec

build_deb:
	$(eval ver = v$(shell gobump show -r version/))
	$(eval no_v_ver = $(shell gobump show -r version/))
	$(eval workdir = deb)
	$(GO) build -ldflags="$(RELEASE_BUILD_LDFLAGS) -X $(PKG).version=$(ver)"
	mkdir -p $(workdir)/DEBIAN $(workdir)/usr/bin
	cat ./template/control.template | VERSION=$(no_v_ver) gomplate > $(workdir)/DEBIAN/control
	mv grcon $(workdir)/usr/bin
	fakeroot dpkg-deb --build $(workdir) /go/src/github.com/kunit/grcon/dist/$(ver)
	rm -rf $(workdir)

depsdev:
	GO111MODULE=off go get golang.org/x/tools/cmd/cover
	GO111MODULE=off go get golang.org/x/lint/golint
	GO111MODULE=off go get github.com/motemen/gobump/cmd/gobump
	GO111MODULE=off go get github.com/tcnksm/ghr
	GO111MODULE=off go get github.com/Songmu/ghch
	GO111MODULE=off go get github.com/hairyhenderson/gomplate/cmd/gomplate

crossbuild:
	@for d in $(DISTS); do\
		docker-compose up $$d;\
	done

prerelease:
	$(eval ver = v$(shell gobump show -r version/))
	ghch -w -N ${ver}

release:
	$(eval ver = v$(shell gobump show -r version/))
	ghr -username kunit -replace ${ver} dist/${ver}

docker:
	docker build -t grcon_develop -f dockerfiles/Dockerfile.golang .
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" -v $(GOPATH):/go/ -v $(GOPATH)/pkg/mod/cache:/go/pkg/mod/cache -w /go/src/github.com/kunit/grcon -it grcon_develop /bin/bash

.PHONY: default test cover

