# Makefile cho build Flutter flavor

run-dev:
	flutter run --flavor dev -t lib/main.dart --dart-define=FLAVOR=dev

run-staging:
	flutter run --flavor staging -t lib/main.dart --dart-define=FLAVOR=staging

apk-dev:
	flutter build apk --flavor dev -t lib/main.dart --dart-define=FLAVOR=dev

apk-staging:
	flutter build apk --flavor staging -t lib/main.dart --dart-define=FLAVOR=staging

version:
	bash version.sh

clean:
	flutter clean
