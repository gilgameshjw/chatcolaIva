import Pkg

meta = ["HTTP","JSON","Dates","Logging"]

Pkg.update()

for p in meta
    Pkg.add(p)
end

