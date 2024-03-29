.PHONY: \
	package \ 
	push_image \
	run \
	init \
	plan \
	apply \
	apply_auto \
	deploy

ACCOUNT_NUMBER := $(shell echo $$ACCOUNT_NUMBER)
REGION = us-east-2

package:
	docker build -t chess-engine .

push_image:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin $(ACCOUNT_NUMBER).dkr.ecr.${REGION}.amazonaws.com
	docker tag chess-engine:latest $(ACCOUNT_NUMBER).dkr.ecr.${REGION}.amazonaws.com/chess-engine:latest
	docker push $(ACCOUNT_NUMBER).dkr.ecr.${REGION}.amazonaws.com/chess-engine:latest

run:
	docker run --platform linux/arm64 -v ~/.aws-lambda-rie:/aws-lambda -p 9000:8080 \
		--entrypoint /aws-lambda/aws-lambda-rie \
		chess-engine \
		/usr/local/bin/python -m awslambdaric app.main.handler

init:
	terraform -chdir=tf init

plan:
	terraform -chdir=tf plan

apply:
	terraform -chdir=tf apply

apply_auto:
	terraform -chdir=tf apply -auto-approve
	
deploy:
	make package
	make push_image
	make apply_auto