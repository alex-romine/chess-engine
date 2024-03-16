.PHONY: \
	apply \
	init \
	plan \
	install \
	run \
	deploy \
	clean


venv: venv
	python3 -m venv venv
	@echo ". venv/bin/activate"
	
install: venv
	. venv/bin/activate; pip install -r requirements.txt

run:
	uvicorn app.main:app --reload

clean:
	rm -rf venv

package:
	rm -rf ./package
	pip install -r requirements.txt -t ./package/
	cp -r app ./package/

init:
	terraform -chdir=tf init

plan:
	terraform -chdir=tf plan

apply:
	terraform -chdir=tf apply -auto-approve

deploy:
	terraform -chdir=tf apply -auto-approve