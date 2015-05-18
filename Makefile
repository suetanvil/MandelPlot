
.SUFFIXES: .coffee .js .tar.gz

.coffee.js:
	coffee -cb $<

JS=seq.js plotstate.js zoomer.js quickform.js mandel.js
TARBALL=mandelplot.tar

all: $(JS)

clean:
	rm *.js $(TARBALL)

tarball: $(TARBALL)

$(TARBALL): all
	tar cvf $(TARBALL) $(JS) mandel.html index.html

