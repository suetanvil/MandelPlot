
# To do: refit this into a real test framework

xr = range(1, 10)
console.log(xr.at(xr.size()))
console.log(xr.at(xr.size() - 1))
console.log(xr.at(0))

x = xr.forEach ((x) -> console.log(x)), ((obj) -> console.log("Done! "+obj))
console.log("notDone: "+x.notDone())
x.resume(5)
console.log("notDone: "+x.notDone())
x.resume(5)
console.log("notDone: "+x.notDone())

console.log("-----------------");

xr = range(3, 40, 5)
console.log(xr.size())
console.log(xr.at(xr.size() - 1))
console.log(xr.at(0))
x = xr.forEach (x) -> console.log(x)
x.finish()

console.log("-----------------");

xr = range(10, 1, -1)
x = xr.forEach (x) -> console.log(x)
x.finish()
console.log("-----------------");

xr = range(1,10)
x = xr.map ((x)-> x + 1), ( (obj) -> console.log("Done: "+obj.result.join(" ")) )
x.finish()
console.log("-----------------");

xr = range(1,6).permutedWith(range(1,4))
console.log(xr.size())
x = xr.forEach (i) -> console.log(i.join(","))
x.finish()
console.log("-----------------");

x = wrap("foobar").forEach (c) -> console.log(c)
x.finish()
