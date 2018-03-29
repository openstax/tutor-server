DOCKER_TAG = dev
DEMO = bio

.PHONY: docker
docker:
	git archive HEAD | docker build -t openstax/tutor-server:$(DOCKER_TAG) -

.PHONY: init_tutordb
init_tutordb:
	docker-compose run --rm web psql -h db -d postgres -U postgres -c "DROP DATABASE IF EXISTS ox_tutor_dev"
	docker-compose run --rm web psql -h db -d postgres -U postgres -c "CREATE DATABASE ox_tutor_dev ENCODING 'UTF8'"
	docker-compose run --rm web bin/rake db:setup

.PHONY:
init_hdb:
	docker-compose run --rm web psql -h db -d postgres -U postgres -c "DROP DATABASE IF EXISTS hypothesis"
	docker-compose run --rm web psql -h db -d postgres -U postgres -c "CREATE DATABASE hypothesis ENCODING 'UTF8'"
	docker-compose run --rm h bin/hypothesis init
	docker-compose run --rm h bin/hypothesis authclient add --authority openstax.org --name openstax.org --type confidential

.PHONY: load_demo
load_demo:
	docker-compose run --rm web bin/rake demo[$(DEMO)]

.PHONY: serve
serve:
	docker compose up

# Self documenting Makefile
.PHONY: help
help:
	@echo "The following targets are available:"
	@echo " serve          Run everything locally"
	@echo " init_tutordb   Initialize the tutor database"
	@echo " init_hdb       Initialize the hypothesis database"
	@echo " demo           Load demo data into the datase"
	@echo " docker         Build the tutor server docker image"
	@echo " test           Run the test suite (default)"
