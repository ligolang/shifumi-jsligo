ligo_compiler?=docker run --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:stable
# ^ Override this variable when you run make command by make <COMMAND> ligo_compiler=<LIGO_EXECUTABLE>
# ^ Otherwise use default one (you'll need docker)
PROTOCOL_OPT?=
JSON_OPT?=--michelson-format json
tsc=npx tsc
help:
	@echo  'Usage:'
	@echo  '  all             - Remove generated Michelson files, recompile smart contracts and lauch all tests'
	@echo  '  clean           - Remove generated Michelson files'
	@echo  '  compile         - Compiles smart contract Shifumi'
	@echo  '  test            - Run integration tests (written in Ligo)'
	@echo  '  deploy          - Deploy smart contract Shifumi (typescript using Taquito)'
	@echo  ''

all: clean compile test

compile: shifumi

shifumi: shifumi.tz shifumi.json

shifumi.tz: contracts/main.jsligo
	@echo "Compiling smart contract to Michelson"
	@mkdir -p compiled
	@$(ligo_compiler) compile contract $^ -e main $(PROTOCOL_OPT) > compiled/$@

shifumi.json: contracts/main.jsligo
	@echo "Compiling smart contract to Michelson in JSON format"
	@mkdir -p compiled
	@$(ligo_compiler) compile contract $^ $(JSON_OPT) -e main $(PROTOCOL_OPT) > compiled/$@

clean:
	@echo "Removing Michelson files"
	@rm -rf compiled/*.tz compiled/*.json

test: test_ligo

test_ligo: test/test.mligo
	@echo "Running integration tests"
	@$(ligo_compiler) run test $^ $(PROTOCOL_OPT)

# test_ligo_2: test/test2.mligo
# 	@echo "Running integration tests (fail)"
# 	@$(ligo_compiler) run test $^ $(PROTOCOL_OPT)

deploy: node_modules metadata.json deploy.js
	@echo "Deploying contract"
	@node deploy/deploy.js

metadata.json:
	@echo "Generate metadata.json"
	@if [ ! -f ./deploy/metadata.json ]; then cp deploy/metadata.json.dist \
        deploy/metadata.json ; fi

deploy.js:
	@cd deploy && $(tsc) deploy.ts --resolveJsonModule -esModuleInterop

node_modules:
	@echo "Install node modules"
	@cd deploy && npm install
