
version        = 2.1 PoliMorf
release_date   = $(shell date --rfc-3339=seconds)
copyright_date = $(shell date +%Y)
githash        = $(shell git log --pretty=format:'%h' -n 1)

morfologik     = lib/target/morfologik-tools-2.0.1.jar
sortopts       = --buffer-size=1G
javaopts       = -ea -Xmx1G
input          = eksport.tab

#
# Aggregate targets.
#
all: compile \
     build/polish_tags.txt \
     test \
     zip

compile: eksport.tab \
         build/polish.dict \
         build/polish_synth.dict

#
# Fetch morfologik-tools (FSA compilers) using Apache Maven.
#
$(morfologik):
	cd lib && mvn dependency:copy-dependencies

#
# Check if the input is present.
#
eksport.tab:
	test -s eksport.tab || { echo "ERROR: eksport.tab not found."; exit 1; }

#
# Preprocess the raw input.
#
build/combined.input:
	mkdir -p build
	LANG=C sort $(sortopts) -u $(input) eksport.quickfix.tab | gawk -f awk/join_tags_reverse.awk > build/combined.input

#
# Build the stemming dictionary.
#
build/polish.dict: $(morfologik) build/combined.input build/polish.info
	cp build/combined.input build/polish.input
	java $(javaopts) -jar $(morfologik) dict_compile --format cfsa2 -i build/polish.input --overwrite
	cp build/polish.dict build/polish.dict.cfsa2
	java $(javaopts) -jar $(morfologik) dict_compile --format fsa5  -i build/polish.input --overwrite
	java $(javaopts) -jar $(morfologik) fsa_dump -i build/polish.dict -o build/polish.dump

#
# Build the synthesis dictionary.
#
build/polish_synth.dict: $(morfologik) build/polish_synth.input build/polish_synth.info
	java $(javaopts) -jar $(morfologik) dict_compile --format cfsa2 -i build/polish_synth.input --overwrite
	cp build/polish_synth.dict build/polish_synth.dict.cfsa2
	java $(javaopts) -jar $(morfologik) dict_compile --format fsa5  -i build/polish_synth.input --overwrite
	java $(javaopts) -jar $(morfologik) fsa_dump -i build/polish_synth.dict -o build/polish_synth.dump

build/polish_synth.input: build/combined.input
	gawk -f awk/combined-to-synth.awk build/combined.input > build/polish_synth.input

#
# Extract unique tags
#
build/polish_tags.txt: build/combined.input
	LANG=C gawk -f awk/tags.awk build/combined.input | sort -u > build/polish_tags.txt

#
# Sanity checks.
#
.PHONY: test
test:
	cd lib && mvn test -Dpolish.dict=../build/polish.dict \
                     -Dpolish_synth.dict=../build/polish_synth.dict \
                     -Dcombined.input=../build/combined.input

#
# Substitute variables in template files.
#
define replaceVariables =
	sed -e 's/$$version/$(version)/g' \
      -e 's/$$release_date/$(release_date)/g' \
      -e 's/$$copyright_date/$(copyright_date)/g' \
      -e 's/$$githash/$(githash)/g' \
      $< >$@
endef

TXT_FILES := $(wildcard src/*.txt)
build/%.txt: src/%.txt
	$(replaceVariables)

INFO_FILES := $(wildcard src/*.info)
build/%.info: src/%.info
	$(replaceVariables)

#
# Create a ZIP distribution.
#
.PHONY: zip
zip: compile \
     build/README.txt \
     build/README.Polish.txt \
     build/LICENSE.txt \
     build/LICENSE.Polish.txt
	rm -f build/polimorfologik.zip
	(cd build && zip -9 polimorfologik.zip \
         polish.info \
         polish.dict \
         polish_synth.info \
         polish_synth.dict \
         README.* \
         LICENSE.* )

#
# clean
#
.PHONY: clean
clean:
	rm -rf build
	rm -rf lib/target

