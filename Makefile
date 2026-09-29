# Détection automatique Windows vs Unix
ifeq ($(OS),Windows_NT)
    BUNDLE := bundle.bat
    GEM    := gem.bat
    RM     := rmdir /s /q
else
    BUNDLE := bundle
    GEM    := gem
    RM     := rm -rf
endif

tree:
	node ./commands/generate-tree.js > .project/tree.txt
	
install:
	$(BUNDLE) install

test:
	$(BUNDLE) exec rspec

test-file:
	$(BUNDLE) exec rspec $(FILE)

lint:
	$(BUNDLE) exec rubocop lib/ spec/

lint-fix:
	$(BUNDLE) exec rubocop --autocorrect lib/ spec/

build:
	$(GEM) build sangho.gemspec

VERSION = $(shell ruby -Ilib -e "require 'sangho/version'; print Sangho::VERSION")

publish: build
	$(GEM) push sangho-$(VERSION).gem

clean:
ifeq ($(OS),Windows_NT)
	if exist .bundle rmdir /s /q .bundle
	if exist vendor  rmdir /s /q vendor
	del /f /q *.gem 2>nul || true
else
	$(RM) .bundle vendor/
	$(RM) *.gem
endif

.PHONY: install test test-file lint lint-fix build publish clean
