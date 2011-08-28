
release: build
	rm -fr Konjac
	mkdir Konjac
	cp -a build/Release/Konjac.app Konjac/Konjac.app
	cp Resources/README.txt Konjac/
	ln -s /Library/Input\ Methods Konjac/Input\ Methods
	zip -y -r Konjac.zip Konjac

build:
	xcodebuild -configuration Release

clean:
	xcodebuild clean
	rm -fr build
	rm -fr Konjac
	rm -f Konjac.zip
