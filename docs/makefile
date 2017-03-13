build: clean
	ldoc .

clean:
	rm -rf modules scripts
	rm -rf index.html ldoc_fixed.css
	rm -rf *.tar.gz
	
pack: build
	tar czvf LuaTools_`date +%Y%m%d_%H%M%S`.tar.gz index.html ldoc_fixed.css modules scripts