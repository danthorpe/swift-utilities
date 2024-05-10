#FROM swiftlang/swift:nightly-master-
#FROM swift:amazonlinux2
#FROM swift:ubuntu-latest
FROM swift:latest

WORKDIR /tmp

ADD .build/checkouts ./.build/checkouts
ADD Sources ./Sources
ADD Tests ./Tests
ADD Package.swift ./

CMD swift test
