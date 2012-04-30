
.SUFFIXES: .coffee .js

.coffee.js:
	coffee -cb $<

JS=seq.js plotstate.js zoomer.js quickform.js mandel.js

all: $(JS)

clean:
	rm *.js
